STACK_NAME ?= ffmpeg-layer-test
LAYER_STACK_NAME ?= ffmpeg-lambda-layer
DEPLOYMENT_BUCKET ?= lambda-layer-bucket-ffmpeg

LAYER_ARN := $(shell aws cloudformation describe-stacks \
	--stack-name $(LAYER_STACK_NAME) \
	--query "Stacks[0].Outputs[?OutputKey=='LayerVersion'].OutputValue" \
	--output text)

FUNC_NAME := $(shell aws cloudformation describe-stacks \
	--stack-name $(STACK_NAME) \
	--query "Stacks[0].Outputs[?OutputKey=='TestFunction'].OutputValue" \
	--output text 2>/dev/null)

package: packaged.yaml

packaged.yaml: template.yaml app.py
	aws cloudformation package \
		--template template.yaml \
		--s3-bucket $(DEPLOYMENT_BUCKET) \
		--output-template-file packaged.yaml

deploy: packaged.yaml
	aws cloudformation deploy \
		--template packaged.yaml \
		--stack-name $(STACK_NAME) \
		--parameter-overrides FFmpegLayerArn=$(LAYER_ARN) \
		--capabilities CAPABILITY_IAM
	aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query Stacks[].Outputs --output table

invoke:
	aws lambda invoke --function-name $(FUNC_NAME) /dev/stdout

clean:
	rm -f packaged.yaml

destroy:
	aws cloudformation delete-stack --stack-name $(STACK_NAME)
