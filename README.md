# K3s Cluster Configuration

This repository serves as the single source of truth for the configuration of the k3s cluster following GitOps principles. All cluster management is done through changes to this repository, which Flux automatically reconciles with the cluster state.

## GitOps-First Approach

This repository follows a GitOps-first philosophy:

1. All changes begin in the repository, not the cluster
2. Flux continuously reconciles the cluster with the repository state
3. Direct cluster manipulation is avoided in favor of repository updates
4. Documentation is kept current to reflect the live state

## Repository Structure

- `apps/`: Contains Flux Kustomization resources for complete, fully Flux-managed applications
- `apps-incomplete/`: Contains Flux Kustomization resources for applications that are not fully managed by Flux
- `flux-system/`: Contains Flux bootstrap configuration
- `kustomize/`: Contains Kubernetes manifests for complete, fully Flux-managed applications
- `kustomize-incomplete/`: Contains Kubernetes manifests for applications that are not fully managed by Flux
- `scripts/`: Contains utility scripts (legacy support - prefer GitOps approach)
- `system/`: Contains system-level configurations
- `test/`: Contains configurations for testing purposes (not committed to the repository)
- `docs/`: Contains comprehensive documentation for the cluster

## Documentation

For detailed documentation on using this repository, see the [docs directory](docs/README.md):

- [GitOps Workflow Guidelines](docs/workflow.md)
- [Adding New Applications](docs/adding-applications.md)
- [MCP Server Tools](docs/mcp-tools.md)
- [Scripts Reference](docs/scripts.md)

## Quick Start

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

### Adding a New Application

Follow the GitOps-first workflow to add new applications:

1. Create the application directory and manifests:

```bash
mkdir -p kustomize/my-application
```

2. Create all necessary manifests following our standards:
   - Ensure PVCs have protection finalizers
   - Follow the standardized domain schema for ingress resources
   - Use SealedSecrets for sensitive data

3. Create a Flux kustomization in the apps directory:

```bash
cat > apps/my-application.yaml << EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-application
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./kustomize/my-application
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
EOF
```

4. Commit and push your changes - Flux will automatically deploy the application

### Handling Sensitive Data

For sensitive data, always use SealedSecrets:

1. Create a regular Kubernetes Secret
2. Seal it using kubeseal:

```bash
kubeseal --format yaml < my-secret.yaml > my-secret-sealed.yaml
```

3. Commit only the sealed version to the repository

### Using MCP Server Tools

MCP server tools provide an integrated way to interact with the cluster through Copilot. See the [MCP Tools Documentation](docs/mcp-tools.md) for details on available tools and usage examples.

### Legacy Scripts (For Reference)

This repository includes legacy scripts that were previously used for manual operations. While our preferred approach is GitOps-first, these scripts remain available for specific scenarios. See the [Scripts Documentation](docs/scripts.md) for details.
## Best Practices

### Critical Protection Policies

1. **PVC Protection**: All PersistentVolumeClaims must include the protection finalizer
   ```yaml
   metadata:
     finalizers:
     - kubernetes.io/pvc-protection
   ```

2. **Ingress Domain Schema**: All applications must follow the standardized domain schema
   - Format: `<application-name>.stillon.top`
   - TLS configuration using `cert-manager.io/cluster-issuer: letsencrypt-prod`
   - Consistent annotations for traefik

### GitOps Workflow

1. **Repository as Source of Truth**:
   - Make changes to the repository first, then let Flux apply them
   - Don't use `kubectl apply` directly for changes that should persist
   - When exploring or testing, use temporary namespaces

2. **Keep Sensitive Data Secure**:
   - Use SealedSecrets for all sensitive data (passwords, tokens, etc.)
   - Never commit unencrypted secrets to the repository
   - Store encryption key backups securely

3. **Documentation as Code**:
   - Keep documentation updated alongside code changes
   - Documentation is the key to Copilot's understanding of the cluster
   - Add contextual comments in critical files

## Monitoring & Verification

To monitor Flux reconciliation:

```bash
flux get kustomizations
```

To verify specific application deployment:

```bash
kubectl get all -n my-application
```

For application-specific verification, check the application at its designated domain:
https://my-application.stillon.top

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
