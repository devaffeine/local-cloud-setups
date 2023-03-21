#!/bin/bash

CLUSTER_NAME=alldbs-test
k3d cluster delete ${CLUSTER_NAME}
sudo rm -rf vol/*