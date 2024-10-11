# Secured, Privileged CDEs with Kata Containers

This repository contains the necessary files to run **privileged 🚀** but **secured 🔒**
Cloud Development Environments on OpenShift using
[Kata Containers](https://katacontainers.io).

<img width="1719" alt="image" src="https://github.com/l0rd/kata-cde/assets/606959/2211ea81-c9a8-4e59-a993-cfffec8bb5cf">

## Prerequisites

- A cluster running OpenShift v4.15 or later on bare metal worker nodes with at least
a non-admin user (c.f. OpenShift sample [install-config.yaml](prerequisites/install-config.yaml)
and [a script to add a non-admin user](prerequisites/add-regular-user.sh)).
- [OpenShift Sandboxed Containers Operator](https://github.com/openshift/sandboxed-containers-operator)
(c.f. [install-ocp-sandbox-operator.sh](prerequisites/install-ocp-sandbox-operator.sh))
- [OpenShift Dev Spaces Operator](https://github.com/redhat-developer/devspaces)
(c.f. [install-ocp-dev-spaces-operator.sh](prerequisites/install-ocp-dev-spaces-operator.sh))
- [Kyverno](https://kyverno.io/docs/installation/methods/)
(c.f. [install-kyverno.sh](prerequisites/install-kyverno.sh))

## Procedure

1. Create the developer namespace `<user>-devspaces` if it doesn't exist yet
2. Apply a [Kyverno policy](configuration/resources/privileged-sa-use-kata-policy.yaml) - *This
allows running privileged Pods, using Kata runtime, in `<user>-che` namespace*
3. Create the privileged ServiceAccount, [privileged-sa](configuration/resources/privileged-sa.yaml), and
RoleBinding, [privileged-rb](configuration/resources/privileged-rb.yaml), in `<user>-che` namespace.
4. Configure OpenShift Dev Spaces with
[configure-ocp-dev-spaces.sh](configuration/configure-ocp-dev-spaces.sh) so that Dev Spaces
uses the SA `privileged-sa` for CDEs Pods.
5. Start a workspace using a DevWorkspace that uses the following `spec.template.attributes`:
`controller.devfile.io/runtime-class: kata` and
`pod-overrides: {"metadata": {"annotations": {"io.kubernetes.cri-o.Devices": "/dev/fuse" }}}`
(c.f. [devworkspace.yaml](tests/devworkspace.yaml)).

These steps can be executed using the following commands after cloning this repository:

```bash
# Set the namespace name
export NS="<user>-devspaces"

# Create the namespace, the privileged service account, and the Kyverno policy
envsubst < configuration/resources/kustomization.yaml | sponge configuration/resources/kustomization.yaml
kubectl apply -k ./configuration/resources

# Configure OpenShift Dev Spaces
./configuration/configure-ocp-dev-spaces.sh

# Start a workspace that uses VS Code
kubectl apply -f ./tests/vscode.yaml -n $NS
kubectl apply -f ./tests/devworkspace.yaml -n $NS

# Get the IDE URL and open it in a browser
kubectl get dw/privileged-cde -n $NS -o json | jq .status.mainUrl
```

## Verification steps

```bash
POD="<cde-podname>"
NS="<user>-che"
kubectl get po -n $NS $POD -o json | jq '.spec.runtimeClassName' # should be `kata`
kubectl get po -n $NS $POD -o json | jq '.spec.serviceAccount' # should be `privsa`
kubectl get po -n $NS $POD -o json | jq '.spec.containers[].securityContext' # privileged etc...
```

## Security Consideration

Trying to run a privileged Pod with the default runtime fails
([run-privileged-pod-with-runc.sh](tests/run-privileged-pod-with-runc.sh)) but
running it with kata (i.e. inside a VM,
[run-privileged-pod-with-kata.sh](tests/run-privileged-pod-with-kata.sh)) works.

## TODO

- [x] Remove hard-coded namespace and user
- [x] Use a minimal set of capabilities to make dnf and podman run work
- [x] Use a simple DevWorkspace to start a workspace
- [ ] Avoid adding annotation and runtimeclass in the DevWorkspace/Devfile (issues
[1](https://issues.redhat.com/browse/CRW-6550) and [2](https://github.com/eclipse-che/che/issues/23032))
- [ ] Change the sample to use a modified version of UDI that works with root and podman run
