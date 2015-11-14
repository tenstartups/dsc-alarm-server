UNAME_S := $(shell uname -m)
ifneq (,$(findstring arm,$(UNAME_S)))
	PLATFORM=arm
	DOCKER_IMAGE_NAME=tenstartups/rpi-dsc-isy-connect
else
	PLATFORM=x86_64
	DOCKER_IMAGE_NAME=tenstartups/dsc-isy-connect
endif

build: ${PLATFORM}/Dockerfile
	cp ${PLATFORM}/Dockerfile .; docker build -t ${DOCKER_IMAGE_NAME} .

clean_build: ${PLATFORM}/Dockerfile
	cp ${PLATFORM}/Dockerfile .; docker build --no-cache=true -t ${DOCKER_IMAGE_NAME} .

run: build
	docker run -it --rm -v /etc/localtime:/etc/localtime -p 8080:4567 -v "${PWD}":/etc/dsc-isy -e RACK_ENV=production -e IT100_URI=${IT100_URI} -e ISY994_URI=${ISY994_URI} -e DSC_ISY_CONFIG=/etc/dsc-isy/config.yml ${DOCKER_IMAGE_NAME} ${ARGS}

push: clean_build
	docker push ${DOCKER_IMAGE_NAME}:latest
