# GitHub Copilot Context for K3s Cluster Configuration

## Cluster Overview

- This repository is the single source of truth for a k3s Kubernetes cluster
- The cluster uses Flux for GitOps-driven continuous deployment
- SealedSecrets is used for handling sensitive data
- The cluster follows a GitOps philosophy with this repository as the source of truth

## Auto-Documentation Update

When I mention "update cluster documentation" or make significant changes to the repository:

1. Update the "Fully Managed Applications" section:
   - Scan the `apps/` directory for current applications
   - Update the list with descriptions based on manifests

2. Update the "Partially Managed Applications" section:
   - Scan the `apps-incomplete/` directory for current applications
   - Update the list with descriptions based on manifests

3. Check and update the "Repository Structure" section:
   - Confirm directory structure is accurate
   - Add any new directories or important files

4. Review and update "Key Repository Scripts":
   - Check for new scripts in the `scripts/` directory
   - Update descriptions for any modified scripts

5. Update any changed workflows or best practices

This ensures that Copilot's understanding of the cluster remains current and accurate as the repository evolves.

## Repository Structure

- `apps/`: Contains Flux Kustomization resources for complete, fully Flux-managed applications
- `apps-incomplete/`: Contains Flux Kustomization resources that are not fully managed by Flux
- `flux-system/`: Contains Flux bootstrap configuration
- `kustomize/`: Contains Kubernetes manifests for complete, fully Flux-managed applications
- `kustomize-incomplete/`: Contains Kubernetes manifests that are not fully managed by Flux
- `scripts/`: Contains utility scripts for managing the repository and cluster
- `system/`: Contains system-level configurations
- `test/`: Contains configurations for testing and development purposes (not committed to the repository)

## Fully Managed Applications

The following applications are fully Flux-managed:

- choremane (prod and staging): Chore management application
- docspell: Document management system
- gotify: Notification service
- linkding: Bookmark management system
- memodawg: whatsapp-voicemessage transcriber
- metube: Media downloader
- picoshare: File sharing solution
- rclone: File synchronization and backup

## Partially Managed Applications

The following applications are partially managed or incomplete:

- actualbudget: Budgeting application
- dex: Identity service and OAuth provider
- expenseowl: Expense tracking
- grafana: Monitoring and visualization
- grocy: Grocery and household management
- lens-metrics: Kubernetes dashboard metrics
- maybe: Financial planning tool
- miniflux: RSS reader
- mirotalk: Video conferencing
- open-webui: Web UI for AI tools
- pingpong-dev: Developer tool
- taskserver: Task management server
- uptime-kuma: Uptime monitoring
- vanessa-choremane: Specialized version of choremane
- vaultwarden: Password manager
- xmrig: Mining utility

## Cluster Management Workflow

1. Make changes to this repository first, then let Flux apply them to the cluster
2. Use SealedSecrets for all sensitive data (passwords, tokens, etc.)
3. Use MCP tools to verify Flux reconciliation and cluster state
4. Create namespaces manually before adding them to Flux management
5. Keep documentation updated via the Copilot-driven auto-documentation process (triggered by significant changes or by asking Copilot to "update cluster documentation").
6. Follow the GitOps-first approach described in [docs/workflow.md](../docs/workflow.md)

## Critical Protection Policies

1. **PVC Protection**: All PersistentVolumeClaims must include `kubernetes.io/pvc-protection` finalizer to prevent accidental deletion

   ```yaml
   metadata:
     finalizers:
     - kubernetes.io/pvc-protection
   ```

2. **Namespace Management**: Namespaces should be created manually, not managed by Flux
   - Create namespaces with `kubectl create namespace` or `kubectl apply`
   - Do not include namespace.yaml in kustomization.yaml resources
   - This prevents accidental namespace deletion during Flux reconciliation

3. **Ingress Domain Schema**: All applications must follow the standardized domain schema:
   - Format: `<application-name>.stillon.top`
   - TLS configuration using `cert-manager.io/cluster-issuer: letsencrypt-prod`
   - Consistent annotations for traefik

4. **Documentation Updates**: Documentation is updated via a Copilot-driven process.
   - After significant repository changes, or when explicitly requested, Copilot will propose updates to relevant documentation files (e.g., `docs/README.md`, this file).
   - Review these proposed changes.
   - Commit and push the updated documentation.
   This ensures documentation stays synchronized with the cluster configuration.

## Key Repository Scripts

- `export_namespace.sh`: Exports resources from a namespace to the repository
- `process_namespace.sh`: Exports clean versions of resources and seals sensitive data
- `master_sync.sh`: Comprehensive workflow for syncing repository with the cluster
- `verify_cluster.sh`: Checks if repository correctly represents cluster state
- `seal_secrets.sh`: Seals sensitive ConfigMaps and Secrets using SealedSecrets

## Common Kubernetes Operations

When suggesting operations for this repository, consider these common tasks:

1. Adding a new application to the cluster (GitOps-first approach):
   - Create namespace manually: `kubectl create namespace <namespace>`
   - Create manifests directly in the repository under `kustomize/<namespace>/`
   - Create Flux Kustomization resource in `apps/<namespace>.yaml`
   - **Always create namespaces manually, not through Flux** (to protect PVCs)
      - **Ensure PVCs have protection finalizers added**
   - **Follow the standard domain schema for ingresses**
   - Commit and push changes for Flux to apply

2. Updating an existing application:
   - Make changes to manifests in repository
   - Commit and push changes for Flux to apply
   - **Wait for Flux reconciliation and verify changes**

3. Verifying deployment with MCP tools:
   - Use `bb7_pods_list_in_namespace namespace=<namespace>`
   - Use `bb7_reconcile_flux_kustomization name=<name> namespace=flux-system`
   - Check application health using `bb7_resources_get` calls

4. Handling sensitive data:
   - Create secrets locally (never commit)
   - Use kubeseal to encrypt: `kubeseal --format yaml < secret.yaml > sealed-secret.yaml`
   - Delete unencrypted secrets
   - Commit only sealed secrets

## Command Reference

When providing commands for this cluster, use these as a reference:

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

When suggesting solutions, always prefer GitOps approaches (changing repository files) over direct kubectl commands.

## MCP Server Tools for Kubernetes

When analyzing or modifying the cluster directly, these Model Context Protocol (MCP) server tools are available:

### Cluster Information

- View cluster configuration: Use `bb7_configuration_view`
- List all namespaces: Use `bb7_namespaces_list`
- List all events: Use `bb7_events_list`

### Pod Management

- List all pods: Use `bb7_pods_list`
- List pods in namespace: Use `bb7_pods_list_in_namespace`
- Get pod details: Use `bb7_pods_get`
- Execute command in pod: Use `bb7_pods_exec`
- View pod logs: Use `bb7_pods_log`
- Delete pod: Use `bb7_pods_delete`
- Run new pod: Use `bb7_pods_run`

### Resource Management

- List resources by kind: Use `bb7_resources_list`
- Get specific resource: Use `bb7_resources_get`
- Create/update resource: Use `bb7_resources_create_or_update`
- Delete resource: Use `bb7_resources_delete`

### Helm Management

- List Helm releases: Use `bb7_helm_list`
- Install Helm chart: Use `bb7_helm_install`
- Uninstall Helm release: Use `bb7_helm_uninstall`

### Repository File Operations

- List allowed directories: Use `bb7_list_allowed_directories`
- List directory contents: Use `bb7_list_directory`
- Get directory tree: Use `bb7_directory_tree`
- Search for files: Use `bb7_search_files`
- Read file contents: Use `bb7_read_file`
- Read multiple files: Use `bb7_read_multiple_files`
- Create directory: Use `bb7_create_directory`
- Write file: Use `bb7_write_file`
- Edit file: Use `bb7_edit_file`
- Move file: Use `bb7_move_file`
- Get file info: Use `bb7_get_file_info`

### Git Operations

- View git status: Use `bb7_git_status`
- Add files: Use `bb7_git_add`
- Commit changes: Use `bb7_git_commit`
- See differences: Use `bb7_git_diff`
- View staged changes: Use `bb7_git_diff_staged`
- View unstaged changes: Use `bb7_git_diff_unstaged`

These tools enable direct interaction with both the Kubernetes cluster and the repository files, making it possible to analyze the cluster state, compare it with the repository, and make informed suggestions about changes or improvements.

## Context Awareness

- Automatically analyze the repository structure when providing assistance
- Consider the GitOps workflow when suggesting changes
- Recognize the difference between fully managed and partially managed applications
- Understand that repository is the source of truth, not the live cluster
