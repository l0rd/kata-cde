#! /bin/bash

set -o errexit -o nounset -o pipefail

CHECLUSTER_NAMESPACE=${CHECLUSTER_NAMESPACE:-eclipse-che}
CHECLUSTER_NAME=${CHECLUSTER_NAME:-eclipse-che}

../configure-ocp-dev-spaces.sh