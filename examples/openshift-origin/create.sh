#!/bin/bash

# Copyright 2014 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Creates resources from the example, assumed to be run from Kubernetes repo root
echo
echo "===> Initializing:"
export OPENSHIFT_EXAMPLE=$(pwd)/examples/openshift-origin
echo Set OPENSHIFT_EXAMPLE=${OPENSHIFT_EXAMPLE}
export OPENSHIFT_CONFIG=${OPENSHIFT_EXAMPLE}/config
echo Set OPENSHIFT_CONFIG=${OPENSHIFT_CONFIG}
mkdir ${OPENSHIFT_CONFIG}
echo Made dir ${OPENSHIFT_CONFIG}
echo

echo "===> Setting up etcd-discovery:"
kubectl create -f ${OPENSHIFT_EXAMPLE}/etcd-discovery-controller.yaml
kubectl create -f ${OPENSHIFT_EXAMPLE}/etcd-discovery-service.yaml
echo

echo "===> Setting up etcd:"
kubectl create -f ${OPENSHIFT_EXAMPLE}/etcd-controller.yaml
kubectl create -f ${OPENSHIFT_EXAMPLE}/etcd-service.yaml
echo

echo "===> Setting up openshift-origin:"
kubectl config view --output=yaml --flatten=true --minify=true > ${OPENSHIFT_CONFIG}/kubeconfig
kubectl create -f ${OPENSHIFT_EXAMPLE}/openshift-service.yaml
echo

export PUBLIC_OPENSHIFT_IP=""
echo "===> Waiting for public IP to be set for the OpenShift Service."
echo "Mistakes in service setup can cause this to loop infinitely if an"
echo "external IP is never set. Ensure that the replication controller"
echo "is set to use an external load balancer. This process may take" 
echo "a few minutes. Errors can be found in the log file found at:"
echo ${OPENSHIFT_EXAMPLE}/openshift-startup.log
while [ ${#PUBLIC_OPENSHIFT_IP} -lt 1 ]; do
	echo -n .
	sleep 1
	{
		export PUBLIC_OPENSHIFT_IP=$(kubectl get services openshift --template="{{ index .status.loadBalancer.ingress 0 \"ip\" }}")
	} 2> ${OPENSHIFT_EXAMPLE}/openshift-startup.log
	if [[ ! ${PUBLIC_OPENSHIFT_IP} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
		export PUBLIC_OPENSHIFT_IP=""
	fi
done
echo
echo "Public OpenShift IP set to: ${PUBLIC_OPENSHIFT_IP}"
echo

echo "===> Configuring OpenShift:"
docker run --privileged -v ${OPENSHIFT_CONFIG}:/config openshift/origin start master --write-config=/config --kubeconfig=/config/kubeconfig --master=https://localhost:8443 --public-master=https://${PUBLIC_OPENSHIFT_IP}:8443 --etcd=http://etcd:2379
sudo -E chown -R ${USER} ${OPENSHIFT_CONFIG}

docker run -it --privileged -e="KUBECONFIG=/config/admin.kubeconfig" -v ${OPENSHIFT_CONFIG}:/config openshift/origin cli secrets new openshift-config /config -o json &> ${OPENSHIFT_EXAMPLE}/secret.json
kubectl create -f ${OPENSHIFT_EXAMPLE}/secret.json
echo

echo "===> Running OpenShift Master:"
kubectl create -f ${OPENSHIFT_EXAMPLE}/openshift-controller.yaml
echo

echo Done.
