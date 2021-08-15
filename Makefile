BUILD_DIR = $(shell pwd)

update:
	docker run --rm -v ${BUILD_DIR}:${BUILD_DIR} --workdir ${BUILD_DIR} quay.io/coreos/jsonnet-ci jb update

build:
	docker run --rm -v ${BUILD_DIR}:${BUILD_DIR} --workdir ${BUILD_DIR} quay.io/coreos/jsonnet-ci ./build.sh ./main.jsonnet

up:
	microk8s kubectl apply -f ${BUILD_DIR}/manifests/setup
	microk8s kubectl apply -f ${BUILD_DIR}/manifests

create_secret:
	microk8s kubectl create secret generic additional-configs --from-file=${BUILD_DIR}/prometheus-additional.yaml -n monitoring

down:
	microk8s kubectl delete --ignore-not-found=true -f ${BUILD_DIR}/manifests/ -f ${BUILD_DIR}/manifests/setup

prometheus:
	microk8s kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090