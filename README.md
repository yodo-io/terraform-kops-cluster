# Kops Cluster

## Design Goals

- Simple interface, encouraging reuse
- Sane defaults
- Private topology
- Cluster bootstrap

## Bootstrap Components

### Minimal

- Log collection into built-in ES cluster
- Metrics collection into built-in Prometheus
- Vault
- Kube Dashboard
- Namespaces & RBAC

### Optional

- Cluster autoscaler
