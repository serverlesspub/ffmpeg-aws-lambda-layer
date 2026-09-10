# FFmpeg Lambda Layer Test

Python Lambda function that verifies the FFmpeg layer works correctly by running 8 checks:

1. `ffmpeg -version`
2. `ffprobe -version`
3. List supported formats
4. List supported codecs
5. Generate a 1s silence WAV file
6. Probe the WAV to validate it
7. Generate a 1s test video MP4 with libx264
8. Probe the MP4 to validate it

Returns a JSON summary with pass/fail count and details for each check.

## Commands

```bash
cd test-layer

make deploy    # Package and deploy the test function (auto-fetches layer ARN)
make invoke    # Invoke the test function and print results
make destroy   # Delete the CloudFormation stack
make clean     # Remove the packaged.yaml artifact
```

## Configuration

Defaults in the Makefile can be overridden:

```bash
make deploy DEPLOYMENT_BUCKET=my-bucket LAYER_STACK_NAME=my-layer-stack STACK_NAME=my-test-stack
```

| Variable | Default | Description |
|---|---|---|
| `DEPLOYMENT_BUCKET` | `lambda-layer-bucket-ffmpeg` | S3 bucket for packaging |
| `LAYER_STACK_NAME` | `ffmpeg-lambda-layer` | Stack name of the deployed FFmpeg layer |
| `STACK_NAME` | `ffmpeg-layer-test` | Stack name for this test function |
