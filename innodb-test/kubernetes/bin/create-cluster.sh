#!/bin/bash

k3d cluster create innodb-test -v $(pwd)/vol:/var/lib/rancher/k3s/storage@all -a 5 -s 3 --registry-create innodb-registry.local:0.0.0.0:5000

kubectl apply -f https://raw.githubusercontent.com/mysql/mysql-operator/trunk/deploy/deploy-crds.yaml
kubectl apply -f https://raw.githubusercontent.com/mysql/mysql-operator/trunk/deploy/deploy-operator.yaml
kubectl get deployment mysql-operator --namespace mysql-operator

kubectl create secret generic usersdb-pwds \
        --from-literal=rootUser=root \
        --from-literal=rootHost=% \
        --from-literal=rootPassword="asd123"

kubectl apply -f cfg/usersdb.mysql.yml

GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml

kubectl apply -f cfg/admin.sec.yml
kubectl -n kubernetes-dashboard create token admin-user