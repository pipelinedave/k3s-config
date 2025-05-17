# Using MCP Tools for Flux Reconciliation and Monitoring

This document outlines how to use Model Context Protocol (MCP) server tools to interact with and monitor FluxCD components within your Kubernetes cluster. These tools allow Copilot to manage Flux operations, check statuses, and trigger reconciliations directly.

## Understanding Flux Health and Status

Before diving into specific reconciliations, it's often useful to get a general overview of your Flux instance and the status of its Kustomizations or HelmReleases.

### 1. Checking the Flux Instance

The `bb7_get_flux_instance` tool provides a detailed report about the Flux controllers, their versions, and the status of Custom Resource Definitions (CRDs) managed by Flux. This is a good starting point to ensure Flux itself is healthy.

**Example Usage (Copilot internal):**

```json
{
  "tool_name": "bb7_get_flux_instance"
}
```

Copilot will then parse the output to inform you about the health of your Flux installation.

### 2. Checking Kustomization and HelmRelease Status

To check the status of a specific Flux Kustomization or HelmRelease, Copilot uses the general `bb7_get_kubernetes_resources` tool, as these are Kubernetes custom resources.

**Example: Checking a Kustomization (Copilot internal):**

```json
{
  "tool_name": "bb7_get_kubernetes_resources",
  "tool_params": {
    "apiVersion": "kustomize.toolkit.fluxcd.io/v1",
    "kind": "Kustomization",
    "name": "my-app-kustomization",
    "namespace": "flux-system"
  }
}
```

Copilot will analyze the `status` field of the returned resource, looking at conditions like `Ready` and `Healthy`, and check for any error messages.

**Example: Checking a HelmRelease (Copilot internal):**

```json
{
  "tool_name": "bb7_get_kubernetes_resources",
  "tool_params": {
    "apiVersion": "helm.toolkit.fluxcd.io/v2beta1", // or v2beta2, etc.
    "kind": "HelmRelease",
    "name": "my-helm-chart",
    "namespace": "my-namespace" // HelmReleases are often in the app's namespace
  }
}
```

Again, Copilot examines the `status` for readiness and health.

## Triggering Reconciliations

MCP tools allow Copilot to trigger reconciliations for various Flux components. This is useful when you've pushed changes to your Git repository and want Flux to pick them up immediately, or if you suspect a component is stuck and needs a nudge.

### 1. Reconciling a Flux Kustomization

The `bb7_reconcile_flux_kustomization` tool tells Flux to re-evaluate a specific Kustomization.

- `name`: The name of the Kustomization resource.
- `namespace`: The namespace of the Kustomization resource (usually `flux-system`).
- `with_source` (optional, boolean): If `true`, Flux will also reconcile the source (e.g., GitRepository) associated with this Kustomization before reconciling the Kustomization itself. This is useful to ensure Flux pulls the very latest changes from Git.

**Example Usage (Copilot internal):**

```json
{
  "tool_name": "bb7_reconcile_flux_kustomization",
  "tool_params": {
    "name": "my-app-kustomization",
    "namespace": "flux-system",
    "with_source": true
  }
}
```

Copilot will inform you that the reconciliation has been triggered.

### 2. Reconciling a Flux HelmRelease

To manually trigger the reconciliation of a specific Flux `HelmRelease` and optionally its source, use the `bb7_reconcile_flux_helmrelease` tool. This is useful when you've made changes to a Helm chart or its values and want to apply them immediately without waiting for the scheduled reconciliation.

**Tool:** `bb7_reconcile_flux_helmrelease`

**Purpose:** Triggers the reconciliation of a specified `HelmRelease` resource.

**Arguments:**

- `name` (string, required): The name of the `HelmRelease` to reconcile.
- `namespace` (string, required): The namespace where the `HelmRelease` is located.
- `with_source` (boolean, optional): If `true`, the associated Helm source (e.g., `HelmRepository`) will also be reconciled. Defaults to `false`.

**Example Usage:**

To reconcile the `grafana` HelmRelease in the `monitoring` namespace and also update its source:

```json
{
  "tool_name": "bb7_reconcile_flux_helmrelease",
  "arguments": {
    "name": "grafana",
    "namespace": "monitoring",
    "with_source": true
  }
}
```

**Expected Output:** A confirmation message indicating that the reconciliation has been triggered. You can then use `bb7_get_kubernetes_resources` to check the status of the `HelmRelease`.

### 3. Reconciling a Flux ResourceSet

To manually trigger the reconciliation of a Flux `ResourceSet`, use the `bb7_reconcile_flux_resourceset` tool. `ResourceSet` is a custom resource that allows you to group and manage arbitrary Kubernetes resources.

**Tool:** `bb7_reconcile_flux_resourceset`

**Purpose:** Triggers the reconciliation of a specified `ResourceSet`.

**Arguments:**

- `name` (string, required): The name of the `ResourceSet` to reconcile.
- `namespace` (string, required): The namespace where the `ResourceSet` is located.

**Example Usage:**

To reconcile the `core-infra` ResourceSet in the `flux-system` namespace:

```json
{
  "tool_name": "bb7_reconcile_flux_resourceset",
  "arguments": {
    "name": "core-infra",
    "namespace": "flux-system"
  }
}
```

**Expected Output:** A confirmation message.

### 4. Reconciling a Flux Source

Flux uses various source types (`GitRepository`, `OCIRepository`, `Bucket`, `HelmChart`, `HelmRepository`) to fetch manifests and charts. To manually trigger the reconciliation of a specific source, use the `bb7_reconcile_flux_source` tool. This is useful if you want Flux to immediately pick up changes from the source repository or registry.

**Tool:** `bb7_reconcile_flux_source`

**Purpose:** Triggers the reconciliation of a specified Flux source object.

**Arguments:**

- `kind` (string, required): The kind of the Flux source (e.g., `GitRepository`, `HelmRepository`).
- `name` (string, required): The name of the source object.
- `namespace` (string, required): The namespace where the source object is located.

**Example Usage:**

To reconcile a `GitRepository` named `k3s-config-main` in the `flux-system` namespace:

```json
{
  "tool_name": "bb7_reconcile_flux_source",
  "arguments": {
    "kind": "GitRepository",
    "name": "k3s-config-main",
    "namespace": "flux-system"
  }
}
```

**Expected Output:** A confirmation message. You can then check the status of the source object using `bb7_get_kubernetes_resources`.

## Suspending and Resuming Reconciliations

There might be scenarios where you want to temporarily stop Flux from reconciling a particular resource.

### 1. Suspending Reconciliation

The `bb7_suspend_flux_reconciliation` tool can pause reconciliation for a given Flux resource.

- `apiVersion`: API version of the Flux resource.
- `kind`: Kind of the Flux resource (e.g., `Kustomization`, `HelmRelease`).
- `name`: Name of the resource.
- `namespace`: Namespace of the resource.

**Example: Suspending a Kustomization (Copilot internal):**

```json
{
  "tool_name": "bb7_suspend_flux_reconciliation",
  "tool_params": {
    "apiVersion": "kustomize.toolkit.fluxcd.io/v1",
    "kind": "Kustomization",
    "name": "my-app-kustomization",
    "namespace": "flux-system"
  }
}
```

Copilot will confirm the suspension. The resource will have an annotation indicating it's suspended.

### 2. Resuming Reconciliation

The `bb7_resume_flux_reconciliation` tool will re-enable reconciliation for a previously suspended resource.

- `apiVersion`: API version of the Flux resource.
- `kind`: Kind of the Flux resource.
- `name`: Name of the resource.
- `namespace`: Namespace of the resource.

**Example: Resuming a Kustomization (Copilot internal):**

```json
{
  "tool_name": "bb7_resume_flux_reconciliation",
  "tool_params": {
    "apiVersion": "kustomize.toolkit.fluxcd.io/v1",
    "kind": "Kustomization",
    "name": "my-app-kustomization",
    "namespace": "flux-system"
  }
}
```

Copilot will confirm resumption, and Flux will start reconciling the resource again based on its interval.

## Searching Flux Documentation

If Copilot needs more information about Flux APIs or features, it can use the `bb7_search_flux_docs` tool.

- `query`: The search query.
- `limit` (optional, number): Maximum number of matching documents to return (default is 1).

**Example Usage (Copilot internal):**

```json
{
  "tool_name": "bb7_search_flux_docs",
  "tool_params": {
    "query": "Kustomization spec options"
  }
}
```

This helps Copilot stay up-to-date with Flux capabilities.

## Workflow Summary

1. **Check Overall Health**: Copilot uses `bb7_get_flux_instance` for a system overview.
2. **Check Specific Resource Status**: Copilot uses `bb7_get_kubernetes_resources` to inspect the `status` of Kustomizations, HelmReleases, or Sources.
3. **Push Changes to Git**: You (the user) make changes to your repository and push them.
4. **Trigger Reconciliation (Optional)**: If you want immediate application, ask Copilot to use `bb7_reconcile_flux_kustomization` (with `with_source: true`), `bb7_reconcile_flux_helmrelease`, or `bb7_reconcile_flux_source`. Otherwise, Flux will reconcile based on its defined intervals.
5. **Verify Application**: Copilot checks the resource status again and can also check application-specific resources (Pods, Deployments, Services) using `bb7_pods_list_in_namespace`, `bb7_resources_get`, etc.
6. **Troubleshoot**: If issues arise, Copilot can use reconciliation tools, check events (`bb7_events_list`), or pod logs (`bb7_pods_log`). Suspension/resumption tools can be used for advanced debugging or maintenance.

By leveraging these MCP tools, Copilot can effectively assist in managing and monitoring your FluxCD deployments, aligning with the GitOps-first approach of your cluster.
