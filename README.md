# Running secured and privileged CDEs on Kubernetes using Kata Containers

This repository contains the necessary files to run **secured** privileged Cloud Development Environments on Kubernetes using Kata Containers.

## Prerequisites

- An OpenShift cluster with bare metal worker nodes.
- OpenShift Sandboxed Containers Operator installed.
- Eclipse Che Operator installed

## Eclipse Che Configuration

Configure Che to:

- Use the privileged udi image `TODO` as default container image.
- Use a privileged SA for CDEs Pods?
- Use the following securityContext spec for CDEs Pod:

```yaml
TODO
```

## Kyverno Configuration

Create the privileged SA `./policies/privsa.yaml` and rolebing `./policies/privsa-rb.yaml` in developers namespaces.
Create Kyverno cluster policy `./policies/run-pod-using-kata.yaml` to developers namespaces.
