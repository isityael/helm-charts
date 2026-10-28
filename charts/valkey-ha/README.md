# Valkey HA

Maintained derivative of CloudPirates Valkey chart 0.25.13; see NOTICE and LICENSE.

## Requirements

Kubernetes, Helm, three replicas, and a writable persistent volume per replica.
Sentinel quorum is two. Independent nodes are needed for host-failure tolerance.

## Install

Consume `oci://git.m0sh1.cc/isityael/charts/valkey-ha` from an ArgoCD wrapper chart.

## Configuration

Sentinel persists its identity and voting state on its pod PVC. Peer discovery
publishes unready addresses; client Services select ready pods only. Readiness
requires replication to catch up to a sampled primary offset and a voting quorum.
Planned shutdown pauses writes and verifies replica offsets before promotion.
The proxy closes connections to demoted primaries and has no role-only fallback.

## Values example

```yaml
architecture: replication
replicaCount: 3
auth:
  enabled: true
  existingSecret: cache-auth
persistence:
  enabled: true
sentinel:
  enabled: true
  quorum: 2
  masterProxy:
    enabled: true
```

## Ingress

No HTTP ingress: use the internal `<release>-master` TCP Service on port 6379.
Do not expose unauthenticated Redis or Sentinel endpoints publicly.

## Upgrade notes

Retain `fullnameOverride` and dependency alias to reuse existing volumes.
The first upgrade persists Sentinel configuration from the current primary.
Replication remains asynchronous; abrupt crashes can lose unreplicated writes.
Test planned rollovers and abrupt primary failure before production promotion.

For a data-preserving migration, set `sentinel.bootstrapMaster` to a dedicated
Service for the old standalone primary. Wait for all replicas to synchronize,
route clients through the new proxy, then perform a synchronized Sentinel handoff.
Remove the bootstrap backend only after verifying the elected primary and data.

### Two data pods with a Sentinel witness

For the internal unauthenticated endpoint, set `replicaCount: 2`,
`sentinel.witness.enabled: true`, and `sentinel.allowUnreplicatedWrites: true`.
Set `min-replicas-to-write 0` in `config.extraConfig` to retain write availability
while the sole replica restarts. This temporarily leaves acknowledged writes on
one data pod; a second failure can lose those writes. The witness stores only
Sentinel state on a small persistent volume, never a third dataset.
The proxy requires two Sentinel votes for the selected backend and checks its
primary role. Authenticated/TLS witness deployments are rejected pending validation.
