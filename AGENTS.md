# K3s Cluster Administration Guide

## Overview

GitOps-driven k3s cluster managed by FluxCD. This repository is the single source of truth.

## Current State

- **Branch**: `main` (synced with origin)
- **Pending**: choretwo OAuth2 client changes (uncommitted)
- **Managed Apps**: 20 fully managed, 20 partially managed

## Critical Protection Policies

1. **PVC Protection**: All PVCs must have `kubernetes.io/pvc-protection` finalizer
2. **Domain Schema**: All ingresses use `<app-name>.stillon.top` with Let's Encrypt TLS
3. **Namespace Management**: Namespaces created manually (`kubectl create ns`), not Flux-managed
4. **SealedSecrets**: Never commit plaintext secrets

## Repository Structure

| Directory | Purpose |
|-----------|---------|
| `apps/` | Flux Kustomizations (deployment triggers) |
| `kustomize/` | Kubernetes manifests (Kustomize overlays) |
| `flux-system/` | Bootstrap configuration |
| `system/` | System-level configs (DaemonSets, etc.) |
| `docs/` | Comprehensive documentation |
| `scripts/` | Legacy utilities |

## Agent Guidelines

### Always
1. **GitOps-first**: Make repo changes first, let Flux reconcile
2. **Verify Flux status**: Check reconciliation before/after changes
3. **Protect PVCs**: Never delete namespaces/PVCs without validation
4. **Seal secrets**: Use `kubeseal` for all sensitive data
5. **Document changes**: Update docs for Copilot memory persistence

### Operations Workflow

**Adding an app:**
```
1. kubectl create namespace <name> (manual)
2. Create manifests in kustomize/<app>/
3. Add PVC finalizers
4. Create Flux Kustomization in apps/<app>.yaml
5. Commit and push
```

**Updating an app:**
```
1. Modify manifests in kustomize/
2. Commit with meaningful message
3. Wait for Flux reconciliation
4. Verify with flux get kustomizations
```

**Handling secrets:**
```
1. Create Secret locally (never commit)
2. Seal: kubeseal --format yaml < secret.yaml > sealed.yaml
3. Commit only sealed version
4. Delete plaintext secret
```

### Verification Commands

```bash
# Flux status
flux get kustomizations -A

# Check specific app
flux get kustomization <app-name> -n flux-system

# Pod status
kubectl get pods -n <namespace>

# View events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

## Pending Actions

- Commit choretwo changes (apps/, kustomize/choretwo/)
- Monitor Traefik → nginx-ingress migration
- Track PostgreSQL nightly image compatibility

## Documentation

- Main README: Root level
- Workflow guide: `docs/workflow.md`
- Cluster context: `.github/cluster-context.md`
- Adding apps: `docs/adding-applications.md`

</content>