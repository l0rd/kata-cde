# Secured and Privileged Kube CDEs with Kata Containers

This repository contains the necessary files to run **secured** privileged Cloud Development Environments on Kubernetes using Kata Containers.

## Prerequisites

- An OpenShift cluster with bare metal worker nodes (c.f. [install-config.yaml](openshift-install/install-config.yaml))
- OpenShift Sandboxed Containers Operator installed and `KataConfig` CR created
- Eclipse Che Operator installed and `CheCluster` CR created in `eclipse-che` namespace
- [Kyverno installed](https://kyverno.io/docs/installation/methods/):
  - `helm repo add kyverno https://kyverno.github.io/kyverno/ && helm repo update`
  - `helm install kyverno kyverno/kyverno -n kyverno --create-namespace --set replicaCount=1`

## Eclipse Che Configuration

Configure Che to:

- Use the privileged udi image `TODO` as default container image.
- Use a privileged SA for CDEs Pods?
- Use the following securityContext spec for CDEs Pod:

```yaml
TODO
```

## Kyverno Policy

Add policy to run pods a developer specific namespace using Kata containers runtime:

```bash
kubectl apply -f - <<EOF apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: run-pod-using-kata
spec:
  background: false
  rules:
  - name: "Run pods in specific namespace using Kata containers runtime"
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaces:
          - mario-che
    mutate:
      patchStrategicMerge:
        spec:
          +(runtimeClassName): kata
EOF
```

- Create the privileged SA `./policies/privsa.yaml` and rolebing `./policies/privsa-rb.yaml` in developers namespaces.
- Create Kyverno cluster policy `./policies/run-pod-using-kata.yaml` to developers namespaces.
