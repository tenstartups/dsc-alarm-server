ifeq ($(DOCKER_ARCH),armhf)
	DOCKER_IMAGE_NAME := tenstartups/dsc-alarm-connect:armhf
else
	DOCKER_IMAGE_NAME := tenstartups/dsc-alarm-connect:latest
endif

build: Dockerfile.$(DOCKER_ARCH)
	docker build --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME) .

clean_build: Dockerfile.$(DOCKER_ARCH)
	docker build --no-cache --pull --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME) .

run: build
	docker run -it --rm \
	-p 8080:8080 \
	-v /etc/localtime:/etc/localtime \
	-v "$(PWD)/test":/etc/dsc-connect \
	-e VIRTUAL_HOST=dsc-connect.docker \
	-e DSC_CONNECT_CONFIG=/etc/dsc-connect/config.yml \
	--name dsc-connect \
	$(DOCKER_IMAGE_NAME) $(ARGS)

push: build
	docker push $(DOCKER_IMAGE_NAME)
