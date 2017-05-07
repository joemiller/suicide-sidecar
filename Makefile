IMAGE ?= quay.io/getpantheon/suicide-sidecar

ifdef CIRCLE_BUILD_NUM
	TAG := $(CIRCLE_BUILD_NUM)
else
	TAG := dev
endif

build:
	docker build -t $(IMAGE):$(TAG) .

push:
	docker push $(IMAGE):$(TAG)
