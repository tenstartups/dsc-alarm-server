DOCKER_IMAGE_NAME := tenstartups/dsc-alarm-connect
ifeq ($(DOCKER_ARCH),rpi)
	DOCKER_IMAGE_NAME := $(subst /,/$(DOCKER_ARCH)-,$(DOCKER_IMAGE_NAME))
endif

build: Dockerfile.$(DOCKER_ARCH)
	docker build --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME) .

clean_build: Dockerfile.$(DOCKER_ARCH)
	docker build --no-cache --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME) .

run: build
	docker run -it --rm \
	-p 8080:8080 \
	-v /etc/localtime:/etc/localtime \
	-v "${PWD}":/etc/dsc-connect \
	-e VIRTUAL_HOST=dsc-connect.docker \
	-e IT100_URI=${IT100_URI} \
	-e ISY994_URI=${ISY994_URI} \
	-e DSC_CONNECT_CONFIG=/etc/dsc-connect/config.yml \
	--name dsc-connect \
	${DOCKER_IMAGE_NAME} ${ARGS}

push: build
	docker push ${DOCKER_IMAGE_NAME}:latest
