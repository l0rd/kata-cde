#! /bin/bash

set -o errexit -o nounset -o pipefail

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged-use-kata
  namespace: ${DEVELOPER_NAMESPACE}
  annotations:
    io.kubernetes.cri-o.Devices: "/dev/fuse"
spec:
  runtimeClassName: kata
  serviceAccount: privileged-sa
  containers:
    - name: podman
      image: quay.io/podman/stable
      command: ["sh", "-c"]
      args:
        - sleep infinity
      # volumeMounts:
      #   - name: container-storage
      #     mountPath: /var/lib/containers
      securityContext:
        privileged: true
  # volumes:
  #   - name: container-storage
  #     emptyDir:
  #       medium: Memory
EOF

sleep 5

echo "Try running a container in the 'privileged-use-kata' pod now..."
kubectl exec -ti privileged-use-kata -n ${DEVELOPER_NAMESPACE} -- podman run -ti --rm hello-world

echo "Try to run dnf install in the 'privileged-use-kata' pod now..."
kubectl exec -ti privileged-use-kata -n ${DEVELOPER_NAMESPACE} -- dnf install -y git

echo "Deleting the 'privileged-use-kata' pod now..."
kubectl delete pod privileged-use-kata -n ${DEVELOPER_NAMESPACE}
