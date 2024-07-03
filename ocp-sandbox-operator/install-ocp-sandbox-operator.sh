#! /bin/bash

set -o errexit -o nounset -o pipefail

echo "Creating the sandboxed-containers-operator namespace"
kubectl create namespace openshift-sandboxed-containers-operator

echo "Creating the sandboxed-containers-operator subscription"
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
EOF

echo "Waiting for the sandboxed-containers-operator to be ready"
while [[ $(kubectl get csv -n openshift-sandboxed-containers-operator -o jsonpath='{.items[0].status.phase}') != "Succeeded" ]]; do
  echo -n "."
  sleep 5
done

echo "Creating the sandboxed-containers-operator CR"
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

start=$(date +%s)
echo "Waiting for the sandboxed-containers-operator to apply the CR (this usually take one hour)"
while [[ $(kubectl get kataconfig example-kataconfig -n openshift-sandboxed-containers-operator -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
  sleep 5
  time="$(($(gdate +%s) - $start))"
  printf '%s\r' "$(gdate -u -d "@$time" +%H:%M:%S)"
done

# # Waiting for next version of the operator, we currently need to add "io.kubernetes.cri-o.Devices"
# # to the allowed_annotations in the crio configuration...this could be automated with a MachineConfig
# # ...
#
# # Get worker nodes names
# oc get node -l node-role.kubernetes.io/worker -o json | jq '.items[].metadata.name'
#
# # For each worker node:
# NODE_NAME="ip-10-0-38-188.ec2.internal"
# oc debug node/$NODE_NAME
#
# chroot /host
# cat /etc/crio/crio.conf.d/50-kata
# cat << EOF >>  /etc/crio/crio.conf.d/50-kata
#   allowed_annotations = [
#     "io.kubernetes.cri-o.Devices",
#   ]
# EOF
# cat /etc/crio/crio.conf.d/50-kata
# systemctl restart crio
#
