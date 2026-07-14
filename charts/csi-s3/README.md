# CSI S3 Helm Chart

Maintained wrapper around the upstream Yandex Cloud `csi-s3` chart. It deploys the `isityael/k8s-csi-s3` driver image and can create multiple StorageClasses without storing S3 credentials in chart values.

## Requirements

- Kubernetes 1.23 or newer
- Linux nodes with `/dev/fuse`
- Cluster-admin privileges for CSI RBAC, host mounts, and privileged containers
- A pre-existing Kubernetes Secret containing `accessKeyID`, `secretAccessKey`, `endpoint`, and optionally `region`

## Install

```bash
helm install csi-s3 oci://ghcr.io/isityael/charts/csi-s3 \
  --version 0.1.0 \
  --namespace csi-s3 \
  --create-namespace
```

## Configuration

The upstream chart is vendored and available under `upstream`. Its renderer is disabled by default because it lacks the resource and security controls applied by this maintained wrapper. Set `upstream.enabled: true` only to test the unmodified upstream renderer. Secret creation and the upstream single StorageClass are disabled by default. Set `upstream.secret.create: true` only when credentials are supplied securely at installation time.

## Values example

```yaml
upstream:
  secret:
    create: false
    name: csi-s3-secret

storageClasses:
  - name: s3-archive
    bucket: archive
    reclaimPolicy: Retain
    mounter: geesefs
    mountOptions: "--memory-limit 512 --dir-mode 0777 --file-mode 0666 --no-systemd"
```

## Ingress example

This chart deploys cluster storage infrastructure and exposes no HTTP service, so Kubernetes Ingress and Gateway API routes do not apply.
