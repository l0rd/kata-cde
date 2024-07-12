#! /bin/bash

set -o errexit -o nounset -o pipefail

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged-use-runc
  namespace: ${DEVELOPER_NAMESPACE}
  annotations:
    io.kubernetes.cri-o.Devices: "/dev/fuse"
spec:
  # runtimeClassName: kata
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

echo "Try running a container in the 'privileged-use-runc' pod now..."
k exec -ti privileged-use-runc -n ${DEVELOPER_NAMESPACE} -- podman run -ti --rm hello-world || true

echo "Try to run dnf install in the 'privileged-use-runc' pod now..."
k exec -ti privileged-use-runc -n ${DEVELOPER_NAMESPACE} -- dnf install -y git || true

echo "Deleting the 'privileged-use-runc' pod now..."
k delete pod privileged-use-runc -n ${DEVELOPER_NAMESPACE}
