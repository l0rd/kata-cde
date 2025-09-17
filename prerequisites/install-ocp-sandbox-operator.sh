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
  logLevel: info
EOF

sleep 30

start=$(date +%s)
echo "Waiting for the sandboxed-containers-operator to apply the CR (this usually takes ~ 15 minutes)..."
while kubectl get kataconfig example-kataconfig -n openshift-sandboxed-containers-operator -o json | jq -e '.status.kataNodes | (.nodeCount != .readyNodeCount)' > /dev/null; do
  sleep 1
  time="$(($(gdate +%s) - $start))"
  printf '%s\r' "$(gdate -u -d "@$time" +%H:%M:%S)"
done
echo
echo "done."
