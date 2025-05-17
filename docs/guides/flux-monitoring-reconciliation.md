# Monitoring Flux and Reconciling Resources with MCP Tools

This guide explains how to use Model Context Protocol (MCP) server tools to monitor the status of Flux custom resources and trigger reconciliations within your k3s cluster. This approach aligns with the GitOps-first philosophy, allowing you to observe and interact with the cluster's declarative state managed by Flux.

## Understanding Flux Kustomizations

Flux Kustomizations (`kustomize.toolkit.fluxcd.io/v1beta2` or similar, check `bb7_get_kubernetes_api_versions`) are central to how Flux manages deployments. They define:
- The path to your Kubernetes manifests within the Git repository.
- The interval at which Flux should check for changes.
- Any dependencies on other Kustomizations.
- Health checks to determine if the deployed resources are ready.

## Monitoring Kustomization Status

You can check the status of a specific Flux Kustomization using the `bb7_get_kubernetes_resources` tool.

**Tool Call:**
```json
{
  "tool_name": "bb7_get_kubernetes_resources",
  "arguments": {
    "apiVersion": "kustomize.toolkit.fluxcd.io/v1",
    "kind": "Kustomization",
    "name": "my-app-kustomization",
    "namespace": "flux-system"
  }
}
```

**Interpreting the Output:**

Look for the `status` field in the response. Key sub-fields include:
- `conditions`: An array indicating the state of the Kustomization (e.g., `Ready`, `Healthy`).
  - A `Ready` condition with `status: "True"` means Flux has successfully applied the manifests from the source.
  - A `Healthy` condition with `status: "True"` means the health checks defined in the Kustomization have passed.
- `lastAppliedRevision`: The Git commit hash that was last applied.
- `lastAttemptedRevision`: The Git commit hash that Flux last attempted to apply. This can be useful for debugging if `lastAppliedRevision` is not updating.

**Example Scenario: Checking `choremane-prod`**

To check the `choremane-prod` application, which has its Kustomization defined in `apps/choremane-prod.yaml`:

1.  **Identify Kustomization Name and Namespace:**
    The Kustomization resource will typically have a `metadata.name` (e.g., `choremane-prod`) and `metadata.namespace` (usually `flux-system`).

2.  **MCP Tool Call:**
    ```json
    {
      "tool_name": "bb7_get_kubernetes_resources",
      "arguments": {
        "apiVersion": "kustomize.toolkit.fluxcd.io/v1",
        "kind": "Kustomization",
        "name": "choremane-prod",
        "namespace": "flux-system"
      }
    }
    ```

3.  **Review Status:**
    Examine the `status.conditions` to ensure it's `Ready` and `Healthy`. Check `lastAppliedRevision` to confirm it matches the latest commit you expect to be deployed.

## Triggering Reconciliation

If you've pushed changes to your Git repository and want Flux to pick them up immediately, or if a Kustomization is in a failed state and you want to retry, you can trigger a reconciliation.

### Reconciling a Kustomization

Use the `bb7_reconcile_flux_kustomization` tool.

**Tool Call:**
```json
{
  "tool_name": "bb7_reconcile_flux_kustomization",
  "arguments": {
    "name": "my-app-kustomization",
    "namespace": "flux-system",
    "with_source": true
  }
}
```
- `name`: The name of the Kustomization resource.
- `namespace`: The namespace of the Kustomization resource (usually `flux-system`).
- `with_source`: Set to `true` to also reconcile the associated GitRepository or other source. This ensures Flux fetches the latest from your repository before attempting to apply the Kustomization.

**Example Scenario: Reconciling `docspell`**

If you've just updated manifests for `docspell` in the `kustomize/docspell/` directory:

1.  **Identify Kustomization Name:** `docspell` (from `apps/docspell.yaml`)
2.  **MCP Tool Call:**
    ```json
    {
      "tool_name": "bb7_reconcile_flux_kustomization",
      "arguments": {
        "name": "docspell",
        "namespace": "flux-system",
        "with_source": true
      }
    }
    ```
3.  **Monitor Status:** After triggering reconciliation, use `bb7_get_kubernetes_resources` as described above to monitor its progress and confirm it becomes `Ready` and `Healthy`.

## Monitoring Flux HelmReleases

Flux can also manage applications deployed via Helm charts using `HelmRelease` custom resources.

**Tool Call to Get HelmRelease Status:**
```json
{
  "tool_name": "bb7_get_kubernetes_resources",
  "arguments": {
    "apiVersion": "helm.toolkit.fluxcd.io/v2beta1", // Or the relevant API version
    "kind": "HelmRelease",
    "name": "my-helm-app",
    "namespace": "app-namespace" // Namespace where HelmRelease is deployed
  }
}
```

**Interpreting Output:**
Similar to Kustomizations, check the `status.conditions` for `Ready` and `Healthy` states. The `lastAppliedRevision` will often correspond to the chart version and values revision.

## Reconciling a HelmRelease

Use the `bb7_reconcile_flux_helmrelease` tool.

**Tool Call:**
```json
{
  "tool_name": "bb7_reconcile_flux_helmrelease",
  "arguments": {
    "name": "my-helm-app",
    "namespace": "app-namespace",
    "with_source": true // If the HelmChart source also needs reconciliation
  }
}
```

## General Troubleshooting Steps

If a Kustomization or HelmRelease is not becoming healthy:

1.  **Check Flux Controller Logs:**
    The primary Flux controllers are usually in the `flux-system` namespace.
    - `source-controller`: Fetches artifacts from sources like Git.
    - `kustomize-controller`: Applies Kustomizations.
    - `helm-controller`: Manages HelmReleases.

    Use `bb7_pods_list_in_namespace` to find the controller pods and then `bb7_pods_log` to view their logs.
    ```json
    {
      "tool_name": "bb7_pods_list_in_namespace",
      "arguments": {"namespace": "flux-system"}
    }
    ```
    Then, for a specific pod:
    ```json
    {
      "tool_name": "bb7_pods_log",
      "arguments": {
        "pod_name": "kustomize-controller-xxxxxxxxx-yyyyy",
        "pod_namespace": "flux-system",
        "container_name": "manager" // Often the container is named 'manager'
      }
    }
    ```

2.  **Check Events in the Application's Namespace:**
    Kubernetes events can provide clues about issues with creating or updating resources.
    ```json
    {
      "tool_name": "bb7_events_list",
      "arguments": {"namespace": "my-app-namespace"}
    }
    ```

3.  **Describe the Flux Resource:**
    The `bb7_get_kubernetes_resources` output is already a "describe". Pay close attention to the `Events` section at the very end of a typical `kubectl describe` output, which is often mirrored in the conditions or status messages of the CRD.

4.  **Verify Manifests:**
    Ensure the manifests in your Git repository are valid Kubernetes YAML and that kustomize can build them correctly. If you have local access to the repository and `kustomize` CLI, you can test with `kustomize build <path-to-overlay>`.

By using these MCP tools, you can effectively monitor and manage your Flux deployments directly through a programmatic interface, keeping your operations aligned with GitOps principles.
