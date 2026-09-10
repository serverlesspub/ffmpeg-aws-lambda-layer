STACK_NAME ?= ffmpeg-lambda-layer
DEPLOYMENT_BUCKET ?= lambda-layer-bucket-ffmpeg
LAYER_ZIP_KEY ?= ffmpeg-layer.zip
FFMPEG_URL ?= https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2026-08-31-13-27/ffmpeg-n8.1.2-50-g1a748fe2cd-linux64-gpl-shared-8.1.tar.xz

clean:
	rm -rf build

build/layer/bin/ffmpeg:
	mkdir -p build/layer/bin build/layer/lib
	rm -rf build/ffmpeg*
	cd build && curl -L $(FFMPEG_URL) | tar xJ
	mv build/ffmpeg*/bin/ffmpeg build/ffmpeg*/bin/ffprobe build/layer/bin
	cp -a build/ffmpeg*/lib/*.so* build/layer/lib/

build/layer.zip: build/layer/bin/ffmpeg
	cd build/layer && zip -r -9 --symlinks ../layer.zip .

upload: build/layer.zip
	aws s3 cp build/layer.zip s3://$(DEPLOYMENT_BUCKET)/$(LAYER_ZIP_KEY)

deploy: upload
	aws cloudformation deploy --template template.yaml --stack-name $(STACK_NAME) \
		--parameter-overrides DeploymentBucket=$(DEPLOYMENT_BUCKET) LayerZipKey=$(LAYER_ZIP_KEY)
	aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query Stacks[].Outputs --output table

deploy-example:
	cd example && \
		make deploy DEPLOYMENT_BUCKET=$(DEPLOYMENT_BUCKET) LAYER_STACK_NAME=$(STACK_NAME)
