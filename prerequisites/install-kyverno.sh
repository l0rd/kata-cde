#! /bin/bash

set -o errexit -o nounset -o pipefail

# Install Kyverno using YAMLs https://kyverno.io/docs/installation/methods/#install-kyverno-using-yamls 
# In order to support the airgap clusters, we host the yaml from https://github.com/kyverno/kyverno/releases/download/v1.15.1/install.yaml in the repository
kubectl create -f kyverno-install.yaml
