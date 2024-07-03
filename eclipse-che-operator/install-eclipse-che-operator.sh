#! /bin/bash

set -o errexit -o nounset -o pipefail

echo "Creating the eclipse-che-operator subscription"
kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: eclipse-che
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: eclipse-che
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF

echo "Waiting for the eclipse-che operator to be ready"
while [[ $(kubectl get csv -n openshift-operators -o jsonpath='{.items[?(@.spec.displayName=="Eclipse Che")].status.phase}') != "Succeeded" ]]; do
  echo -n "."
  sleep 5
done

echo "Creating the eclipse-che namespace"
kubectl create namespace eclipse-che

echo "Creating the sandboxed-containers-operator CR"
kubectl apply -f - <<EOF
apiVersion: org.eclipse.che/v2
kind: CheCluster
metadata:
  name: eclipse-che
  namespace: eclipse-che
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

start=$(date +%s)
echo "Waiting for the eclipse-che operator to apply the CR (this usually takes 5 minutes)"
while [[ $(kubectl get checluster eclipse-che -n eclipse-che -o jsonpath='{.status.chePhase}') != "Active" ]]; do
  sleep 5
  time="$(($(gdate +%s) - $start))"
  printf '%s\r' "$(gdate -u -d "@$time" +%H:%M:%S)"
done
