#!/bin/bash

### K3D cluster
CLUSTER_NAME=alldbs-test
k3d cluster create $CLUSTER_NAME \
    -v $(pwd)/vol:/var/lib/rancher/k3s/storage@all \
    -a 10 -s 1 \
    --registry-create $CLUSTER_NAME-registry.local:0.0.0.0:5000

###################### Tools ###########################

### Kubernetes Dashboard
# Docs: https://github.com/kubernetes/dashboard/
GITHUB_URL=https://github.com/kubernetes/dashboard/releases
VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/$VERSION_KUBE_DASHBOARD/aio/deploy/recommended.yaml
kubectl apply -f cfg/dashborad/admin.sec.yml

### Prometheus Monitoring
# Docs: https://github.com/prometheus-community/helm-charts
helm install community-prometheus prometheus-community/prometheus

### Splunk
# Docs: https://operatorhub.io/operator/splunk
curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.24.0/install.sh | bash -s v0.24.0
kubectl create -f https://operatorhub.io/install/splunk.yaml
kubectl create -f cfg/splunk/s1.splunk.yml

### Cert Manager
# Docs: https://cert-manager.io/
# Helm Repo:
#     helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true

###################### DBs ###########################

### MySQL
# Docs: https://dev.mysql.com/doc/mysql-operator/en/
# Helm Repo:
#    helm repo add mysql-operator https://mysql.github.io/mysql-operator/
#    helm repo update
MYSQL_CLUSTER_NAME=usersdb-cluster
helm install official-mysql-operator mysql-operator/mysql-operator --namespace mysql-operator --create-namespace
helm install $MYSQL_CLUSTER_NAME mysql-operator/mysql-innodbcluster \
    --set credentials.root.user='root' \
    --set credentials.root.password='asd1234' \
    --set credentials.root.host='%' \
    --set serverInstances=5 \
    --set routerInstances=3 \
    --set tls.useSelfSigned=true

### Redis Spotahome
# Docs: https://github.com/spotahome/redis-operator
# Helm Repo: 
#    helm repo add redis-operator https://spotahome.github.io/redis-operator
#    helm repo update
helm install spotahome-redis-operator redis-operator/redis-operator
kubectl create -f cfg/redis/redis.spotahome.yml

### Neo4j
# Docs: https://neo4j.com/docs/operations-manual/current/kubernetes/
# Helm Repo:
#    helm repo add neo4j https://helm.neo4j.com/neo4j
#    helm repo update
helm install my-neo4j-release neo4j/neo4j -f cfg/neo4j/values.yaml

### Couchbase
# Docs: https://docs.couchbase.com/operator/current/helm-setup-guide.html
# Helm Repo:
#    helm repo add couchbase https://couchbase-partners.github.io/helm-charts/
#    helm repo update
helm install couchbase-release --set cluster.name=couchbase-cluster couchbase/couchbase-operator

### Mongodb
# Docs: https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/docs/install-upgrade.md
# Docs: https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/docs/deploy-configure.md
# Helm Repo:
#    helm repo add mongodb https://mongodb.github.io/helm-charts
#    helm repo update
helm install community-operator mongodb/community-operator
kubectl apply -f cfg/mongodb/mongodb-comm.yml

### ElasticSearch
# Docs: https://www.elastic.co/downloads/elastic-cloud-kubernetes
kubectl create -f https://download.elastic.co/downloads/eck/2.6.1/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.6.1/operator.yaml
kubectl apply -f cfg/elasticsearch/quickstart.es.yml

### Kafka
# Docs: https://docs.confluent.io/operator/2.2/co-deploy-cfk.html#deploy-co-long
# Helm Repo:
#    helm repo add confluentinc https://packages.confluent.io/helm
#    helm repo update
helm install confluent-operator confluentinc/confluent-for-kubernetes --create-namespace --namespace confluent
kubectl apply -f cfg/kafka/kafka.confluent.yml

### Manual Steps
# Dashboard:
#     Token: kubectl -n kubernetes-dashboard create token admin-user
#     URL:   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/service?namespace=default

# Exposing Services:
# Prometeus:
#     kubectl port-forward service/community-prometheus 8081:80
# Splunk:
#     kubectl get secret splunk-default-secret -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
#     kubectl port-forward splunk-s1-standalone-0 8000
# Redis
#     kubectl port-forward svc/rfs-redisfailover 26379
#     kubectl run --rm -it myshell --image=redis -- redis-cli -h rfs-redisfailover.default.svc.cluster.local -p 26379
# Cassandra:
#      kubectl exec -it demo-dc1-default-sts-0 -n k8ssandra-operator -c cassandra -- nodetool -u $CASS_USERNAME -pw $CASS_PASSWORD status
# ElasticSearch:   
#     kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}'
#     kubectl port-forward service/quickstart-es-http 9200