DOCKER_IMAGE_NAME := tenstartups/dsc-alarm-connect
UNAME_S := $(shell uname -m)
ifneq (,$(findstring arm,$(UNAME_S)))
	PLATFORM := arm
	DOCKER_IMAGE_NAME := $(subst /,/${PLATFORM}-,${DOCKER_IMAGE_NAME})
else
	PLATFORM := x86_64
endif

build: Dockerfile.${PLATFORM}
	docker build --file Dockerfile.${PLATFORM} --tag ${DOCKER_IMAGE_NAME} .

clean_build: Dockerfile.${PLATFORM}
	docker build --no-cache --file Dockerfile.${PLATFORM} --tag ${DOCKER_IMAGE_NAME} .

run: build
	docker run -it --rm \
	-p 4567:4567 \
	-v /etc/localtime:/etc/localtime \
	-v "${PWD}":/etc/dsc-connect \
	-e VIRTUAL_HOST=dsc.docker \
	-e IT100_URI=${IT100_URI} \
	-e DSC_REST_SERVER_ACTIVE=true \
	-e DSC_EVENT_HANDLER_ISY994=ISY994EventHandler \
	-e ISY994_EVENT_HANDLER_CONFIG=/etc/dsc-connect/isy-config.yml \
	--name dsc-connect \
	${DOCKER_IMAGE_NAME} ${ARGS}

push: clean_build
	docker push ${DOCKER_IMAGE_NAME}:latest
