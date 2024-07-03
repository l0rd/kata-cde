# Secured, Privileged CDEs with Kata Containers

This repository contains the necessary files to run **privileged 🚀** but **secured 🔒**
Cloud Development Environments on Kubernetes using
[Kata Containers](https://katacontainers.io).

<img width="1719" alt="image" src="https://github.com/l0rd/kata-cde/assets/606959/2211ea81-c9a8-4e59-a993-cfffec8bb5cf">

<img width="1719" alt="image" src="https://github.com/l0rd/kata-cde/assets/606959/2211ea81-c9a8-4e59-a993-cfffec8bb5cf">


## Prerequisites

- A cluster running OpenShift v4.15 or later on bare metal worker nodes with at least
a non-admin user (c.f. OpenShift sample [install-config.yaml](ocp-install/install-config.yaml)
and [a script to add a non-admin user](ocp-install/add-regular-user.sh)).
- [OpenShift Sandboxed Containers Operator](https://github.com/openshift/sandboxed-containers-operator) (c.f.
[install-ocp-sandbox-operator.sh](ocp-sandbox-operator/install-ocp-sandbox-operator.sh))
- [Eclipse Che Operator](https://github.com/eclipse-che/che-operator) (c.f.
[install-eclipse-che-operator.sh](eclipse-che-operator/install-eclipse-che-operator.sh))
- [Kyverno](https://kyverno.io/docs/installation/methods/)
```bash
helm repo add kyverno https://kyverno.github.io/kyverno/ && \
helm repo update && \
helm install kyverno kyverno/kyverno -n kyverno --create-namespace --set replicaCount=1
```

## Procedure

1. Login to Che using a regular user - *This creates the `<user>-che`
namespace*.
2. Apply a [Kyverno policy](policies/run-priv-pod-using-kata.yaml) - *This
allows running privileged Pods, using Kata runtime, in `<user>-che` namespace*
3. Create the privileged ServiceAccount, [privsa](policies/privsa.yaml), and
RoleBinding, [privsa-rb](policies/privsa-rb.yaml), in `<user>-che` namespace.
4. Patch the CheCluster CR with
[patch-checluster.sh](eclipse-che-operator/patch-checluster.sh) so that Che
uses the privileged SA, `privsa`, for CDEs Pods.
5. Start a workspace using a Devfile with a `pod-overrides` spec (c.f.
[.devfile.yaml](.devfile.yaml)).

## Verification steps

```bash
POD="<cde-podname>"
NS="<user>-che"
kgp -n $NS $POD -o json | jq '.spec.runtimeClassName' # should be `kata`
kgp -n $NS $POD -o json | jq '.spec.serviceAccount' # should be `privsa`
kgp -n $NS $POD -o json | jq '.spec.containers[].securityContext' # privileged etc...
```

## Security Consideration

Trying to run a privileged Pod without kata runtime should fail (last examples
in [ocp-sandbox-operator/test.sh]).
