# GitOps Workflow Guidelines

This document outlines the preferred workflow for managing the k3s cluster using GitOps principles.

## Core GitOps Principles

1. **Repository as the Source of Truth**
   - The Git repository is the single source of truth for desired cluster state
   - All changes to the system should be made through the repository, not directly on the cluster
   - Flux automatically reconciles the repository with the cluster state

2. **Declarative Configuration**
   - All resources are defined as declarative configurations
   - The desired state is explicitly declared rather than the steps to achieve it
   - Configuration is version-controlled and auditable

3. **Pull-Based Deployment Model**
   - Flux pulls changes from the repository (rather than changes being pushed to the cluster)
   - No direct access to the cluster is required for normal operations
   - Changes are automatically applied when detected in the repository

4. **Protection of Data**
   - All PVCs must include the kubernetes.io/pvc-protection finalizer
   - Namespaces are created manually, not managed by Flux
   - Critical data is always protected against accidental deletion

5. **Standardized Access**
   - All applications follow the domain schema standard (application-name.stillon.top)
   - TLS is configured using cert-manager
   - Consistent ingress annotations are applied

## GitOps-First Workflow

### Adding a New Application

1. **Create namespace manually** (not managed by Flux):

   ```bash
   # Create namespace.yaml
   cat > namespace.yaml << EOF
   apiVersion: v1
   kind: Namespace
   metadata:
     name: my-application
   EOF

   # Apply manually to protect against Flux pruning
   kubectl apply -f namespace.yaml
   ```

2. **Create manifests in repository**:

   - Create directory in `kustomize/` for the application
   - Create all necessary manifests (deployment, service, ingress, etc.)
   - Include PVC protection finalizers
   - Follow domain schema for ingress resources

3. **Add Flux Kustomization**:

   ```yaml
   # apps/my-application.yaml
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
   ```

4. **Handle sensitive data**:

   - Create and seal sensitive data with SealedSecrets
   - Delete the original unencrypted files
   - Commit only the sealed versions to the repository

5. **Commit and push changes**:

   ```bash
   git add .
   git commit -m "Add my-application"
   git push
   ```

6. **Monitor and verify**:

   ```bash
   flux get kustomization my-application
   kubectl get all -n my-application
   ```

For complete details, see [Adding Applications](adding-applications.md).

### Updating an Application

1. **Make changes to manifests**:

   - Edit the relevant files in the repository
   - Follow existing patterns and standards

2. **Commit and push changes**:

   ```bash
   git add .
   git commit -m "Update my-application"
   git push
   ```

3. **Monitor Flux reconciliation**:

   ```bash
   flux get kustomization my-application
   ```

### Troubleshooting

When issues occur, follow this workflow:

1. **Observe current state** using MCP tools:

   ```bash
   bb7_pods_list_in_namespace namespace=my-application
   bb7_pods_log name=my-pod-xyz namespace=my-application
   ```

2. **Identify issues** in the manifests or application

3. **Make corrections** in the repository files

4. **Commit and push** changes to fix the issue

5. **Verify resolution** using MCP tools and kubectl

## Proper Use of MCP Server Tools

MCP server tools provide a convenient way to interact with the cluster, but should be used in accordance with GitOps principles:

### Recommended Uses

1. **Observation**: View the current state of resources

   ```bash
   bb7_pods_list_in_namespace namespace=my-app
   bb7_resources_get apiVersion=v1 kind=Service name=my-service namespace=my-app
   ```

2. **Verification**: Confirm changes were applied correctly

   ```bash
   bb7_reconcile_flux_kustomization name=my-app namespace=flux-system
   ```

3. **Troubleshooting**: Diagnose issues

   ```bash
   bb7_pods_log name=my-pod namespace=my-app
   bb7_events_list namespace=my-app
   ```

4. **Repository Updates**: Make changes to Git repository files

   ```bash
   bb7_edit_file path=/home/dave/src/k3s-config/kustomize/my-app/deployment.yaml
   bb7_git_commit repo_path=/home/dave/src/k3s-config message="Update deployment"
   ```

### Discouraged Uses

- ❌ Making persistent changes directly to cluster resources
- ❌ Running one-off commands that bypass the GitOps workflow
- ❌ Creating resources that aren't tracked in the repository

## Handling Sensitive Data

All sensitive data should be sealed using SealedSecrets:

1. Create a regular Secret (temporary file, never commit):

   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: my-secret
     namespace: my-namespace
   type: Opaque
   stringData:
     key: value
   ```

2. Seal it:

   ```bash
   kubeseal --format yaml < my-secret.yaml > my-secret-sealed.yaml
   ```

3. Delete the original plaintext Secret file
4. Add the SealedSecret to your kustomization.yaml and commit it

## Documentation Updates

After making significant changes to the cluster:

1. Run the update_documentation.sh script:

   ```bash
   ./scripts/update_documentation.sh
   ```

2. Review the changes made by the script

3. Commit the updated documentation:

   ```bash
   git add docs/
   git commit -m "Update documentation"
   git push
   ```

This keeps documentation in sync with the actual state of the cluster.
