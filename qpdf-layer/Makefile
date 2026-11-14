SHELL := /bin/bash
STACK_NAME ?= qpdf-lambda-layer
DEPLOYMENT_BUCKET ?= lambda-layer-bucket-ffmpeg
QPDF_VERSION ?= 12.4.2
QPDF_URL ?= https://github.com/qpdf/qpdf/releases/download/v$(QPDF_VERSION)/qpdf-$(QPDF_VERSION)-bin-linux-x86_64.zip
# Versioned key: bumping QPDF_VERSION changes the CloudFormation parameter,
# which forces a new layer version (a fixed key would make deploy a no-op).
LAYER_ZIP_KEY ?= qpdf-layer-$(QPDF_VERSION).zip
FFMPEG_LAYER_DIR ?= ../build/layer

.PHONY: clean upload deploy check-conflicts verify-local

clean:
	rm -rf build

build/layer/bin/qpdf:
	rm -rf build/qpdf-src build/layer
	mkdir -p build/qpdf-src build/layer/bin build/layer/lib
	curl -fL -o build/qpdf.zip $(QPDF_URL)
	unzip -q build/qpdf.zip -d build/qpdf-src
	cp -a build/qpdf-src/bin/. build/layer/bin/
	cp -a build/qpdf-src/lib/. build/layer/lib/
	chmod +x build/layer/bin/*

build/layer.zip: build/layer/bin/qpdf
	rm -f build/layer.zip
	cd build/layer && zip -r -9 --symlinks ../layer.zip .

upload: build/layer.zip
	aws s3 cp build/layer.zip s3://$(DEPLOYMENT_BUCKET)/$(LAYER_ZIP_KEY)

deploy: upload
	aws cloudformation deploy --template-file template.yaml --stack-name $(STACK_NAME) \
		--parameter-overrides DeploymentBucket=$(DEPLOYMENT_BUCKET) LayerZipKey=$(LAYER_ZIP_KEY)
	aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query Stacks[].Outputs --output table

# Fails if any file path exists in both this layer and the ffmpeg layer
# (both extract into /opt, the later layer silently wins), and reports the
# combined unzipped size against Lambda's 250 MB limit.
check-conflicts: build/layer/bin/qpdf
	@test -d $(FFMPEG_LAYER_DIR) || { echo "ffmpeg layer not built at $(FFMPEG_LAYER_DIR); run 'make build/layer.zip' in the repo root"; exit 1; }
	@dups=$$(comm -12 <(cd build/layer && find . ! -type d | sort) <(cd $(FFMPEG_LAYER_DIR) && find . ! -type d | sort)); \
	if [ -n "$$dups" ]; then echo "CONFLICT: paths present in both layers:"; echo "$$dups"; exit 1; fi; \
	echo "No path conflicts between qpdf and ffmpeg layers."
	@q=$$(du -sk build/layer | cut -f1); f=$$(du -sk $(FFMPEG_LAYER_DIR) | cut -f1); \
	echo "qpdf: $$((q/1024)) MB, ffmpeg: $$((f/1024)) MB, combined: $$(((q+f)/1024)) MB of 250 MB (function code counts too)"

# Runs the layer inside the real Lambda nodejs20 image to catch glibc / missing .so issues.
verify-local: build/layer/bin/qpdf
	docker run --rm --platform linux/amd64 -v "$(CURDIR)/build/layer:/opt:ro" \
		--entrypoint /bin/sh public.ecr.aws/lambda/nodejs:20 \
		-c 'echo "LD_LIBRARY_PATH=$$LD_LIBRARY_PATH"; ldd /opt/bin/qpdf; ! ldd /opt/bin/qpdf | grep -q "not found" && /opt/bin/qpdf --version'
