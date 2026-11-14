# qpdf Lambda Layer

This layer packages [qpdf](https://github.com/qpdf/qpdf) for AWS Lambda. qpdf is a command-line tool that repairs, encrypts, decrypts, linearizes, splits and merges PDFs. The layer is built the same way as the ffmpeg layer in this repo:

1. Download a pinned prebuilt release.
2. Extract it into `bin/` and `lib/`.
3. Zip it, keeping the symlinks.
4. Upload the zip to S3.
5. Deploy it as an `AWS::Lambda::LayerVersion` stack.

It is a **separate layer and stack** from ffmpeg. You can attach either one or both to a function.

- **Target:** x86_64, Amazon Linux 2023 runtimes (`nodejs20.x`, `nodejs22.x`, `python3.12`, `python3.13`)
- **qpdf version:** 12.4.2 (`QPDF_VERSION` in [qpdf-layer/Makefile](../qpdf-layer/Makefile))
- **Size:** about 11 MB unzipped, about 4 MB zipped

## 1. What ends up in the function

Lambda extracts every layer into `/opt`:

```
/opt/bin/qpdf, /opt/bin/fix-qdf, /opt/bin/zlib-flate   # /opt/bin is on PATH
/opt/lib/libqpdf.so.30 -> libqpdf.so.30.4.2           # /opt/lib is on LD_LIBRARY_PATH
/opt/lib/libgnutls.so.30, libjpeg.so.8, libnettle.so.8, libhogweed.so.6,
         libffi.so.8, libidn2.so.0, libp11-kit.so.0, libtasn1.so.6, libunistring.so.2
```

The qpdf release bundles its own libraries, which is why `lib/` contains more than just `libqpdf`. In your code, call `qpdf` directly or use `/opt/bin/qpdf`.

## 2. Prerequisites

- `make`, `curl`, `unzip`, `zip`, and `bash`
- The AWS CLI, configured for the account and **region** where your functions run. Layers are regional.
- An S3 bucket in that same region. The default is `lambda-layer-bucket-ffmpeg`, the same bucket the ffmpeg layer uses.
- Optional: Docker or OrbStack, for `make verify-local`

## 3. Build and deploy

```bash
cd qpdf-layer

make build/layer.zip                        # download qpdf and build the zip (no AWS)
make verify-local                           # run qpdf inside the real Lambda nodejs20 image
make check-conflicts                        # compare with the ffmpeg layer: same file paths, total size
make deploy DEPLOYMENT_BUCKET=<your-bucket> # upload to S3, deploy the stack, print the layer ARN
```

The ARN is printed in the `LayerVersion` output. It looks like `arn:aws:lambda:<region>:<account>:layer:qpdf:<N>`. You can read it again at any time:

```bash
aws cloudformation describe-stacks --stack-name qpdf-lambda-layer \
  --query "Stacks[0].Outputs[?OutputKey=='LayerVersion'].OutputValue" --output text
```

You can override these variables: `STACK_NAME` (default `qpdf-lambda-layer`), `DEPLOYMENT_BUCKET`, `QPDF_VERSION`, and `LAYER_ZIP_KEY` (default `qpdf-layer-<version>.zip`).

### Upgrading qpdf

1. Find the new version on the [qpdf releases page](https://github.com/qpdf/qpdf/releases). Pick the asset named `qpdf-<ver>-bin-linux-x86_64.zip`.
2. Run `make clean deploy QPDF_VERSION=<ver>`, or edit the default in the Makefile first.
3. You get a **new ARN** (version `N+1`). Update each function that uses the layer (see section 4).

The S3 key includes the version, so every upgrade really does create a new layer version. Older versions are kept (`DeletionPolicy: Retain`), so you can roll a function back to one.

## 4. Attach it to a Lambda function

Requirements for the function: it must be **x86_64** and in the **same region** as the layer, and it should use one of the runtimes listed above.

### a) AWS Console

1. Open the function and go to **Layers**.
2. Choose **Add a layer**, then **Specify an ARN**.
3. Paste the qpdf ARN.
4. If the function also uses ffmpeg, keep the ffmpeg layer in the list too.

### b) AWS CLI

```bash
aws lambda update-function-configuration \
  --function-name my-function \
  --layers <ffmpeg-layer-arn> <qpdf-layer-arn>
```

> ⚠️ `--layers` **replaces the whole list**. If you pass only the qpdf ARN, the ffmpeg layer is silently removed. Check the current list first:
> `aws lambda get-function-configuration --function-name my-function --query Layers[].Arn`

### c) SAM / CloudFormation (recommended)

```yaml
Parameters:
  FFmpegLayerArn: { Type: String }
  QpdfLayerArn:   { Type: String }

Resources:
  MyFunction:
    Type: AWS::Serverless::Function
    Properties:
      Runtime: nodejs20.x
      Architectures: [x86_64]
      Handler: index.handler
      CodeUri: src
      Timeout: 60
      MemorySize: 1024
      Layers:
        - !Ref FFmpegLayerArn
        - !Ref QpdfLayerArn
```

Read the ARNs from the layer stacks when you deploy. This is the same pattern as [example/Makefile](../example/Makefile) and [qpdf-layer/test-layer/Makefile](../qpdf-layer/test-layer/Makefile):

```make
QPDF_LAYER_ARN := $(shell aws cloudformation describe-stacks --stack-name qpdf-lambda-layer \
  --query "Stacks[0].Outputs[?OutputKey=='LayerVersion'].OutputValue" --output text)
```

### d) Serverless Framework

```yaml
functions:
  pdf:
    handler: index.handler
    layers:
      - arn:aws:lambda:<region>:<account>:layer:ffmpeg:<N>
      - arn:aws:lambda:<region>:<account>:layer:qpdf:<N>
```

## 5. Using qpdf from Node.js

```js
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
const run = promisify(execFile);

// qpdf exit codes: 0 = ok, 3 = ok but with warnings (output still written), 2 = error
async function qpdf(args) {
  try {
    return await run('qpdf', args, { maxBuffer: 10 * 1024 * 1024 });
  } catch (err) {
    if (err.code === 3) return err;   // warnings only: treat as success
    throw err;
  }
}

export const handler = async () => {
  // Download the input to /tmp first (e.g. from S3), then:
  await qpdf(['--linearize', '/tmp/in.pdf', '/tmp/out.pdf']);
  await qpdf(['--decrypt', '--password=secret', '/tmp/in.pdf', '/tmp/plain.pdf']);
  await qpdf(['--empty', '--pages', '/tmp/a.pdf', '/tmp/b.pdf', '--', '/tmp/merged.pdf']);
  await qpdf(['/tmp/in.pdf', '--pages', '.', '1-3', '--', '/tmp/first3.pdf']);
  // Upload the result, then delete the /tmp files (warm containers keep /tmp).
};
```

Use `execFile` with an argument array, not `exec` with a string. Filenames and passwords taken from events could otherwise inject shell commands.

## 6. Test it in AWS

```bash
cd qpdf-layer/test-layer
make deploy    # deploys a nodejs20.x x86_64 function with the qpdf layer, plus the ffmpeg layer if its stack exists
make invoke    # expect "all_passed": true
make destroy   # remove the test stack
```

The test covers these steps:
1. `qpdf --version`
2. Repair a hand-written one-page PDF.
3. `--check`
4. Encrypt the file with AES-256, then decrypt it.
5. Linearize it, then check the linearization.
6. Confirm the page count is 1.
7. If the ffmpeg layer is attached: `ffmpeg -version`, which proves both layers work in the same function.

You can run the same handler locally without AWS:

```bash
cd qpdf-layer
docker run --rm --platform linux/amd64 -v "$PWD/build/layer:/opt:ro" -v "$PWD/test-layer:/var/task:ro" \
  --entrypoint /var/lang/bin/node public.ecr.aws/lambda/nodejs:20 \
  -e "import('/var/task/index.mjs').then(m=>m.handler()).then(r=>console.log(r.body))"
```

## 7. Problems you can hit when combining with the existing ffmpeg layer

| # | Problem | Symptom | Prevention / fix |
|---|---|---|---|
| 1 | **Both layers extract into the same `/opt`.** If both contain a file at the same path (for example `lib/libz.so.1`), the layer **later** in the function's list silently overwrites the other. | One tool crashes with `undefined symbol` or `version not found` after the other layer is added. | Run `make check-conflicts` before deploying. Today there is no overlap: ffmpeg ships only `libav*`/`libsw*` and qpdf ships `libqpdf` and its own dependencies. Re-run the check after every ffmpeg or qpdf upgrade. |
| 2 | **250 MB unzipped limit** for the function code plus **all** of its layers. There is also a maximum of 5 layers per function. | Deploy fails with `Function code combined with layers exceeds the maximum allowed size`. | `make check-conflicts` prints the combined size. Measured: ffmpeg is about 179 MB and qpdf about 10 MB, **189 MB combined**, which leaves only about 60 MB for your function code and any other layers. Keep `node_modules` small, and don't bundle `@aws-sdk/*`, because the runtime already includes it. |
| 3 | **The system libraries win over `/opt/lib`.** Lambda's `LD_LIBRARY_PATH` is `/var/lang/lib:/lib64:/usr/lib64:...:/opt/lib`, so `/opt/lib` is searched **last**. On AL2023, qpdf picks up the system copies of `libffi`, `libidn2`, `libtasn1`, `libunistring` and `libp11-kit` instead of the bundled ones. | Works on AL2023 (verified with `make verify-local`). It could break if a future runtime image ships incompatible versions of those libraries. | Re-run `make verify-local` after a qpdf upgrade or a runtime change. Don't put `/opt/lib` first in `LD_LIBRARY_PATH` globally: that would make Node itself load qpdf's gnutls and ffi. |
| 4 | **glibc and runtime mismatch.** The prebuilt qpdf is tested on AL2023 only. The ffmpeg template also lists AL2 runtimes (`nodejs18.x`, `python3.10`, `python3.11`), but qpdf is not guaranteed to work on them. | `GLIBC_2.xx not found` or `error while loading shared libraries`. | Use `nodejs20.x` or newer, or `python3.12` or newer, for any function that uses qpdf. The qpdf template only lists AL2023 runtimes. |
| 5 | **Architecture.** Both layers are x86_64 only. | `Exec format error` on an arm64 (Graviton) function. | Set `Architectures: [x86_64]`. An arm64 version would need the `bin-linux-aarch64.zip` asset and an arm64 ffmpeg build. |
| 6 | **Layer versions are immutable.** A redeploy creates a new ARN, and functions don't pick it up automatically. | You upgraded qpdf, but the function still runs the old version. | Redeploy the consuming stacks so they read the new ARN from the stack output. |
| 7 | **A fixed S3 key means "no changes".** The ffmpeg flow always uploads to `ffmpeg-layer.zip`. If the CloudFormation parameters don't change, `cloudformation deploy` does nothing, even though the zip in S3 changed. | `No changes to deploy` after you changed `FFMPEG_URL`. | qpdf uses versioned keys (`qpdf-layer-12.4.2.zip`). For ffmpeg, pass a new key: `make deploy LAYER_ZIP_KEY=ffmpeg-layer-8.1.2.zip`. |
| 8 | **The ffmpeg stack deletes old versions.** The root `template.yaml` has no `Retain` policy, so each update deletes the previous ffmpeg layer version. | Existing functions keep working, but you can't attach the old version to anything new, so a rollback isn't possible. | qpdf uses `DeletionPolicy`/`UpdateReplacePolicy: Retain`. Consider adding the same to the ffmpeg template. |
| 9 | **Layers are regional.** | `Layer version ... does not exist` or an access denied error. | Deploy the bucket, both layers and the function in one region. Use `--region` or set `AWS_REGION`. |
| 10 | **`/tmp` and resources.** PDFs and videos are processed on disk in `/tmp`, which is 512 MB by default and is reused while a container stays warm. | `ENOSPC`, timeouts, or out-of-memory errors on large files. | Raise `EphemeralStorage` (up to 10 GB), `MemorySize` and `Timeout`. Delete the files in `/tmp` after each invocation. |
| 11 | **The CLI `--layers` replaces the whole list** (see section 4b). | The ffmpeg layer disappears from a function. | Always pass both ARNs. |
| 12 | **Licensing.** qpdf and its bundled libraries use Apache-2.0 and LGPL. The ffmpeg build is **GPL**. | — | Using them internally is fine. If you redistribute the combined layer set, the ffmpeg GPL terms apply. |
