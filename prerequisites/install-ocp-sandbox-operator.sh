#! /bin/bash

set -o errexit -o nounset -o pipefail

echo "Creating the sandboxed-containers-operator namespace"
kubectl create namespace openshift-sandboxed-containers-operator --dry-run=client -o yaml | kubectl apply -f -

# https://docs.openshift.com/container-platform/latest/operators/admin/olm-adding-operators-to-cluster.html

echo "Creating the sandboxed-containers-operator subscription"
kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-sandboxed-containers-operatorgroup
  namespace: openshift-sandboxed-containers-operator
spec:
  targetNamespaces:
  - openshift-sandboxed-containers-operator
EOF

kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: sandboxed-containers-operator
  namespace: openshift-sandboxed-containers-operator
spec:
  channel: stable
  installPlanApproval: Automatic
  name: sandboxed-containers-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: sandboxed-containers-operator.v1.6.0
EOF

echo -n "Waiting for the sandboxed-containers-operator csv resource to be created"
while kubectl get csv -n openshift-sandboxed-containers-operator -o json | jq -e '.items == []'  > /dev/null; do
  echo -n "."
  sleep 5
done
echo "done."

echo -n "Waiting for the sandboxed-containers-operator to be ready"
while [[ $(kubectl get csv -n openshift-sandboxed-containers-operator -o jsonpath='{.items[0].status.phase}') != "Succeeded" ]]; do
  echo -n "."
  sleep 5
done
echo "done."

echo "Creating the sandboxed-containers-operator CR"
sleep 30

kubectl apply -f - <<EOF
apiVersion: kataconfiguration.openshift.io/v1
kind: KataConfig
metadata:
  name: example-kataconfig
spec:
  checkNodeEligibility: false
  enablePeerPods: false
  kataConfigPoolSelector: null
  logLevel: info
EOF

sleep 30

start=$(date +%s)
echo "Waiting for the sandboxed-containers-operator to apply the CR (this usually take one hour)..."
while kubectl get kataconfig example-kataconfig -n openshift-sandboxed-containers-operator -o json | jq -e '.status.kataNodes | (.nodeCount != .readyNodeCount)' > /dev/null; do
  sleep 1
  time="$(($(gdate +%s) - $start))"
  printf '%s\r' "$(gdate -u -d "@$time" +%H:%M:%S)"
done
echo
echo "done."

# Waiting for next version of the operator, we currently need to add "io.kubernetes.cri-o.Devices"
# to the allowed_annotations in the cri-o configuration to enable fuse support.
# This is done by adding a MachineConfig to the worker nodes.
# `ignition` syntax reference: https://coreos.github.io/ignition/configuration-v3_4/
# echo "Creating MachineConfig to enable fuse when using kata"
# kubectl apply -f - <<EOF
# apiVersion: machineconfiguration.openshift.io/v1
# kind: MachineConfig
# metadata:
#   labels:
#     machineconfiguration.openshift.io/role: worker
#   name: 50-kata-worker
# spec:
#   config:
#     ignition:
#       version: 3.4.0
#     storage:
#       files:
#         - path: /etc/crio/crio.conf.d/50-kata
#           append:
#             source: data:,%20%20allowed_annotations%20%3D%20%5B%0A%20%20%20%20%22io.kubernetes.cri-o.Devices%22%2C%0A%20%20%5D
# EOF

# Or manually:
#
# # Get worker nodes names
# oc get node -l node-role.kubernetes.io/worker -o json | jq '.items[].metadata.name'

# # For each worker node:
# NODE_NAME="ip-10-0-38-188.ec2.internal"
# oc debug node/$NODE_NAME -- cat /host/etc/crio/crio.conf.d/50-kata

# chroot /host
# cat /etc/crio/crio.conf.d/50-kata
# cat << EOF >>  /etc/crio/crio.conf.d/50-kata
#   allowed_annotations = [
#     "io.kubernetes.cri-o.Devices",
#   ]
# EOF
# cat /etc/crio/crio.conf.d/50-kata
# systemctl restart crio
