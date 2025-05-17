# K3s Cluster Documentation

This documentation serves as the single source of truth for the configuration and management of the k3s cluster.

## Table of Contents

- [Getting Started](#getting-started)
- [Cluster Overview](#cluster-overview)
- [Repository Structure](#repository-structure)
- [Fully Managed Applications](#fully-managed-applications)
- [Partially Managed Applications](#partially-managed-applications)
- [Critical Protection Policies](#critical-protection-policies)
- [Workflow Guidelines](#workflow-guidelines)
- [Command Reference](#command-reference)

## Getting Started

This repository follows a GitOps-first approach for managing the cluster:

- [Adding New Applications](adding-applications.md) - Follow this guide to add new applications
- [Using MCP Server Tools](mcp-tools.md) - Learn how to use Model Context Protocol server tools
- [Scripts Reference](scripts.md) - Utility scripts when needed

## Cluster Overview

This repository is the single source of truth for a k3s Kubernetes cluster:

- Using Flux for GitOps-driven continuous deployment
- Using SealedSecrets for handling sensitive data
- Following strict GitOps philosophy where the repository is the only source of truth
- Using MCP server tools for direct cluster interaction

## Repository Structure

- `apps/`: Contains Flux Kustomization resources for complete, fully Flux-managed applications
- `apps-incomplete/`: Contains Flux Kustomization resources that are not fully managed by Flux
- `flux-system/`: Contains Flux bootstrap configuration
- `kustomize/`: Contains Kubernetes manifests for complete, fully Flux-managed applications
- `kustomize-incomplete/`: Contains Kubernetes manifests that are not fully managed by Flux
- `scripts/`: Contains utility scripts for managing the repository and cluster
- `system/`: Contains system-level configurations
- `test/`: Contains configurations for testing and development purposes (not committed to the repository)
- `docs/`: Contains documentation for the cluster

## Fully Managed Applications

The following applications are fully Flux-managed:

| Application | Description |
|-------------|-------------|
| choremane-prod | Production instance of chore management application |
| choremane-staging | Staging instance of chore management application |
| docspell | Document management system |
| gotify | Notification service |
| linkding | Bookmark management system |
| memodawg | WhatsApp voice message transcriber |
| metube | Media downloader |
| picoshare | File sharing solution |

## Partially Managed Applications

The following applications are partially managed or incomplete:

| Application | Description |
|-------------|-------------|
| actualbudget | Budgeting application |
| dex | Identity service and OAuth provider |
| expenseowl | Expense tracking |
| grafana | Monitoring and visualization |
| grocy | Grocery and household management |
| lens-metrics | Kubernetes dashboard metrics |
| maybe | Financial planning tool |
| miniflux | RSS reader |
| mirotalk | Video conferencing |
| open-webui | Web UI for AI tools |
| pingpong-dev | Developer tool |
| taskserver | Task management server |
| uptime-kuma | Uptime monitoring |
| vanessa-choremane | Specialized version of choremane |
| vaultwarden | Password manager |
| xmrig | Mining utility |

## Critical Protection Policies

### PVC Protection

All PersistentVolumeClaims must include the `kubernetes.io/pvc-protection` finalizer to prevent accidental deletion:

```yaml
metadata:
  finalizers:
  - kubernetes.io/pvc-protection
```

### Ingress Domain Schema

All applications must follow the standardized domain schema:

- Format: `<application-name>.stillon.top`
- TLS configuration using `cert-manager.io/cluster-issuer: letsencrypt-prod`
- Consistent annotations for traefik

Example:
```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  rules:
  - host: app-name.stillon.top
    # ...
  tls:
  - hosts:
    - app-name.stillon.top
    secretName: app-name-tls
```

### Documentation Updates

Documentation should only be updated after:
- Changes have been committed and pushed to the repository
- Flux has successfully reconciled the changes
- Manual verification has confirmed proper operation

## Workflow Guidelines

### Adding a New Application

1. Create namespace: `kubectl create namespace <namespace>`
2. Deploy application
3. Export resources: `./scripts/export_namespace.sh <namespace>`
4. Decide on Flux management level and place in appropriate directories
5. **Ensure PVCs have protection finalizers added**
6. **Follow the standard domain schema for ingresses**

### Updating an Existing Application

1. Make changes to manifests in repository
2. Commit and push changes for Flux to apply
3. Wait for Flux reconciliation and verify changes

### Verifying Cluster State

Run `./scripts/verify_cluster.sh [namespace]`

### Handling Sensitive Data

1. Use SealedSecrets for encryption
2. Run `./scripts/seal_secrets.sh <namespace>` to seal sensitive data

## Command Reference

### Flux Commands

- Check Flux health: `flux check`
- List Kustomizations: `flux get kustomizations`
- Reconcile specific kustomization: `flux reconcile kustomization <name>`
- Get sources: `flux get sources git`
- Trace a resource: `flux trace kustomization <name>`

### Helm Commands for Flux-managed releases

- List Helm releases: `flux get helmreleases`
- Reconcile Helm release: `flux reconcile helmrelease <name> -n <namespace>`

### Kubernetes Management

- Get pods across all namespaces: `kubectl get pods --all-namespaces`
- Get all resources in a namespace: `kubectl get all -n <namespace>`
- View resource details: `kubectl describe <resource-type> <resource-name> -n <namespace>`
- Follow logs: `kubectl logs -f <pod-name> -n <namespace>`
- Port forward to service: `kubectl port-forward svc/<service-name> <local-port>:<service-port> -n <namespace>`

### SealedSecrets

- View a current secret: `kubectl get secret <secret-name> -n <namespace> -o yaml`
- Seal a secret: `kubeseal --format yaml < secret.yaml > sealed-secret.yaml`
- Re-seal all secrets in namespace: `./scripts/seal_secrets.sh <namespace>`

### Troubleshooting

- Check Flux logs: `kubectl logs -n flux-system deployment/source-controller`
- Check failed reconciliations: `flux get all --status-selector ready=false`
- Debug resource application: `kubectl get events -n <namespace>`