UNAME_S := $(shell uname -m)
ifneq (,$(findstring arm,$(UNAME_S)))
  PLATFORM=rpi
else
  PLATFORM=x64
endif
DOCKER_IMAGE_NAME=tenstartups/${PLATFORM}-dsc-isy-connect

clean_build: ${PLATFORM}/Dockerfile
	cp ${PLATFORM}/Dockerfile .; docker build --no-cache=true -t ${DOCKER_IMAGE_NAME} .

build: ${PLATFORM}/Dockerfile
	cp ${PLATFORM}/Dockerfile .; docker build -t ${DOCKER_IMAGE_NAME} .

run: build
	docker run -it --rm -v /etc/localtime:/etc/localtime -v "${PWD}":/etc/dsc-isy -e IT100_URI=${IT100_URI} -e ISY994_URI=${ISY994_URI} -e DSC_ISY_BRIDGE_CONFIG=/etc/dsc-isy/config.yml ${DOCKER_IMAGE_NAME} ${ARGS}

push: clean_build
	docker push ${DOCKER_IMAGE_NAME}:latest
