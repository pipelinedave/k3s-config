# K3s Cluster Configuration

This repository serves as the single source of truth for the configuration of the k3s cluster following GitOps principles. All cluster management is done through changes to this repository, which Flux automatically reconciles with the cluster state.

## GitOps-First Approach

This repository follows a GitOps-first philosophy:

1. All changes begin in the repository, not the cluster.
2. Flux continuously reconciles the cluster with the repository state.
3. Direct cluster manipulation is avoided in favor of repository updates.
4. Documentation is kept current to reflect the live state.

## Documentation

**The primary and most detailed documentation for this cluster is located in the [`docs/` directory](./docs/README.md).**

This includes:

- Comprehensive cluster overview and setup.
- Detailed repository structure.
- Lists of fully and partially managed applications.
- In-depth workflow guidelines and critical protection policies.
- Command references and troubleshooting guides.

Key documentation links:

- [**Main Documentation Hub**](./docs/README.md)
- [GitOps Workflow Guidelines](./docs/workflow.md)
- [Adding New Applications](./docs/adding-applications.md)
- [MCP Server Tools](./docs/mcp-tools.md)
- [Scripts Reference](./docs/scripts.md) (for legacy support and specific scenarios)

## Repository Structure

This repository is organized as follows:

- `apps/`: Flux Kustomizations for fully managed applications.
- `apps-incomplete/`: Flux Kustomizations for partially managed applications.
- `flux-system/`: Flux bootstrap configuration.
- `kustomize/`: Kubernetes manifests for fully managed applications.
- `kustomize-incomplete/`: Kubernetes manifests for partially managed applications.
- `scripts/`: Utility scripts (primarily for legacy support).
- `system/`: System-level configurations.
- `docs/`: Comprehensive cluster documentation (this is the place to go for details!).
- `test/`: Configurations for testing (not committed).

For a detailed explanation of the repository structure, please see the [main documentation](./docs/README.md#repository-structure).

## Quick Start

### Prerequisites

- `kubectl`
- Flux CLI (for bootstrapping)
- `kubeseal` (for handling sensitive data)

### Bootstrapping a New Cluster

To bootstrap a new cluster with this configuration:

1. Create a new k3s cluster.
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

### Adding a New Application (GitOps Workflow)

1. **Create Namespace Manually**: `kubectl create namespace <namespace>` (Namespaces are not managed by Flux to protect PVCs).
2. **Create Manifests**:
    - Place application manifests in `kustomize/<application-name>/`.
    - Ensure PVCs have protection finalizers:

      ```yaml
      metadata:
        finalizers:
          - kubernetes.io/pvc-protection
      ```

    - Follow the standard domain schema for Ingress resources (`<application-name>.stillon.top`, TLS with `letsencrypt-prod`).
3. **Handle Sensitive Data**:
    - Create regular Kubernetes Secrets locally (e.g., `my-secret.yaml`).
    - Seal them using `kubeseal`:

      ```bash
      kubeseal --format yaml < my-secret.yaml > kustomize/<application-name>/my-secret-sealed.yaml
      ```

    - Commit only the sealed version.
4. **Create Flux Kustomization**:
    - Add a YAML file in `apps/<application-name>.yaml`:

      ```yaml
      apiVersion: kustomize.toolkit.fluxcd.io/v1
      kind: Kustomization
      metadata:
        name: <application-name>
        namespace: flux-system
      spec:
        interval: 10m0s
        path: ./kustomize/<application-name>
        prune: true
        sourceRef:
          kind: GitRepository
          name: flux-system
        targetNamespace: <namespace> # Specify the target namespace for the application
      ```

5. **Commit and Push**: Flux will automatically deploy the application.

For more detailed steps, see [Adding New Applications](./docs/adding-applications.md).

### Using MCP Server Tools

MCP server tools provide an integrated way to interact with the cluster through Copilot. See the [MCP Tools Documentation](./docs/mcp-tools.md) for details.

## Best Practices

### Critical Protection Policies

Adherence to these policies is crucial for cluster stability and security. Detailed explanations and examples are in the [main documentation](./docs/README.md#critical-protection-policies).

1. **PVC Protection**: All PersistentVolumeClaims *must* include the `kubernetes.io/pvc-protection` finalizer.
2. **Ingress Domain Schema**: All applications *must* follow the standardized domain schema (`<application-name>.stillon.top`) and TLS configuration.
3. **Namespace Management**: Namespaces are created manually (`kubectl create namespace <namespace>`) and are *not* managed by Flux. The `targetNamespace` field in Flux Kustomizations should be used to deploy resources into these pre-existing namespaces.

### GitOps Workflow

1. **Repository as Source of Truth**: Make changes to this repository first. Flux applies them. Avoid direct `kubectl apply` for persistent changes.
2. **Secure Sensitive Data**: Use SealedSecrets for all secrets. Never commit unencrypted secrets.
3. **Documentation as Code**: Keep documentation, especially in the [`docs/`](./docs/) directory, updated with changes. This is key for Copilot's understanding and effective assistance. Meaningful commit messages are also important.

## Monitoring & Verification

- Monitor Flux reconciliation: `flux get kustomizations -A`
- Verify application deployment: `kubectl get all -n <application-namespace>`
- Check application health via its domain: `https://<application-name>.stillon.top`

## Repository Workflow Philosophy

- **`apps/` & `kustomize/`**: For complete, fully Flux-managed applications.
- **`apps-incomplete/` & `kustomize-incomplete/`**: For partially managed applications or those requiring manual steps.
- **`test/`**: For temporary experiments (not committed).
- **`scripts/`**: Utility scripts, mainly for legacy operations or specific tasks not covered by pure GitOps.

---
