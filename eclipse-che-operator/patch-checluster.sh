#! /bin/bash

set -o errexit -o nounset -o pipefail

echo "Patching CheCluster to disable container build capabilities"

PATCH='{"spec":{"devEnvironments":{"disableContainerBuildCapabilities": true}}}'
kubectl patch checluster eclipse-che \
    --type=merge -p \
    "${PATCH}" \
    -n eclipse-che

PATCH='{"spec":{"devEnvironments":{"serviceAccount":"privsa"}}}'
kubectl patch checluster eclipse-che \
    --type=merge -p \
    "${PATCH}" \
    -n eclipse-che

PATCH='{"spec":{"devEnvironments":{"security":{"containerSecurityContext":{'
PATCH+='"allowPrivilegeEscalation":true, "runAsUser": 0, "runAsNonRoot": false,"privileged": true, "capabilities": {"drop": ["KILL"], "add": ["CAP_SYS_ADMIN"]}'
PATCH+='}}}}}'

kubectl patch checluster eclipse-che \
    --type=merge -p \
    "${PATCH}" \
    -n eclipse-che
