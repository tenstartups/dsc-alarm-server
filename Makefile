DOCKER_IMAGE_NAME := tenstartups/dsc-alarm-connect
DOCKER_ARCH := $(shell uname -m)
ifneq (,$(findstring arm,$(DOCKER_ARCH)))
	DOCKER_PLATFORM := rpi
	DOCKER_IMAGE_NAME := $(subst /,/${DOCKER_PLATFORM}-,${DOCKER_IMAGE_NAME})
else
	DOCKER_PLATFORM := x64
endif

build: Dockerfile.${DOCKER_PLATFORM}
	docker build --file Dockerfile.${DOCKER_PLATFORM} --tag ${DOCKER_IMAGE_NAME} .

clean_build: Dockerfile.${DOCKER_PLATFORM}
	docker build --no-cache --file Dockerfile.${DOCKER_PLATFORM} --tag ${DOCKER_IMAGE_NAME} .

run: build
	docker run -it --rm \
	-p 4567:4567 \
	-v /etc/localtime:/etc/localtime \
	-v "${PWD}":/etc/dsc-connect \
	-e VIRTUAL_HOST=dsc.docker \
	-e IT100_URI=${IT100_URI} \
	-e DSC_REST_SERVER_ACTIVE=true \
	-e DSC_EVENT_HANDLER_ISY994=DSCConnect::ISY994EventHandler \
	-e ISY994_EVENT_HANDLER_CONFIG=/etc/dsc-connect/isy-config.yml \
	--name dsc-connect \
	${DOCKER_IMAGE_NAME} ${ARGS}

push: clean_build
	docker push ${DOCKER_IMAGE_NAME}:latest
