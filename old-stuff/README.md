## Start a workspace

```bash
kubectl apply -f ./editor-contribution.yaml
kubectl apply --wait=true -f ./devworkspace.yaml
DEPLOYMENT=$(kubectl get dw dw -o jsonpath='{..devworkspaceId}')
export DEPLOYMENT
kubectl wait --for=condition=available --timeout=60s deployment/"${DEPLOYMENT}"
```

## Eclipse Che Configuration

Configure Che to:

- Use the privileged udi image `TODO` as default container image.

- Use a privileged SA for CDEs Pods

```yaml
spec:
  devEnvironments:
    serviceAccount: privsa
```

```bash
PATCH='{"spec":{"devEnvironments":{"serviceAccount":"privsa"}}}'
kubectl patch checluster eclipse-che \
  --type=merge -p \
  "${PATCH}" \
  -n eclipse-che

PATCH='{"spec":{"devEnvironments":{"disableContainerBuildCapabilities": true}}}'
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
```

containerSecurityContext:
capabilities:
add: - SYS_TIME - CHOWN
drop: - KILL

- Use the following securityContext spec for CDEs Pod:

```yaml
TODO
```

## Check the workspace pod

```bash
DEPLOYMENT=$(kubectl get dw dw -o jsonpath='{..devworkspaceId}')
k get deployment $DEPLOYMENT -o json | jq .spec.template.spec.runtimeClassName

k get deployment $DEPLOYMENT -o json | jq .spec.template.spec.serviceAccountName

k get deployment $DEPLOYMENT -o json | jq .spec.template.spec.securityContext

k get deployment $DEPLOYMENT -o json | jq '.spec.template.spec.containers[].securityContext'
```

## Kyverno Policy

Add policy to enforce `kata` runtime class for Pods in the developer namespace:

```bash
export NS="mario-che"

kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
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
          - "${NS}"
    mutate:
      patchStrategicMerge:
        spec:
          +(runtimeClassName): kata
EOF
```

Create a privilege service account that will be used to start Pods in the same
namespace...

```bash
export NS="mario-che"

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: privsa
  namespace: "${NS}"
EOF

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
    name: system:openshift:scc:privileged
    namespace: "${NS}"
roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: system:openshift:scc:privileged
subjects:
    - kind: ServiceAccount
      name: privsa
      namespace: "${NS}"
EOF

kubectl apply -f - <<EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: run-priv-pod-using-kata
spec:
  background: false
  rules:
  - name: "Run privilege pod using Kata containers runtime"
    match:
      all:
      - resources:
          kinds:
          - Pod
          namespaces:
          - "${NS}"
    preconditions:
     any:
      - key: '{{request.object.spec.containers[?securityContext.privileged] | length(@)}}'
        operator: Equals
        value: 1
      - key: '{{request.object.spec.containers[?securityContext.runAsRoot] | length(@)}}'
        operator: Equals
        value: 1
      - key: '{{length(request.object.spec.containers[?securityContext.runAsUser == "0"])}}'
        operator: Equals
        value: 0
    mutate:
      patchStrategicMerge:
        spec:
          +(runtimeClassName): kata
          +(serviceAccountName): privsa
EOF
```

Try to start a privileged Pod:

```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: buildah-priv
  namespace: "${NS}"
spec:
  serviceAccountName: privsa
  containers:
    - name: buildah
      image: quay.io/mloriedo/buildah:userns
      resources:
        limits:
          cpu: 1000m
          memory: 4G
EOF
```

```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: podman-priv
  annotations:
    io.kubernetes.cri-o.Devices: "/dev/fuse"
spec:
  serviceAccountName: privsa
  containers:
    - name: priv
      image: quay.io/podman/stable
      args:
        - sleep
        - "1000000"
      securityContext:
        privileged: true
EOF
```

- Create the privileged SA `./policies/privsa.yaml` and rolebing `./policies/privsa-rb.yaml` in developers namespaces.
- Create Kyverno cluster policy `./policies/run-pod-using-kata.yaml` to developers namespaces.

## Issues

- On the DW has to explicit set `controller.devfile.io/runtime-class: kata`
