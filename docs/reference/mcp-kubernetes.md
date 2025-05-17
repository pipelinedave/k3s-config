# Kubernetes MCP Server Tools

This document provides a comprehensive reference for all Model Context Protocol (MCP) server tools available for interacting with the Kubernetes cluster. These tools enable direct access to cluster resources and data, allowing for a seamless integration between GitHub Copilot and the cluster.

## Available MCP Server Tools

### Cluster Information

| Tool | Description | Parameters | Example Usage |
|------|-------------|------------|--------------|
| `bb7_configuration_view` | Get current cluster configuration | None | `bb7_configuration_view` |
| `bb7_namespaces_list` | List all namespaces in the cluster | None | `bb7_namespaces_list` |
| `bb7_events_list` | List cluster events | `namespace` (optional) | `bb7_events_list namespace=my-app` |

### Pod Management

| Tool | Description | Parameters | Example Usage |
|------|-------------|------------|--------------|
| `bb7_pods_list` | List all pods across namespaces | None | `bb7_pods_list` |
| `bb7_pods_list_in_namespace` | List pods in specific namespace | `namespace` (required) | `bb7_pods_list_in_namespace namespace=my-app` |
| `bb7_pods_get` | Get details about a pod | `name`, `namespace` | `bb7_pods_get name=my-pod namespace=my-app` |
| `bb7_pods_exec` | Execute command in pod | `name`, `namespace`, `command` | `bb7_pods_exec name=my-pod namespace=my-app command=["ls", "-la"]` |
| `bb7_pods_log` | View pod logs | `name`, `namespace`, `container` (optional) | `bb7_pods_log name=my-pod namespace=my-app` |
| `bb7_pods_delete` | Delete a pod | `name`, `namespace` | `bb7_pods_delete name=my-pod namespace=my-app` |
| `bb7_pods_run` | Create a new pod | `name`, `namespace`, `image`, etc. | `bb7_pods_run name=test-pod namespace=default image=nginx` |

### Resource Management

| Tool | Description | Parameters | Example Usage |
|------|-------------|------------|--------------|
| `bb7_resources_list` | List resources by kind | `apiVersion`, `kind`, `namespace` (optional) | `bb7_resources_list apiVersion=apps/v1 kind=Deployment` |
| `bb7_resources_get` | Get specific resource | `apiVersion`, `kind`, `name`, `namespace` (optional) | `bb7_resources_get apiVersion=v1 kind=Service name=my-service namespace=my-app` |
| `bb7_resources_create_or_update` | Create or update a resource | `manifest` (YAML/JSON) | `bb7_resources_create_or_update manifest={...}` |
| `bb7_resources_delete` | Delete a resource | `apiVersion`, `kind`, `name`, `namespace` (optional) | `bb7_resources_delete apiVersion=v1 kind=ConfigMap name=my-config namespace=my-app` |

### Helm Management

| Tool | Description | Parameters | Example Usage |
|------|-------------|------------|--------------|
| `bb7_helm_list` | List all Helm releases | `namespace` (optional) | `bb7_helm_list namespace=my-app` |
| `bb7_helm_install` | Install a Helm chart | `name`, `chart`, `namespace`, `values` (optional) | `bb7_helm_install name=my-release chart=stable/nginx namespace=my-app` |
| `bb7_helm_uninstall` | Uninstall Helm release | `name`, `namespace` | `bb7_helm_uninstall name=my-release namespace=my-app` |

### Flux-Specific Tools

| Tool | Description | Parameters | Example Usage |
|------|-------------|------------|--------------|
| `bb7_get_flux_instance` | Get Flux installation details | None | `bb7_get_flux_instance` |
| `bb7_reconcile_flux_helmrelease` | Reconcile Flux HelmRelease | `name`, `namespace` | `bb7_reconcile_flux_helmrelease name=my-release namespace=flux-system` |
| `bb7_reconcile_flux_kustomization` | Reconcile Flux Kustomization | `name`, `namespace`, `with_source` (boolean, optional) | `bb7_reconcile_flux_kustomization name=my-app namespace=flux-system with_source=true` |
| `bb7_reconcile_flux_source` | Reconcile Flux source | `kind`, `name`, `namespace` | `bb7_reconcile_flux_source kind=GitRepository name=flux-system namespace=flux-system` |
| `bb7_suspend_flux_reconciliation` | Suspend Flux reconciliation | `kind`, `name`, `namespace` | `bb7_suspend_flux_reconciliation kind=Kustomization name=my-app namespace=flux-system` |
| `bb7_resume_flux_reconciliation` | Resume Flux reconciliation | `kind`, `name`, `namespace` | `bb7_resume_flux_reconciliation kind=Kustomization name=my-app namespace=flux-system` |
| `bb7_search_flux_docs` | Search Flux documentation | `query` | `bb7_search_flux_docs query="Kustomization spec"` |

## GitOps-First Usage Guidelines

While these MCP tools provide direct access to the cluster, they should be used in accordance with GitOps principles:

### DO:
- Use these tools for **observing** the current state of the cluster
- Use these tools to **verify** that Flux has correctly reconciled repository changes
- Use these tools to **troubleshoot** issues when applications aren't behaving as expected
- Use these tools to **explore** how resources are currently configured

### DON'T:
- Use these tools to make persistent changes to the cluster that aren't reflected in the repository
- Bypass the GitOps workflow for regular application deployments and updates

### Recommended Workflow

1. **Observe** current state using MCP tools
2. Make changes to the **repository files**
3. **Commit** and push changes
4. **Verify** that Flux successfully reconciled the changes using MCP tools

This maintains the GitOps principle of the repository being the single source of truth while leveraging the power of MCP tools for observation and verification.
