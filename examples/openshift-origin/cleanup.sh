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

# Cleans up resources from the example, assumed to be run from Kubernetes repo root
echo
echo
export OPENSHIFT_EXAMPLE=$(pwd)/examples/openshift-origin
export OPENSHIFT_CONFIG=${OPENSHIFT_EXAMPLE}/config

echo "===> Removing OpenShift:"
kubectl delete secrets openshift-config
kubectl delete rc openshift
kubectl delete services openshift
echo

echo "===> Removing etcd:"
kubectl delete rc etcd
kubectl delete services etcd
echo

echo "===> Removing etcd-discovery:"
kubectl delete rc etcd-discovery
kubectl delete services etcd-discovery
echo

echo "===> Removing local files:"
rm -rf ${OPENSHIFT_CONFIG}
rm ${OPENSHIFT_EXAMPLE}/secret.json
echo

echo Done.