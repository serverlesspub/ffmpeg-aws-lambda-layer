# FFmpeg/FFprobe AWS Lambda layer

This is an AWS Lambda layer containing statically linked `ffmpeg` and `ffprobe` binary utilities from the [`FFmpeg`](https://www.ffmpeg.org/) Linux package, allowing you to convert videos and extract metadata about video files in AWS Lambda, deployable as an AWS lambda layer. It can help you get started quickly with FFmpeg inside Lambda functions.

## Use within Lambda

You can use a pre-deployed ARN: `arn:aws:lambda:us-east-1:145266761615:layer:ffmpeg:4` or deploy yourself -- edit Makefile to set your deployment bucket etc, then just run `make deploy`.

The binares will be in `/opt/bin/ffmpeg` and `/opt/bin/ffprobe` inside your Lambda container.

## FFmpeg Version

This package includes FFmpeg 4.1, packaged by Johan Van Sickle. Please consider supporting him for maintaining statically built FFmpeg packages. For more information, check out <https://johnvansickle.com/ffmpeg/>

## Copyright and license

FFMpeg is licensed under [GNU GENERAL PUBLIC LICENSE 2.1 or later](https://www.ffmpeg.org/legal.html).

