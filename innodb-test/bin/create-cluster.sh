#!/bin/bash

k3d cluster create innodb-test -v $(pwd)/vol:/var/lib/rancher/k3s/storage@all -a 5 -s 3
./install-mysql-operator.sh
./create-userdb-cluster.sh