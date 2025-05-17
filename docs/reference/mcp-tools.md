# MCP Server Tools for Kubernetes

This document details how to use Model Context Protocol (MCP) server tools to interact directly with the Kubernetes cluster. These tools provide an integrated experience for accessing and managing cluster resources directly within Copilot.

## Cluster Information Tools

| Tool                       | Description                                  | Usage                               |
|----------------------------|----------------------------------------------|-------------------------------------|
| `bb7_configuration_view`   | View cluster configuration                   | Use to check current kubeconfig     |
| `bb7_namespaces_list`      | List all namespaces                          | Check available namespaces          |
| `bb7_events_list`          | List all events                              | Troubleshoot cluster issues         |

## Pod Management Tools

| Tool                           | Description                      | Usage                                       |
|--------------------------------|----------------------------------|---------------------------------------------|
| `bb7_pods_list`                | List all pods                    | Get overview of all running pods            |
| `bb7_pods_list_in_namespace`   | List pods in namespace           | Focus on specific namespace                 |
| `bb7_pods_get`                 | Get pod details                  | Check specific pod configuration            |
| `bb7_pods_exec`                | Execute command in pod           | Run commands inside containers              |
| `bb7_pods_log`                 | View pod logs                    | Troubleshoot pod issues                     |
| `bb7_pods_delete`              | Delete pod                       | Remove problematic pods                     |
| `bb7_pods_run`                 | Run new pod                      | Test configurations or troubleshoot         |

## Resource Management Tools

| Tool                               | Description                                  | Usage                                            |
|------------------------------------|----------------------------------------------|--------------------------------------------------|
| `bb7_resources_list`               | List resources by kind                       | Check deployments, services, etc.                |
| `bb7_resources_get`                | Get specific resource                        | View detailed configuration                      |
| `bb7_resources_create_or_update`   | Create/update resource                       | Apply changes directly (use with caution)        |
| `bb7_resources_delete`             | Delete resource                              | Remove resources (use with caution)              |

## Helm Management Tools

| Tool                     | Description                      | Usage                                   |
|--------------------------|----------------------------------|-----------------------------------------|
| `bb7_helm_list`          | List Helm releases               | Check deployed Helm charts              |
| `bb7_helm_install`       | Install Helm chart               | Deploy applications via Helm            |
| `bb7_helm_uninstall`     | Uninstall Helm release           | Remove Helm-deployed applications       |

## Flux-Specific Tools

| Tool                               | Description                                  | Usage                                       |
|------------------------------------|----------------------------------------------|---------------------------------------------|
| `bb7_get_flux_instance`            | Get Flux installation details                | Check Flux controllers and status           |
| `bb7_reconcile_flux_helmrelease`   | Reconcile Flux HelmRelease                   | Force Helm release update                   |
| `bb7_reconcile_flux_kustomization` | Reconcile Flux Kustomization                 | Force kustomization update                  |
| `bb7_reconcile_flux_source`        | Reconcile Flux source                        | Force source update                         |
| `bb7_suspend_flux_reconciliation` | Suspend Flux reconciliation                  | Temporarily stop reconciliation             |
| `bb7_resume_flux_reconciliation`  | Resume Flux reconciliation                   | Resume paused reconciliation                |
| `bb7_search_flux_docs`           | Search Flux documentation                    | Access up-to-date Flux API specs            |

## File Operations Tools

These tools allow interaction with the repository files directly from Copilot.

| Tool                             | Description                                  | Usage                                                       |
|----------------------------------|----------------------------------------------|-------------------------------------------------------------|
| `bb7_list_allowed_directories`   | List allowed directories                     | See which directories can be accessed                       |
| `bb7_list_directory`             | List directory contents                      | View files and directories                                  |
| `bb7_directory_tree`             | Get directory tree                           | View complete directory structure                           |
| `bb7_search_files`               | Search for files                             | Find files by pattern                                       |
| `bb7_read_file`                  | Read file contents                           | View file content                                           |
| `bb7_read_multiple_files`        | Read multiple files                          | Compare or analyze multiple files                           |
| `bb7_create_directory`           | Create a new directory                       | Set up directory structures                                 |
| `bb7_write_file`                 | Write to file                                | Create or overwrite files (use with caution if overwriting) |
| `bb7_edit_file`                  | Edit file                                    | Make changes to existing files                              |
| `bb7_move_file`                  | Move or rename a file/directory              | Organize files                                              |
| `bb7_get_file_info`              | Get detailed file metadata                   | Check file size, modification times, etc.                   |

## Git Operations Tools

These tools allow performing Git operations on the repository directly from Copilot.

| Tool                      | Description                         | Usage                                       |
|---------------------------|-------------------------------------|---------------------------------------------|
| `bb7_git_status`          | View git status                     | Check for uncommitted changes               |
| `bb7_git_add`             | Add files to staging                | Prepare files for commit                    |
| `bb7_git_commit`          | Commit changes                      | Record changes to the repository            |
| `bb7_git_diff`            | See differences                     | Compare branches or commits                 |
| `bb7_git_diff_staged`     | View staged changes                 | Review changes before committing            |
| `bb7_git_diff_unstaged`   | View unstaged changes               | See changes not yet staged                  |
| `bb7_git_log`             | Show commit logs                    | Review repository history                   |
| `bb7_git_reset`           | Unstage changes                     | Revert staged files                         |
| `bb7_git_show`            | Show commit contents                | Inspect a specific commit                   |
| `bb7_git_checkout`        | Switch branches                     | Change the active branch                    |
| `bb7_git_create_branch`   | Create a new branch                 | Start a new line of development             |

## GitOps-First Workflow with MCP Tools

While the repository is the source of truth for our GitOps approach, MCP tools are valuable for:

1. **Reading Information**: Analyzing the current cluster state before making repository changes
2. **Verification**: Confirming that Flux properly applied changes from the repository
3. **Troubleshooting**: Diagnosing issues when applications aren't behaving as expected
4. **Exploration**: Understanding how things are currently configured

### Example Workflow

1. **View Applications**: Check what's currently running

   ```bash
   bb7_namespaces_list
   bb7_pods_list_in_namespace my-namespace
   ```

2. **Verify Configuration**: Examine how resources are configured

   ```bash
   bb7_resources_get apiVersion=apps/v1 kind=Deployment name=my-app namespace=my-namespace
   ```

3. **Check Logs**: Troubleshoot issues

   ```bash
   bb7_pods_log name=my-app-pod-xyz namespace=my-namespace
   ```

4. **Make Changes**: Always make changes in repository files, not directly to the cluster

   ```bash
   bb7_edit_file path=/home/dave/src/k3s-config/kustomize/my-app/deployment.yaml
   ```

5. **Commit Changes**: Use Git to commit and push changes

   ```bash
   bb7_git_add repo_path=/home/dave/src/k3s-config files=["kustomize/my-app/deployment.yaml"]
   bb7_git_commit repo_path=/home/dave/src/k3s-config message="Update my-app deployment"
   ```

6. **Verify Reconciliation**: Confirm Flux applied your changes. You can also use this to trigger an immediate reconciliation if needed.

   ```bash
   bb7_reconcile_flux_kustomization name=my-app namespace=flux-system with_source=true
   ```

Remember to always follow GitOps principles: make changes to the repository, not directly to the cluster whenever possible. MCP tools that modify the cluster directly (e.g., `bb7_resources_create_or_update`, `bb7_pods_delete`) should be used sparingly, primarily for temporary troubleshooting or exploration, not for persistent changes that should be managed via GitOps.
