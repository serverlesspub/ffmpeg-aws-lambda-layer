# FFmpeg/FFprobe for AWS Lambda

A Lambda layer containing a static version of FFmpeg/FFprobe utilities from the [`FFmpeg`](https://www.ffmpeg.org/) Linux package, compatible with Amazon Linux 2.x and Amazon Linux 1.x instances (including the `nodejs10.x` runtime, and the updated 2018.03 Amazon Linux 1 runtimes). 

## Usage

Absolutely the easiest way of using this is to pull it directly from the AWS Serverless Application repository into a CloudFormation/SAM application, or deploy directly from the Serverless Application Repository into your account, and then link as a layer. 

The `ffmpeg` and `ffprobe` binaries will be in `/opt/bin/` after linking the layer to a Lambda function.

For more information, check out the [ffmpeg-lambda-layer](https://serverlessrepo.aws.amazon.com/applications/arn:aws:serverlessrepo:us-east-1:145266761615:applications~ffmpeg-lambda-layer) application in the Serverless App Repository.

For manual deployments and custom builds, read below...

## Prerequisites

* Unix Make environment
* AWS command line utilities (just for deployment)

## Deploying to AWS as a layer

This package includes FFmpeg 4.1.3, packaged by Johan Van Sickle. Please consider supporting him for maintaining statically built FFmpeg packages. For more information, check out <https://johnvansickle.com/ffmpeg/>

The output will be in the `result` dir.

Run the following command to deploy the compiled result as a layer in your AWS account.

```
make deploy DEPLOYMENT_BUCKET=<YOUR BUCKET NAME>
```

### configuring the deployment

By default, this uses `ffmpeg-lambda-layer` as the stack name. Provide a `STACK_NAME` variable when calling `make deploy` to use an alternative name.

### example usage

An example project is in the [example](example) directory. It sets up two buckets, and listens to file uploads on the first bucket to convert and generate thumbnails from uploaded video files. You can deploy it from the root Makefile using:

```
make deploy-example DEPLOYMENT_BUCKET=<YOUR BUCKET NAME>
```

For more information on using FFmpeg and FFprobe, check out <https://ffmpeg.org/documentation.html>

## Author

Gojko Adzic <https://gojko.net>

## License

* These scripts: [MIT](https://opensource.org/licenses/MIT)
* FFmpeg: http://ffmpeg.org/legal.html
