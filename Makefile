IMAGE := quay.io/getpantheon/suicide-sidecar
TAG := TODO

build:
	docker build -t $(IMAGE):$(TAG) .

push:
	docker push $(IMAGE):$(TAG)
