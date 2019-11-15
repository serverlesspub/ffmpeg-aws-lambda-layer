STACK_NAME ?= ffmpeg-lambda-layer
AWS_PROFILE ?= default

clean: 
	rm -rf build

build/layer/bin/ffmpeg: 
	mkdir -p build/layer/bin
	rm -rf build/ffmpeg*
	cd build && curl https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz | tar x
	mv build/ffmpeg*/ffmpeg build/ffmpeg*/ffprobe build/layer/bin

build/output.yaml: template.yaml build/layer/bin/ffmpeg
	aws --profile $(AWS_PROFILE) cloudformation package --template $< --s3-bucket $(DEPLOYMENT_BUCKET) --output-template-file $@

deploy: build/output.yaml
	aws --profile $(AWS_PROFILE) cloudformation deploy --template $< --stack-name $(STACK_NAME)
	aws --profile $(AWS_PROFILE) cloudformation describe-stacks --stack-name $(STACK_NAME) --query Stacks[].Outputs --output table

deploy-example:
	cd example && \
		make deploy DEPLOYMENT_BUCKET=$(DEPLOYMENT_BUCKET) LAYER_STACK_NAME=$(STACK_NAME)
