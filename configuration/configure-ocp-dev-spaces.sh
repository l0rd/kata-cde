#! /bin/bash

set -o errexit -o nounset -o pipefail

CHECLUSTER_NAMESPACE=${CHECLUSTER_NAMESPACE:-openshift-devspaces}
CHECLUSTER_NAME=${CHECLUSTER_NAME:-devspaces}

echo "Patching CheCluster to:
- set privileged-sa as workspaces ServiceAccount (that enforces running workspaces in kata containers)
- disable container build capabilities (because we want to use custom capabilities)
- Add the Pod annotation to uses fuse devices in workspaces
- Set the runtimeClassName to kata
"

PATCH+='{"spec":{"devEnvironments":{'
PATCH+='"disableContainerBuildCapabilities": true,'
PATCH+='"runtimeClassName": "kata",'
PATCH+='"security":{"containerSecurityContext":{"privileged": true,"allowPrivilegeEscalation": true, "runAsNonRoot": false}},'
PATCH+='"serviceAccount":"privileged-sa",'
PATCH+='"workspacesPodAnnotations":{"io.kubernetes.cri-o.Devices":"/dev/fuse"}'
PATCH+='}}}'
kubectl patch checluster ${CHECLUSTER_NAME} \
    --type=merge -p \
    "${PATCH}" \
    -n ${CHECLUSTER_NAMESPACE}
