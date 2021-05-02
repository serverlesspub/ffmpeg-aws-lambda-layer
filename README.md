# FFmpeg/FFprobe for AWS Lambda (LGPL v2.1)

A Lambda layer containing a static version of FFmpeg/FFprobe utilities from the [`FFmpeg`](https://www.ffmpeg.org/) Linux package, compatible with Amazon Linux 2.x and Amazon Linux 1.x instances (including the `nodejs10.x` runtime, and the updated 2018.03 Amazon Linux 1 runtimes). 

## Prerequisites

* Unix Make environment
* AWS command line utilities (just for deployment)

## Deploying to AWS as a layer

This package includes FFmpeg 4.2.2 compiled to be compatible with LGPL v2.1, packaged by [giusedroid](https://twitter.com/giusedroid). For more information, check out [the build repo](https://github.com/giusedroid/ffmpeg-lgpl-amazonlinux2).

Run the following command to deploy the compiled result as a layer in your AWS account.

```
make deploy DEPLOYMENT_BUCKET=<YOUR BUCKET NAME>
```

### configuring the deployment

By default, this uses `ffmpeg-lgpl-lambda-layer` as the stack name. Provide a `STACK_NAME` variable when calling `make deploy` to use an alternative name.

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
* FFmpeg: http://ffmpeg.org/legal.html . More details in the next section.

## Notice about the usage of FFmpeg

This software uses code of <a href=http://ffmpeg.org>FFmpeg</a> licensed under
the <a href=http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html>LGPLv2.1</a>
and its source can be downloaded <a href="https://github.com/giusedroid/ffmpeg-lgpl-amazonlinux2/blob/main/ffmpeg/ffmpeg-4.2.2.tar.bz2?raw=true">here</a>.   

A copy of the LGPLv2.1 is also available [here](https://github.com/giusedroid/ffmpeg-lgpl-amazonlinux2/blob/main/ffmpeg/LICENSE).  

## Compilation Process
FFmpeg source code has **NOT** been modified for this software.  
FFmpeg has been compiled with the following configuration.  

```
ffmpeg version 4.2.2 Copyright (c) 2000-2019 the FFmpeg developers
  built with gcc 7 (GCC)
  configuration: --prefix=/home/ec2-user/ffmpeg_build --pkg-config-flags=--static --extra-cflags='-I/home/ec2-user/ffmpeg_build/include -static' --extra-ldflags='-L/home/ec2-user/ffmpeg_build/lib -static' --disable-debug --disable-doc --disable-ffplay --bindir=/home/ec2-user/bin
  libavutil      56. 31.100 / 56. 31.100
  libavcodec     58. 54.100 / 58. 54.100
  libavformat    58. 29.100 / 58. 29.100
  libavdevice    58.  8.100 / 58.  8.100
  libavfilter     7. 57.100 /  7. 57.100
  libswscale      5.  5.100 /  5.  5.100
  libswresample   3.  5.100 /  3.  5.100
```
FFmpeg has been compiled **without** `--enable-gpl` and `--enable-nonfree` in order to comply with the terms of [LGPLv2.1](/ffmpeg/LICENSE).  
You can have further details on the compilation process in the [Dockerfile](/Dockerfile) and in the [local build script](/build.sh) 

You can check that the `ffmpeg` single binary has no dynamic dependencies by
```
Admin:~/environment $ ldd ./ffmpeg
        not a dynamic executable
```

You can also check FFmpeg license by
```
Admin:~/environment $ ./ffmpeg -L
```

You should expect the following output
```
ffmpeg version 4.2.2 Copyright (c) 2000-2019 the FFmpeg developers
  built with gcc 7 (GCC)
  configuration: --prefix=/opt/ffmpeg --pkg-config-flags=--static --extra-cflags='-I/opt/ffmpeg/include -static' --extra-ldflags='-L/opt/ffmpeg/lib -static' --disable-debug --disable-doc --disable-ffplay --bindir=/opt/ffmpeg/bin
  libavutil      56. 31.100 / 56. 31.100
  libavcodec     58. 54.100 / 58. 54.100
  libavformat    58. 29.100 / 58. 29.100
  libavdevice    58.  8.100 / 58.  8.100
  libavfilter     7. 57.100 /  7. 57.100
  libswscale      5.  5.100 /  5.  5.100
  libswresample   3.  5.100 /  3.  5.100
ffmpeg is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

ffmpeg is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with ffmpeg; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
```

## Binaries
Standalone Binaries for FFmpeg and FFprobe compiled on Amazonlinux2 are available [here](https://github.com/giusedroid/ffmpeg-lgpl-amazonlinux2/tree/main/bin).  
These have been compiled with the same configuration set.

## Release
You can find an archive with both FFmpeg and FFprobe static binaries for AmazonLinux2 [here](https://github.com/giusedroid/ffmpeg-lgpl-amazonlinux2/tree/main/release).
