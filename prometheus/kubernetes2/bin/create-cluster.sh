#!/bin/bash

k3d cluster create prometheus-cluster -v $(pwd)/vol:/var/lib/rancher/k3s/storage@all -a 5 -s 3 --registry-create prometheus2-registry.local:0.0.0.0:5000

GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml

kubectl apply -f cfg/admin.sec.yml
kubectl -n kubernetes-dashboard create token admin-user

# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/service?namespace=default

# prometheus 2

helm install my-prometheus prometheus-community/prometheus
kubectl port-forward service/my-prometheus-server 8081:80