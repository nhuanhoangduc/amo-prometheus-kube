BUILD_DIR = $(shell pwd)

create_secret:
	kubectl create secret generic additional-scrape-configs --from-file=${BUILD_DIR}/exporters/prometheus-additional.yaml --dry-run=client -oyaml > ${BUILD_DIR}/exporters/additional-scrape-configs.yaml

create_rule:
	cat my-prometheus-rule.yaml | gojsontoyaml -yamltojson > my-prometheus-rule.json

update:
	docker run --rm -v ${BUILD_DIR}:${BUILD_DIR} --workdir ${BUILD_DIR} quay.io/coreos/jsonnet-ci jb update

build:
	make create_secret
	make create_rule
	docker run --rm -v ${BUILD_DIR}:${BUILD_DIR} --workdir ${BUILD_DIR} quay.io/coreos/jsonnet-ci ./build.sh ./main.jsonnet

prometheus:
	kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
	
grafana:
	kubectl --namespace monitoring port-forward svc/grafana 3000
	
alertmanager:
	kubectl --namespace monitoring port-forward svc/alertmanager-main 9093

up:
	kubectl apply -f ${BUILD_DIR}/manifests/setup
	kubectl apply -f ${BUILD_DIR}/exporters/nats_exporter.yaml
	kubectl apply -f ${BUILD_DIR}/exporters/redis_exporter.yaml
	kubectl apply -f ${BUILD_DIR}/exporters/additional-scrape-configs.yaml -n monitoring
	kubectl apply -f ${BUILD_DIR}/manifests

down:
	kubectl delete --ignore-not-found=true -f ${BUILD_DIR}/manifests/ -f ${BUILD_DIR}/manifests/setup