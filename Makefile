SERVER_VERSION=7.1.13-11ddea2a3a
SERVER_VERSION_PREVIEW=7.0.5-6b319cdd26
SERVER_VERSION_6_5=6.5.27-53746e2b5a
SERVER_VERSION_6_8=6.8.24-8e110b7bed
SERVER_VERSION_7_0=7.0.23-fb3626fb91
CLIENT_VERSION=1.0.0
TOOLBOX_VERSION=1.9.1
STUDIO_VERSION=3.0.0
KUBE_CLIENT_VERSION=v1.11.6
REVISION=$(shell git describe --dirty=-dirty --always --long --abbrev=40 --match='')

VARIANT ?= centos

ifeq (${VARIANT},redhat)
BASE_IMAGE=registry.access.redhat.com/ubi7/ubi:7.7-358
else
BASE_IMAGE=centos:7
endif

NODE_TAG=${VARIANT}-${SERVER_VERSION}
NODE_TAG_PREVIEW=${VARIANT}-${SERVER_VERSION_PREVIEW}-preview
NODE_TAG_6_5=${VARIANT}-${SERVER_VERSION_6_5}
NODE_TAG_6_8=${VARIANT}-${SERVER_VERSION_6_8}
NODE_TAG_7_0=${VARIANT}-${SERVER_VERSION_7_0}
DYNAMIC_TAG=${VARIANT}-${REVISION}
CIAB_TAG=${VARIANT}-${SERVER_VERSION}-${STUDIO_VERSION}-${TOOLBOX_VERSION}
TOOLS_TAG=${VARIANT}-${KUBE_CLIENT_VERSION}-${TOOLBOX_VERSION}-${REVISION}

.PHONY: build
build:
	${MAKE} build-dynamic-node
	${MAKE} build-ciab

.PHONY: build-dev
build-dev: build
	${MAKE} build-ciab-dev

.PHONY: test
test:
	# node
	${MAKE} build-node
	${MAKE} test-node
	${MAKE} test-node-ssl
	# node-preview
	${MAKE} build-node-preview
	${MAKE} test-node-preview
	${MAKE} test-node-preview-ssl
	# node-6-5
	${MAKE} build-node-6-5
	${MAKE} test-node-6-5
	# node-6-8
	${MAKE} build-node-6-8
	${MAKE} test-node-6-8
	# node-7-0
	${MAKE} build-node-7-0
	${MAKE} test-node-7-0
	# node-redhat
	${MAKE} build-node VARIANT=redhat
	${MAKE} test-node VARIANT=redhat
	# node-7-0-redhat
	${MAKE} build-node-7-0 VARIANT=redhat
	${MAKE} test-node-7-0 VARIANT=redhat
	# dynamic node
	${MAKE} build-dynamic-node
	${MAKE} test-dynamic-node
	# cluster-in-a-box (ciab)
	${MAKE} build-ciab
	${MAKE} test-ciab
	# cluster-in-a-box (ciab) redhat
	${MAKE} build-ciab VARIANT=redhat
	${MAKE} test-ciab VARIANT=redhat

.PHONY: build-base
build-base:
	docker build \
		--build-arg BASE_IMAGE=${BASE_IMAGE} \
		-t memsql-base:${VARIANT} \
		-f Dockerfile-base .

.PHONY: build-base-dev
build-base-dev:
	docker build \
		--build-arg BASE_IMAGE=${BASE_IMAGE} \
		--build-arg RELEASE_CHANNEL=dev \
		-t memsql-base-dev:${VARIANT} \
		-f Dockerfile-base .

.PHONY: build-tools
build-tools: build-base
	docker build \
		--build-arg BASE_IMAGE=memsql-base:${VARIANT} \
		--build-arg TOOLBOX_VERSION=${TOOLBOX_VERSION} \
		--build-arg KUBE_CLIENT_VERSION=${KUBE_CLIENT_VERSION} \
		-t memsql/tools:${TOOLS_TAG} \
		-f Dockerfile-tools .
	docker tag memsql/tools:${TOOLS_TAG} memsql/tools:latest

.PHONY: build-node
build-node: build-base
	docker build \
		--build-arg BASE_IMAGE=memsql-base:${VARIANT} \
		--build-arg SERVER_VERSION=${SERVER_VERSION} \
		--build-arg CLIENT_VERSION=${CLIENT_VERSION} \
		-t memsql/node:${NODE_TAG} \
		-f Dockerfile-node .
	docker tag memsql/node:${NODE_TAG} memsql/node:latest

.PHONY: build-node-preview
build-node-preview: build-base-dev
	docker build \
		--build-arg BASE_IMAGE=memsql-base-dev:${VARIANT} \
		--build-arg SERVER_VERSION=${SERVER_VERSION_PREVIEW} \
		--build-arg CLIENT_VERSION=${CLIENT_VERSION} \
		-t memsql/node:${NODE_TAG_PREVIEW} \
		-f Dockerfile-node .

.PHONY: build-node-6-5
build-node-6-5: build-base-dev
	docker build \
		--build-arg BASE_IMAGE=memsql-base-dev:${VARIANT} \
		--build-arg SERVER_VERSION=${SERVER_VERSION_6_5} \
		--build-arg CLIENT_VERSION=${CLIENT_VERSION} \
		-t memsql/node:${NODE_TAG_6_5} \
		-f Dockerfile-node .

.PHONY: build-node-6-8
build-node-6-8: build-base
	docker build \
		--build-arg BASE_IMAGE=memsql-base:${VARIANT} \
		--build-arg SERVER_VERSION=${SERVER_VERSION_6_8} \
		--build-arg CLIENT_VERSION=${CLIENT_VERSION} \
		-t memsql/node:${NODE_TAG_6_8} \
		-f Dockerfile-node .

.PHONY: build-node-7-0
build-node-7-0: build-base
	docker build \
		--build-arg BASE_IMAGE=memsql-base:${VARIANT} \
		--build-arg SERVER_VERSION=${SERVER_VERSION_7_0} \
		--build-arg CLIENT_VERSION=${CLIENT_VERSION} \
		-t memsql/node:${NODE_TAG_7_0} \
		-f Dockerfile-node .

.PHONY: test-node
test-node: test-destroy
	IMAGE=memsql/node:${NODE_TAG} ./test/node

.PHONY: test-node-preview
test-node-preview: test-destroy
	IMAGE=memsql/node:${NODE_TAG_PREVIEW} ./test/node

.PHONY: test-node-6-5
test-node-6-5: test-destroy
	IMAGE=memsql/node:${NODE_TAG_6_5} ./test/node

.PHONY: test-node-6-8
test-node-6-8: test-destroy
	IMAGE=memsql/node:${NODE_TAG_6_8} ./test/node

.PHONY: test-node-7-0
test-node-7-0: test-destroy
	IMAGE=memsql/node:${NODE_TAG_7_0} ./test/node

.PHONY: test-node-ssl
test-node-ssl: test-destroy
	IMAGE=memsql/node:${NODE_TAG} ./test/node-ssl

.PHONY: test-node-preview-ssl
test-node-preview-ssl: test-destroy
	IMAGE=memsql/node:${NODE_TAG_PREVIEW} ./test/node-ssl

.PHONY: publish-node
publish-node:
	docker push memsql/node:${NODE_TAG}
	docker tag memsql/node:${NODE_TAG} memsql/node:latest
	docker push memsql/node:latest

.PHONY: stage-node
stage-node:
	docker tag memsql/node:${NODE_TAG} memsql/node:staging-${NODE_TAG}
	docker push memsql/node:staging-${NODE_TAG}

.PHONY: publish-node-preview
publish-node-preview:
	docker push memsql/node:${NODE_TAG_PREVIEW}

.PHONY: stage-node-preview
stage-node-preview:
	docker tag memsql/node:${NODE_TAG_PREVIEW} memsql/node:staging-${NODE_TAG_PREVIEW}
	docker push memsql/node:staging-${NODE_TAG_PREVIEW}

.PHONY: publish-node-6-5
publish-node-6-5:
	docker push memsql/node:${NODE_TAG_6_5}

.PHONY: publish-node-6-8
publish-node-6-8:
	docker push memsql/node:${NODE_TAG_6_8}

.PHONY: publish-node-7-0
publish-node-7-0:
	docker push memsql/node:${NODE_TAG_7_0}

.PHONY: redhat-verify-node
redhat-verify-node:
	docker tag memsql/node:${NODE_TAG} scan.connect.redhat.com/ospid-faf4ba09-5344-40d5-b9c5-7c88ea143472/node:${NODE_TAG}
	docker push scan.connect.redhat.com/ospid-faf4ba09-5344-40d5-b9c5-7c88ea143472/node:${NODE_TAG}
	@echo "View results + publish: https://connect.redhat.com/project/1123901/view"

.PHONY: redhat-verify-node-7-0
redhat-verify-node-7-0:
	docker tag memsql/node:${NODE_TAG_7_0} scan.connect.redhat.com/ospid-faf4ba09-5344-40d5-b9c5-7c88ea143472/node:${NODE_TAG_7_0}
	docker push scan.connect.redhat.com/ospid-faf4ba09-5344-40d5-b9c5-7c88ea143472/node:${NODE_TAG_7_0}
	@echo "View results + publish: https://connect.redhat.com/project/1123901/view"

.PHONY: build-dynamic-node
build-dynamic-node: build-base
	docker build \
		--build-arg BASE_IMAGE=memsql-base:${VARIANT} \
		--build-arg CLIENT_VERSION=${CLIENT_VERSION} \
		-t memsql/dynamic-node:${DYNAMIC_TAG} \
		-f Dockerfile-dynamic .
	docker tag memsql/dynamic-node:${DYNAMIC_TAG} memsql/dynamic-node:latest

.PHONY: test-dynamic-node
test-dynamic-node: test-destroy
	IMAGE=memsql/dynamic-node:${DYNAMIC_TAG} ./test/node

.PHONY: publish-dynamic-node
publish-dynamic-node:
	docker push memsql/dynamic-node:${DYNAMIC_TAG}
	docker tag memsql/dynamic-node:${DYNAMIC_TAG} memsql/dynamic-node:latest
	docker push memsql/dynamic-node:latest

.PHONY: build-ciab
build-ciab: build-base
	docker build \
		--build-arg BASE_IMAGE=memsql-base:${VARIANT} \
		--build-arg SERVER_VERSION=${SERVER_VERSION} \
		--build-arg CLIENT_VERSION=${CLIENT_VERSION} \
		--build-arg STUDIO_VERSION=${STUDIO_VERSION} \
		--build-arg TOOLBOX_VERSION=${TOOLBOX_VERSION} \
		-t memsql/cluster-in-a-box:${CIAB_TAG} \
		-f Dockerfile-ciab .
	docker tag memsql/cluster-in-a-box:${CIAB_TAG} memsql/cluster-in-a-box:latest

.PHONY: build-ciab-dev
build-ciab-dev: build-base-dev
	docker build \
		--build-arg BASE_IMAGE=memsql-base-dev:${VARIANT} \
		--build-arg SERVER_VERSION=${SERVER_VERSION} \
		--build-arg CLIENT_VERSION=${CLIENT_VERSION} \
		--build-arg STUDIO_VERSION=${STUDIO_VERSION} \
		--build-arg TOOLBOX_VERSION=${TOOLBOX_VERSION} \
		-t memsql/cluster-in-a-box-dev:${CIAB_TAG} \
		-f Dockerfile-ciab .
	docker tag memsql/cluster-in-a-box-dev:${CIAB_TAG} memsql/cluster-in-a-box-dev:latest

.PHONY: test-ciab
test-ciab: test-destroy
	IMAGE=memsql/cluster-in-a-box:${CIAB_TAG} ./test/ciab

.PHONY: publish-ciab
publish-ciab:
	docker push memsql/cluster-in-a-box:${CIAB_TAG}
	docker tag memsql/cluster-in-a-box:${CIAB_TAG} memsql/cluster-in-a-box:latest
	docker push memsql/cluster-in-a-box:latest

.PHONY: redhat-verify-ciab
redhat-verify-ciab:
	docker tag memsql/cluster-in-a-box:${CIAB_TAG} scan.connect.redhat.com/ospid-6b69e5e1-d98a-4d75-a591-e300d4820ecb/cluster-in-a-box:${CIAB_TAG}
	docker push scan.connect.redhat.com/ospid-6b69e5e1-d98a-4d75-a591-e300d4820ecb/cluster-in-a-box:${CIAB_TAG}
	@echo "View results + publish: https://connect.redhat.com/project/923891/view"

.PHONY: test-destroy
test-destroy:
	@-docker rm -f memsql-node-ma memsql-node-leaf memsql-ciab
	@-docker volume rm memsql-node-ma memsql-node-leaf memsql-ciab

.PHONY: publish-tools
publish-tools:
	docker push memsql/tools:${TOOLS_TAG}
	docker tag memsql/tools:${TOOLS_TAG} memsql/tools:latest
	docker push memsql/tools:latest

.PHONY: stage-tools
stage-tools:
	docker tag memsql/tools:${TOOLS_TAG} memsql/tools:staging-${TOOLS_TAG}
	docker push memsql/tools:staging-${TOOLS_TAG}

.PHONY: requires-license
requires-license:
ifndef LICENSE_KEY
	$(error LICENSE_KEY is required)
endif
