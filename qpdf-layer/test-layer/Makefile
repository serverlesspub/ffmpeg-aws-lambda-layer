STACK_NAME ?= qpdf-layer-test
QPDF_LAYER_STACK_NAME ?= qpdf-lambda-layer
FFMPEG_LAYER_STACK_NAME ?= ffmpeg-lambda-layer
DEPLOYMENT_BUCKET ?= lambda-layer-bucket-ffmpeg

QPDF_LAYER_ARN := $(shell aws cloudformation describe-stacks \
	--stack-name $(QPDF_LAYER_STACK_NAME) \
	--query "Stacks[0].Outputs[?OutputKey=='LayerVersion'].OutputValue" \
	--output text)

# Optional: empty if the ffmpeg stack doesn't exist; the test then skips the ffmpeg check.
FFMPEG_LAYER_ARN := $(shell aws cloudformation describe-stacks \
	--stack-name $(FFMPEG_LAYER_STACK_NAME) \
	--query "Stacks[0].Outputs[?OutputKey=='LayerVersion'].OutputValue" \
	--output text 2>/dev/null)

FUNC_NAME := $(shell aws cloudformation describe-stacks \
	--stack-name $(STACK_NAME) \
	--query "Stacks[0].Outputs[?OutputKey=='TestFunction'].OutputValue" \
	--output text 2>/dev/null)

.PHONY: package deploy invoke clean destroy

package: packaged.yaml

packaged.yaml: template.yaml index.mjs
	aws cloudformation package \
		--template-file template.yaml \
		--s3-bucket $(DEPLOYMENT_BUCKET) \
		--output-template-file packaged.yaml

deploy: packaged.yaml
	aws cloudformation deploy \
		--template-file packaged.yaml \
		--stack-name $(STACK_NAME) \
		--parameter-overrides QpdfLayerArn=$(QPDF_LAYER_ARN) FFmpegLayerArn=$(FFMPEG_LAYER_ARN) \
		--capabilities CAPABILITY_IAM
	aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query Stacks[].Outputs --output table

invoke:
	aws lambda invoke --function-name $(FUNC_NAME) /dev/stdout

clean:
	rm -f packaged.yaml

destroy:
	aws cloudformation delete-stack --stack-name $(STACK_NAME)
