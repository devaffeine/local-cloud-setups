#!/bin/bash

### K3D cluster
CLUSTER_NAME=alldbs-test
k3d cluster create ${CLUSTER_NAME} \
    -v $(pwd)/vol:/var/lib/rancher/k3s/storage@all \
    -a 10 -s 1 \
    --registry-create ${CLUSTER_NAME}-registry.local:0.0.0.0:5000

###################### Tools ###########################

### Kubernetes Dashboard
# Docs: https://github.com/kubernetes/dashboard/
GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml
kubectl apply -f cfg/admin.sec.yml

### Prometheus Monitoring
# Docs: https://github.com/prometheus-community/helm-charts
helm install community-prometheus prometheus-community/prometheus

### Splunk
# Docs: https://operatorhub.io/operator/splunk
curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.24.0/install.sh | bash -s v0.24.0
kubectl create -f cfg/splunk/s1.splunk.yml

###################### DBs ###########################

### MySQL
# Docs: https://dev.mysql.com/doc/mysql-operator/en/
# Helm repo:
#    helm repo add mysql-operator https://mysql.github.io/mysql-operator/
#    helm repo update
MYSQL_CLUSTER_NAME=usersdb-cluster
helm install official-mysql-operator mysql-operator/mysql-operator --namespace mysql-operator --create-namespace
helm install ${MYSQL_CLUSTER_NAME} mysql-operator/mysql-innodbcluster \
    --set credentials.root.user='root' \
    --set credentials.root.password='asd1234' \
    --set credentials.root.host='%' \
    --set serverInstances=5 \
    --set routerInstances=3 \
    --set tls.useSelfSigned=true

### Redis
# Docs: https://github.com/spotahome/redis-operator
# Helm Repo: 
#    helm repo add redis-operator https://spotahome.github.io/redis-operator
#    helm repo update
helm install spotahome-redis-operator redis-operator/redis-operator
REDIS_OPERATOR_VERSION=v1.2.4
kubectl create -f https://raw.githubusercontent.com/spotahome/redis-operator/${REDIS_OPERATOR_VERSION}/example/redisfailover/basic.yaml

### Cassandra
# Docs: https://docs.k8ssandra.io/components/k8ssandra-operator/
# Docs: https://github.com/k8ssandra/k8ssandra-operator
# Helm Repo:
#     helm repo add k8ssandra https://helm.k8ssandra.io/stable
#     helm repo update
helm install k8ssandra-operator k8ssandra/k8ssandra-operator -n k8ssandra-operator --create-namespace
kubectl create -f cfg/cassandra/demo.cass.yml

### Neo4j
# Docs: https://neo4j.com/docs/operations-manual/current/kubernetes/
# Helm Repo:
#    helm repo add neo4j https://helm.neo4j.com/neo4j
#    helm repo update
helm install my-neo4j-release neo4j/neo4j -f values.yaml

### Couchbase
# Docs: https://docs.couchbase.com/operator/current/helm-setup-guide.html
# Helm Repo:
#    helm repo add couchbase https://couchbase-partners.github.io/helm-charts/
#    helm repo update
helm install couchbase_clust --set cluster.name=couchbase_clust couchbase/couchbase-operator

### Mongodb
# Docs: https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/docs/install-upgrade.md
# Docs: https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/docs/deploy-configure.md
# Helm Repo:
#    helm repo add mongodb https://mongodb.github.io/helm-charts
#    helm repo update
helm install community-operator mongodb/community-operator
kubectl apply -f cfg/mongodb/mongodb-comm.yml

### Manual Steps
# Dashboard:
#     Token: kubectl -n kubernetes-dashboard create token admin-user
#     URL:   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/service?namespace=default

# Exposing Services:
# Prometheus:      kubectl port-forward service/community-prometheus 8081:80
# Splunk:
#     kubectl port-forward splunk-s1-standalone-0 8000
#  get splunk password
#     kubectl get secret splunk-default-secret -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
# Cassandra:       kubectl exec -it demo-dc1-default-sts-0 -n k8ssandra-operator -c cassandra -- nodetool -u $CASS_USERNAME -pw $CASS_PASSWORD status