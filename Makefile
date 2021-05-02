STACK_NAME ?= ffmpeg-lgpl-lambda-layer

clean: 
	rm -rf build

build/layer/bin/ffmpeg: 
	mkdir -p build/layer/bin
	rm -rf build/ffmpeg*
	cd build && curl -sL https://github.com/giusedroid/ffmpeg-lgpl-amazonlinux2/blob/main/release/ffmpeg-static-amazonlinux2-lgpl.tar.gz?raw=true | tar xz
	mv build/ffmpeg build/ffprobe build/layer/bin

build/output.yaml: template.yaml build/layer/bin/ffmpeg
	aws cloudformation package --template $< --s3-bucket $(DEPLOYMENT_BUCKET) --output-template-file $@

deploy: build/output.yaml
	aws cloudformation deploy --template $< --stack-name $(STACK_NAME)
	aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query Stacks[].Outputs --output table

deploy-example:
	cd example && \
		make deploy DEPLOYMENT_BUCKET=$(DEPLOYMENT_BUCKET) LAYER_STACK_NAME=$(STACK_NAME)
