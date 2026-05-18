# CSI Driver NFS Helm Chart

Helm chart for the Kubernetes [CSI Driver NFS](https://github.com/kubernetes-csi/csi-driver-nfs), using the m0sh1 fork with configurable `fsGroupPolicy`.

## Requirements

- Kubernetes >= 1.21
- Linux nodes with NFS client support
- Cluster-admin privileges for CSI RBAC, CRDs, DaemonSet host mounts, and privileged CSI containers
- DHI registry credentials when using the default DHI sidecar images

## Install

```bash
helm repo add yaelmoshi https://yaelmoshi.github.io/helm-charts
helm repo update

helm install csi-driver-nfs yaelmoshi/csi-driver-nfs -n kube-system
```

## Configuration

The chart installs controller and node CSI workloads. Privileged containers, host networking, and hostPath mounts are expected for this storage driver.

## Values Example

```yaml
feature:
  enableFSGroupPolicy: true
  fsGroupPolicy: None

storageClass:
  create: true
  name: nfs
  reclaimPolicy: Delete
  volumeBindingMode: Immediate
  parameters:
    server: nfs.example.com
    share: /exports/kubernetes

volumeSnapshotClass:
  create: true
  name: nfs-snapshots
  deletionPolicy: Delete
```

## Ingress Example

This chart deploys cluster storage infrastructure and does not expose HTTP traffic. No Kubernetes Ingress or Gateway API route is applicable.
