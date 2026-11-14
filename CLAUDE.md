# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Make + CloudFormation scripts that package a prebuilt FFmpeg (BtbN/FFmpeg-Builds, **GPL shared** linux64 build) into an AWS Lambda layer. There is no compiled code here. The only code is the example function (Node.js) and the test function (Python).

## Commands

All AWS commands use the local AWS CLI credentials. Default bucket: `lambda-layer-bucket-ffmpeg`. Default layer stack: `ffmpeg-lambda-layer`.

```bash
# Layer (repo root)
make build/layer.zip                     # download FFmpeg tarball and build the zip only
make deploy DEPLOYMENT_BUCKET=<bucket>   # build, upload zip to S3, deploy the CFN stack, print outputs
./temp.sh                                # shortcut: make deploy with the default bucket
make clean                               # rm -rf build/ (needed to force a re-download or repackage)

# Smoke test the deployed layer (test-layer/)
cd test-layer
make deploy    # reads LayerVersion output from the layer stack, packages and deploys a python3.12 test fn
make invoke    # runs 8 checks (versions, formats/codecs, WAV + libx264 MP4 generate and probe), prints JSON
make destroy   # delete the test stack

# Example S3 thumbnail app (example/, deployed from the root)
make deploy-example DEPLOYMENT_BUCKET=<bucket>
```

```bash
# qpdf layer (qpdf-layer/): a separate layer and stack built the same way. Full guide: docs/QPDF-LAYER.md
cd qpdf-layer
make build/layer.zip     # download the pinned qpdf release (QPDF_VERSION) and zip it
make verify-local        # ldd + qpdf --version inside the public.ecr.aws/lambda/nodejs:20 image (Docker/OrbStack)
make check-conflicts     # fail on any path shared with ../build/layer (ffmpeg), print the combined size vs 250 MB
make deploy DEPLOYMENT_BUCKET=<bucket>
cd test-layer && make deploy && make invoke   # nodejs20.x test fn; also attaches ffmpeg if that stack exists
```

There are no unit tests or linters. Verify by deploying the layer, then running `test-layer` `make deploy && make invoke` and checking that `summary.all_passed` is true.

## Architecture / how the pieces connect

- **Root `Makefile`**: `FFMPEG_URL` pins the exact BtbN release tarball. Building extracts `bin/ffmpeg` and `bin/ffprobe` into `build/layer/bin` and `lib/*.so*` into `build/layer/lib`, then zips with `--symlinks` so the shared-lib symlink chains are kept and not duplicated. The zip is uploaded to `s3://$DEPLOYMENT_BUCKET/$LAYER_ZIP_KEY`. Then the stack is deployed with those values passed as parameters. Make targets are file-based (`build/layer/bin/ffmpeg`, `build/layer.zip`), so a stale `build/` is reused silently. Run `make clean` after changing `FFMPEG_URL`.
- **Root `template.yaml`**: a plain `AWS::Lambda::LayerVersion` that reads its content from S3 (it does not use `aws cloudformation package`). The stack output `LayerVersion` is the layer ARN. Both `test-layer/Makefile` and `example/Makefile` read this output through `describe-stacks` to wire the layer into their functions.
- **Runtime layout**: Lambda mounts the layer at `/opt`, so the binaries are at `/opt/bin` (on `PATH`) and the shared libs at `/opt/lib` (on Lambda's default `LD_LIBRARY_PATH`). Because the build is *shared*, the binaries do not work without the `lib/` directory.
- **`test-layer/`**: a SAM function (`app.py`) packaged with `aws cloudformation package` into `packaged.yaml` (gitignored). It takes the layer ARN as the `FFmpegLayerArn` parameter.
- **`example/`**: a legacy Node.js S3-trigger thumbnail generator. It still targets `nodejs10.x` and calls `/opt/bin/ffmpeg`, and it hasn't been updated for the current layer.

## Gotchas

- `README.md`, `README-SAR.md` and the SAR `Metadata` in `template.yaml` still mention FFmpeg 4.1.3, static builds and `nodejs10.x`. The actual build is 8.1 shared. Update them if you touch versioning.
- CloudFormation errors such as `UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS`: run `aws cloudformation wait stack-rollback-complete --stack-name ffmpeg-lambda-layer`, then `make clean` and redeploy.
- `Uploaded file must be a non-empty zip` or `NoSuchKey`: the S3 artifact is stale or missing. Fix it with `make clean` and a redeploy.
- `CompatibleRuntimes` in `template.yaml` lists python3.10–3.12 and nodejs18/20. Add new runtimes there.
- qpdf layer: the S3 key includes the version (`qpdf-layer-$(QPDF_VERSION).zip`) so bumping the version actually creates a new LayerVersion. The ffmpeg flow uses a fixed key, so a redeploy with unchanged params is a no-op. The qpdf template retains old layer versions; the ffmpeg template does not.
- qpdf targets x86_64 AL2023 runtimes only (nodejs20+/python3.12+). Its release zip bundles gnutls, nettle, jpeg and other libraries into `lib/`. Lambda searches `/opt/lib` *last*, so system copies in `/lib64` win where they exist. Both layers share `/opt`, so re-run `check-conflicts` after upgrading either one.
- `qpdf --empty` creates a zero-page PDF that `--check` rejects. qpdf exit code 3 means success with warnings.
- License: FFmpeg GPL build, so `LicenseInfo: GPL-2.0-or-later`. The repo's own scripts are MIT.
