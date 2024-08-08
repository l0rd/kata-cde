#! /bin/bash

set -o errexit -o nounset -o pipefail

echo "Creating the devspaces operator subscription"
kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: devspaces
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: devspaces
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

echo -n "Waiting for the devspaces operator csv resource to be created"
while kubectl get csv -n openshift-operators -o json | jq -e '.items == []'  > /dev/null; do
  echo -n "."
  sleep 5
done
echo "done."

echo -n "Waiting for the devspaces operator to be ready"
while [[ $(kubectl get csv -n openshift-operators -o jsonpath='{.items[?(@.spec.displayName=="Red Hat OpenShift Dev Spaces")].status.phase}') != "Succeeded" ]]; do
  echo -n "."
  sleep 5
done
echo "done"

sleep 10

echo "Creating the openshift-devspaces namespace"
kubectl create namespace openshift-devspaces --dry-run=client -o yaml | kubectl apply -f -

sleep 30

echo "Creating the CheCluster CR"
kubectl apply -f - <<EOF
apiVersion: org.eclipse.che/v2
kind: CheCluster
metadata:
  name: devspaces
  namespace: openshift-devspaces
spec:
  components:
    cheServer: {}
    dashboard: {}
    devWorkspace: {}
    devfileRegistry:
        disableInternalRegistry: true
        externalDevfileRegistries:
        - url: https://registry.devfile.io
    imagePuller: {}
    pluginRegistry:
        disableInternalRegistry: true
  containerRegistry: {}
  devEnvironments:
    containerBuildConfiguration:
      openShiftSecurityContextConstraint: container-build
    defaultNamespace:
      autoProvision: true
      template: <username>-che
    maxNumberOfWorkspacesPerUser: -1
    secondsOfInactivityBeforeIdling: 1800
    secondsOfRunBeforeIdling: -1
    security: {}
    startTimeoutSeconds: 300
    storage:
      pvcStrategy: per-user
  gitServices: {}
  networking:
    auth:
      gateway:
        configLabels:
          app: che
          component: che-gateway-config
        kubeRbacProxy:
          logLevel: 0
        oAuthProxy:
          cookieExpireSeconds: 86400
        traefik:
          logLevel: INFO
EOF

sleep 30

start=$(date +%s)
echo "Waiting for the dev spaces operator to apply the CR (this usually takes 5 minutes)"
while [[ $(kubectl get checluster devspaces -n openshift-devspaces -o jsonpath='{.status.chePhase}') != "Active" ]]; do
  sleep 1
  time="$(($(gdate +%s) - $start))"
  printf '%s\r' "$(gdate -u -d "@$time" +%H:%M:%S)"
done
echo
echo "done"
