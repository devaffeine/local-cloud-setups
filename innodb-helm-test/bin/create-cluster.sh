#!/bin/bash

k3d cluster create innodb-helm-test -v $(pwd)/vol:/var/lib/rancher/k3s/storage@all -a 5 -s 3 --registry-create innodb-helm-registry.local:0.0.0.0:5000

GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml

kubectl apply -f cfg/admin.sec.yml
kubectl -n kubernetes-dashboard create token admin-user

# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/service?namespace=default

helm install my-mysql-operator mysql-operator/mysql-operator --namespace mysql-operator --create-namespace
helm install usersdb-cluster mysql-operator/mysql-innodbcluster \
    --set credentials.root.user='root' \
    --set credentials.root.password='asd1234' \
    --set credentials.root.host='%' \
    --set serverInstances=5 \
    --set routerInstances=3 \
    --set tls.useSelfSigned=true

# install splunk for centralize logging
