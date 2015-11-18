UNAME_S := $(shell uname -m)
ifneq (,$(findstring arm,$(UNAME_S)))
	PLATFORM=arm
	DOCKER_IMAGE_NAME=tenstartups/rpi-dsc-alarm-connect
else
	PLATFORM=x86_64
	DOCKER_IMAGE_NAME=tenstartups/dsc-alarm-connect
endif

build: ${PLATFORM}/Dockerfile
	cp ${PLATFORM}/Dockerfile .; docker build -t ${DOCKER_IMAGE_NAME} .

clean_build: ${PLATFORM}/Dockerfile
	cp ${PLATFORM}/Dockerfile .; docker build --no-cache=true -t ${DOCKER_IMAGE_NAME} .

run: build
	docker run -it --rm \
	-p 4567:4567 \
	-v /etc/localtime:/etc/localtime \
	-v "${PWD}":/etc/dsc-connect \
	-e VIRTUAL_HOST=dsc.docker \
	-e IT100_URI=${IT100_URI} \
	-e DSC_REST_SERVER_ACTIVE=true \
	-e DSC_EVENT_HANDLER_ISY994=ISY994EventHandler \
	-e ISY994_EVENT_HANDLER_CONFIG=/etc/dsc-connect/isy994-event-handler.yml \
	--name dsc-connect \
	${DOCKER_IMAGE_NAME} ${ARGS}

push: clean_build
	docker push ${DOCKER_IMAGE_NAME}:latest
