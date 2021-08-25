BUILD_DIR = $(shell pwd)

# Create secret for scrape config - See https://github.com/prometheus-operator/prometheus-operator/blob/master/Documentation/additional-scrape-config.md
create_scrape_secret:
	microk8s kubectl create secret generic additional-scrape-configs --from-file=${BUILD_DIR}/exporters/prometheus-additional.yaml --dry-run=client -oyaml > ${BUILD_DIR}/exporters/additional-scrape-configs.yaml

# Convert prometheus rule from .yaml to .json - See https://github.com/prometheus-operator/kube-prometheus/blob/8d36d0d7071dcad1fb1d7ed966842967d9175360/docs/developing-prometheus-rules-and-grafana-dashboards.md#prometheus-rules
create_rule:
	docker run --rm -v ${BUILD_DIR}:${BUILD_DIR} --workdir ${BUILD_DIR} quay.io/coreos/jsonnet-ci sh -c "cat my-prometheus-rule.yaml | gojsontoyaml -yamltojson > my-prometheus-rule.json"

# Build /manifets/*.yaml files. Input: custom configs files, vendor, main.jsonnet
build:
	make create_scrape_secret
	make create_rule
	docker run --rm -v ${BUILD_DIR}:${BUILD_DIR} --workdir ${BUILD_DIR} quay.io/coreos/jsonnet-ci ./build.sh ./main.jsonnet

# Start Prometheus server listening on port 9090 (Using k8s port forward)
prometheus:
	microk8s kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
	
# Start Grafana server listening on port 3000 (Using k8s port forward)
grafana:
	microk8s kubectl --namespace monitoring port-forward svc/grafana 3000

# Start AlertManager server listening on port 9093 (Using k8s port forward)
alertmanager:
	microk8s kubectl --namespace monitoring port-forward svc/alertmanager-main 9093

# Deploy kube-prometheus deployment stack
up:
	microk8s kubectl apply -f ${BUILD_DIR}/manifests/setup
	microk8s kubectl apply -f ${BUILD_DIR}/exporters/additional-scrape-configs.yaml -n monitoring
	microk8s kubectl apply -f ${BUILD_DIR}/manifests
	microk8s kubectl apply -f ${BUILD_DIR}/exporters/nats_exporter.yaml
	microk8s kubectl apply -f ${BUILD_DIR}/exporters/redis_exporter.yaml
	microk8s kubectl apply -f ${BUILD_DIR}/ingress.yaml

# Delete kube-prometheus deployment stack
down:
	microk8s kubectl delete -f ${BUILD_DIR}/exporters/nats_exporter.yaml
	microk8s kubectl delete -f ${BUILD_DIR}/exporters/redis_exporter.yaml
	microk8s kubectl delete --ignore-not-found=true -f ${BUILD_DIR}/manifests/ -f ${BUILD_DIR}/manifests/setup
	microk8s kubectl delete -f ${BUILD_DIR}/ingress.yaml