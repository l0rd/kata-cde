# Running privileges Eclipse Che CDEs on Kubernetes using Kata Containers

This repository contains the necessary files to run **secured** privileged Cloud Development Environments on Kubernetes using Kata Containers.

## Prerequisites

- An OpenShift cluster with bare metal worker nodes.
- OpenShift Sandboxed Containers Operator installed.
- Eclipse Che Operator installed

## Eclipse Che Configuration

Configure Che to:

- Use the privileged udi image `TODO` as default container image.
- Spec the following securityContext at every workspace:

```yaml
TODO
```

## Kyverno Configuration

Apply Kyverno cluster policy `./policies/run-pod-using-kata.yaml` to developers namespaces.
