# K3s Cluster Configuration

This repository serves as the single source of truth for the configuration of the k3s cluster. It contains all the manifests and resources needed to recreate the entire cluster state.

## Repository Structure

- `apps/`: Contains Flux Kustomization resources for complete, fully Flux-managed applications
- `apps-incomplete/`: Contains Flux Kustomization resources for applications that are not fully managed by Flux
- `flux-system/`: Contains Flux bootstrap configuration
- `kustomize/`: Contains Kubernetes manifests for complete, fully Flux-managed applications
- `kustomize-incomplete/`: Contains Kubernetes manifests for applications that are not fully managed by Flux
- `scripts/`: Contains utility scripts for managing the repository and interacting with the cluster
- `system/`: Contains system-level configurations
- `test/`: Contains configurations for testing and development purposes (not committed to the repository)

## Using this Repository

### Prerequisites

- kubectl
- Flux CLI (for bootstrapping)
- kubeseal (for handling sensitive data)

### Bootstrapping a New Cluster

To bootstrap a new cluster with this configuration:

1. Create a new k3s cluster
2. Bootstrap Flux:

```bash
flux bootstrap github \
  --owner=<your-github-username> \
  --repository=k3s-config \
  --branch=main \
  --path=./ \
  --personal
```

This will install Flux and configure it to sync with this repository.

### Exporting Resources from the Current Cluster

This repository includes scripts to export and manage resources from namespaces in the cluster:

#### Basic Export

```bash
./scripts/export_namespace.sh <namespace>
```

This will create a Flux Kustomization resource in the `apps/` directory and export Kubernetes resources to the `kustomize/<namespace>/` directory.

#### Clean Export and Secret Sealing

For a more secure approach that removes sensitive metadata and seals secrets:

```bash
./scripts/process_namespace.sh <namespace>
```

This script will:

1. Export clean versions of resources (deployments, services, etc.)
2. Identify and seal sensitive ConfigMaps and Secrets using SealedSecrets
3. Update kustomization.yaml to use these sealed resources

#### Processing All Namespaces

To process all namespaces in the repository:

```bash
./scripts/process_all.sh
```

This will run the clean export and secret sealing process for each namespace in the repository.

#### Comprehensive Repository Sync (Recommended)

For a complete workflow that handles all aspects of syncing your repository with the cluster:

```bash
./scripts/master_sync.sh [--all] [namespace1 namespace2 ...]
```

This comprehensive script will:

1. Verify which namespaces need updating
2. Export any missing namespaces
3. Clean up resources and remove sensitive metadata
4. Seal sensitive ConfigMaps and Secrets
5. Properly merge and apply all changes
6. Perform a final verification

When run without arguments, it provides an interactive menu to choose which namespaces to process.

### Managing Configurations

All configurations should be committed to this repository. Flux will automatically apply changes to the cluster when they are pushed to the main branch.

### Verifying Repository State

To check if the repository correctly represents the cluster state:

```bash
./scripts/verify_cluster.sh [namespace]
```

This will:

1. Identify namespaces in the cluster that are missing from the repository
2. Check if all resource types in each namespace are represented
3. Compare repository resources with cluster resources for discrepancies

## Best Practices

1. **Always use the repository as the source of truth**:
   - Make changes to the repository first, then let Flux apply them to the cluster
   - Don't make manual `kubectl apply` changes that aren't reflected in the repository

2. **Keep sensitive data secure**:
   - Use SealedSecrets for all sensitive data (passwords, tokens, etc.)
   - Never commit unencrypted secrets to the repository

3. **Regularly verify and update**:
   - Run `./verify_cluster.sh` periodically to ensure repository and cluster are in sync
   - When adding new applications, use the export scripts to ensure complete coverage

4. **Document changes**:
   - Include meaningful commit messages that explain what changed and why
   - Update this README if new namespaces or major applications are added

## Managed Applications

The following applications are fully Flux-managed and maintained in the `apps/` and `kustomize/` directories:

- choremane (prod and staging)
- docspell
- firefly
- gotify
- memodawg
- metube
- miniflux
- picoshare

The following applications are partially managed or incomplete and are stored in the `apps-incomplete/` and `kustomize-incomplete/` directories:

- actualbudget
- dex
- expenseowl
- grafana
- grocy
- lens-metrics
- maybe
- mirotalk
- open-webui
- pingpong-dev
- rclone
- supersecretmessage
- taskserver
- uptime-kuma
- vanessa-choremane
- vaultwarden
- xmrig

## Adding New Applications

1. Create a new namespace for your application: `kubectl create namespace <namespace>`
2. Deploy your application to the namespace
3. Export the resources using the export script: `./scripts/export_namespace.sh <namespace>`
4. Decide if the application is fully Flux-managed or partially managed:
   - Fully managed: Keep in `apps/` and `kustomize/` directories
   - Partially managed: Move to `apps-incomplete/` and `kustomize-incomplete/` directories
5. Commit and push the changes to the repository

## Repository Workflow Philosophy

This repository follows a GitOps philosophy where:

1. Complete, fully Flux-managed applications are maintained in `apps/` and `kustomize/` 
   - These applications are fully declarative and can be recreated entirely from the manifests
   - Flux manages all aspects of these applications

2. Incomplete or partially managed applications are moved to `apps-incomplete/` and `kustomize-incomplete/`
   - These may be applications that require manual steps or have components not managed by Flux
   - They're included in the repository for documentation but may need manual intervention

3. Test resources and experiments belong in the `test/` directory
   - These resources are not committed to the repository
   - They're primarily for testing and development purposes

All utility scripts are located in the `scripts/` directory for better organization and maintainability.
