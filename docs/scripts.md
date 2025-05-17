# Repository Scripts Documentation

This document details the utility scripts available in the `scripts/` directory for managing the k3s cluster and repository. While our objective is to move toward a fully GitOps-managed approach, these scripts remain useful for specific scenarios.

> **Note**: Our preferred approach is GitOps-first, where manifests are created and modified directly in the repository before being applied by Flux. These scripts primarily serve as helpers for specific scenarios or transitional workflows.

## Key Repository Scripts

| Script | Description | When to Use | Usage |
|--------|-------------|-------------|-------|
| `verify_cluster.sh` | Verifies repository accurately represents cluster state | For auditing purposes | `./scripts/verify_cluster.sh [namespace]` |
| `seal_secrets.sh` | Seals sensitive ConfigMaps and Secrets | When adding sensitive data | `./scripts/seal_secrets.sh <namespace>` |
| `export_namespace.sh` | Exports resources from a namespace to the repository | For existing unmanaged workloads | `./scripts/export_namespace.sh <namespace>` |
| `process_namespace.sh` | Exports clean versions of resources and seals sensitive data | For cleaning up exported resources | `./scripts/process_namespace.sh <namespace>` |

## GitOps vs Direct Script Usage

### GitOps-First Approach (Recommended)

The GitOps-first approach follows these principles:

1. Manifests are created/edited directly in the repository
2. Changes are committed to the repository
3. Flux automatically applies changes to the cluster
4. Repository remains the single source of truth

This approach is cleaner, more reproducible, and allows for better versioning and change tracking.

## Script Usage When Needed

### Verifying Repository-Cluster Synchronization

```bash
./scripts/verify_cluster.sh [namespace]
```

Use this to check if the repository accurately reflects the cluster state. This is useful for auditing purposes or when troubleshooting inconsistencies.

### Sealing Sensitive Data

```bash
./scripts/seal_secrets.sh my-app
```

Use this when you need to seal sensitive data for a namespace. Prefer creating sealed secrets directly using kubeseal when possible.

### Migrating Existing Workloads to GitOps

For existing applications that were deployed directly to the cluster:

```bash
./scripts/export_namespace.sh my-app
```

This will export the resources to be managed by GitOps. Review the exported files carefully before committing them to ensure they are properly organized and cleaned.

## MCP Server Tools Alternative

Instead of using these scripts, consider using the MCP server tools that provide direct access to cluster information:

```bash
bb7_configuration_view        # View cluster configuration
bb7_pods_list                 # List pods across all namespaces
bb7_resources_get             # Get details about a specific resource
bb7_resources_list            # List resources of a specific kind
```

These tools provide a more integrated experience when working with Copilot to manage your cluster.

## Deprecated Scripts

The following scripts are deprecated and will be removed in the future as their functionality is integrated into Copilot-managed workflows or GitOps best practices:

- `update_documentation.sh`: This script was used to update documentation. This functionality is now handled by Copilot's auto-documentation features.