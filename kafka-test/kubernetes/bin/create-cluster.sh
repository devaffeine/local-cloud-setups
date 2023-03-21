#!/bin/bash

k3d cluster create kafka-test -v $(pwd)/vol:/var/lib/rancher/k3s/storage@all -a 10 -s 1

### Install Dashboard
GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml
kubectl apply -f cfg/admin.sec.yml

### Install Kafka
#withou helm: kubectl apply -f 'https://strimzi.io/install/latest?namespace=default'
helm install my-release strimzi/strimzi-kafka-operator
kubectl apply -f cfg/playevents.strimzi.yml

### Install Prometheus Prometheus 
helm install my-prometheus prometheus-community/prometheus
#manual: kubectl port-forward service/my-prometheus-server 8081:80

### Dashboard
#manual: kubectl -n kubernetes-dashboard create token admin-user
#browser: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/service?namespace=default
