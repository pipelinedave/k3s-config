# Global Copilot Instructions

## Todo Management
- Always check for the file `.github/todo/Todo.md` in this repository.
- Process the todo list based on the instructions in `.github/todo/CopilotTodo.md`.
- Maintain the structure of the todo list while allowing me to freely add new items anywhere.
- Help me prioritize and work on tasks from the todo list.


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
- memodawg: whatsapp-voicemessage transcriber
- metube: Media downloader
- picoshare: File sharing solution

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
- rclone: File synchronization
- taskserver: Task management server
- uptime-kuma: Uptime monitoring
- vanessa-choremane: Specialized version of choremane
- vaultwarden: Password manager
- xmrig: Mining utility

## Cluster Management Workflow
1. Make changes to this repository first, then let Flux apply them to the cluster
2. Use SealedSecrets for all sensitive data (passwords, tokens, etc.)
3. Run verification scripts periodically to ensure repository and cluster are in sync
4. Process namespaces using provided scripts when changes are needed

## Key Repository Scripts
- `export_namespace.sh`: Exports resources from a namespace to the repository
- `process_namespace.sh`: Exports clean versions of resources and seals sensitive data
- `master_sync.sh`: Comprehensive workflow for syncing repository with the cluster
- `verify_cluster.sh`: Checks if repository correctly represents cluster state
- `seal_secrets.sh`: Seals sensitive ConfigMaps and Secrets using SealedSecrets

## Common Kubernetes Operations
When suggesting operations for this repository, consider these common tasks:
1. Adding a new application to the cluster:
   - Create namespace: `kubectl create namespace <namespace>`
   - Deploy application
   - Export resources: `./scripts/export_namespace.sh <namespace>`
   - Decide on Flux management level and place in appropriate directories
2. Updating an existing application:
   - Make changes to manifests in repository
   - Commit and push changes for Flux to apply
3. Verifying cluster state:
   - Run `./scripts/verify_cluster.sh [namespace]`
4. Handling sensitive data:
   - Use SealedSecrets for encryption
   - Run `./scripts/seal_secrets.sh <namespace>` to seal sensitive data

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

## Context Awareness
- Automatically analyze the repository structure when providing assistance
- Consider the GitOps workflow when suggesting changes
- Recognize the difference between fully managed and partially managed applications
- Understand that repository is the source of truth, not the live cluster

