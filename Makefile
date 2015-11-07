DOCKER_IMAGE_NAME=tenstartups/dsc-isy-bridge

build: Dockerfile
	docker build -t ${DOCKER_IMAGE_NAME} .

push: build
	docker push ${DOCKER_IMAGE_NAME}

run: build
	docker run -it --rm -v "${PWD}":/dsc_isy_bridge -e IT100_URI=${IT100_URI} -e ISY994_URI=${ISY994_URI} -e DSC_ISY_BRIDGE_CONFIG=/dsc_isy_bridge/config.yml ${DOCKER_IMAGE_NAME} ${ARGS}
