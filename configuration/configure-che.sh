#! /bin/bash

set -o errexit -o nounset -o pipefail

CHECLUSTER_NAMESPACE=${CHECLUSTER_NAMESPACE:-eclipse-che}

echo "Patching CheCluster to disable container build capabilities"

PATCH+='{"spec":{"devEnvironments":{'
PATCH+='"disableContainerBuildCapabilities": true,'
PATCH+='"security":{"containerSecurityContext":{"privileged": true,"allowPrivilegeEscalation": true, "runAsNonRoot": false}},'
PATCH+='"serviceAccount":"privileged-sa",'
PATCH+='"workspacesPodAnnotations":{"io.kubernetes.cri-o.Devices":"/dev/fuse"}'
PATCH+='}}}'
kubectl patch checluster eclipse-che \
    --type=merge -p \
    "${PATCH}" \
    -n ${CHECLUSTER_NAMESPACE}
