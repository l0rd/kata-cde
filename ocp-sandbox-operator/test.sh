#! /bin/bash

set -o errexit -o nounset -o pipefail

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: podman-kata-rootful-priv
  annotations:
    io.kubernetes.cri-o.Devices: "/dev/fuse"
spec:
  runtimeClassName: kata
  containers:
    - name: podman
      image: quay.io/podman/stable
      command: ["sh", "-c"]
      args:
        - sleep infinity
      volumeMounts:
        - name: container-storage
          mountPath: /var/lib/containers
      securityContext:
        privileged: true
  volumes:
    - name: container-storage
      emptyDir:
        medium: Memory
EOF

k exec -ti podman-kata-rootful-priv -- podman run -ti --rm hello-world

kubectl apply --as mario -n mario-che -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: podman-kata-rootful-priv-mod
  annotations:
    io.kubernetes.cri-o.Devices: "/dev/fuse"
spec:
  runtimeClassName: kata
  serviceAccount: privsa
  containers:
    - name: podman
      image: quay.io/podman/stable
      command: ["sh", "-c"]
      args:
        - sleep infinity
      securityContext:
        privileged: true
EOF

k exec -ti -n mario-che podman-kata-rootful-priv-mod -- podman run -ti --rm hello-world

kubectl apply --as mario -n mario-che -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: podman-kata-rootful-priv-no-kata
  annotations:
    io.kubernetes.cri-o.Devices: "/dev/fuse"
spec:
  serviceAccount: privsa
  containers:
    - name: podman
      image: quay.io/podman/stable
      command: ["sh", "-c"]
      args:
        - sleep infinity
      securityContext:
        privileged: true
EOF

k exec -ti -n mario-che podman-kata-rootful-priv-no-kata -- podman run -ti --rm hello-world
