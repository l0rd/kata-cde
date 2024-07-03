# Secured and Privileged Kube CDEs with Kata Containers

This repository contains the necessary files to run **secured** privileged Cloud Development Environments on Kubernetes using Kata Containers.

<img width="1719" alt="image" src="https://github.com/l0rd/kata-cde/assets/606959/2211ea81-c9a8-4e59-a993-cfffec8bb5cf">


## Prerequisites

- An OpenShift cluster v4.16 or later with bare metal worker nodes (c.f. [install-config.yaml](ocp-install/install-config.yaml)) and a [regular user](ocp-install/add-regular-user.sh)
- OpenShift Sandboxed Containers Operator installed and a `KataConfig` CR created
(c.f. [install-ocp-sandbox-operator.sh](ocp-sandbox-operator/install-ocp-sandbox-operator.sh))
- Eclipse Che Operator installed and `CheCluster` CR created in `eclipse-che` namespace
(c.f. [install-eclipse-che-operator.sh](eclipse-che-operator/install-eclipse-che-operator.sh))
- [Kyverno installed](https://kyverno.io/docs/installation/methods/):
  - `helm repo add kyverno https://kyverno.github.io/kyverno/ && helm repo update`
  - `helm install kyverno kyverno/kyverno -n kyverno --create-namespace --set replicaCount=1`

## Procedure

1. Login to Che using a regular user <-- This creates the `<user>-che` namespace
2. Apply a [Kyverno policy](policies/run-priv-pod-using-kata.yaml)  <-- This allow running privileged Pods using Kata runtime in `<user>-che` namespace
3. Create the privileged SA [privsa.yaml](policies/privsa.yaml) and rolebinding [privsa-rb.yaml](policies/privsa-rb.yaml) in `<user>-che` namespace.  <-- This is the privileged SA that Che will use to start the CDEs
4. Patch the CheCluster CR with [patch-checluster.sh](eclipse-che-operator/patch-checluster.sh) to use the privileged SA `privsa` for CDEs Pods
5. Start a workspace using a Devfile with a `pod-overrides` spec as in as the one in `.devfile.yaml`

## Verification steps

```bash
POD="workspace25b1397e11e2478f-c587f877f-swbrf"
kgp -n mario-che $POD -o json | jq '.spec.runtimeClassName'               # <-- should be `kata`
kgp -n mario-che $POD -o json | jq '.spec.serviceAccount'                 # <-- should be `privsa`
kgp -n mario-che $POD -o json | jq '.spec.containers[].securityContext'   # <-- should be privileged etc...
```

## Security Consideration

Trying to run a privileged Pod without kata runtime should fail (last examples in [ocp-sandbox-operator/test.sh])
