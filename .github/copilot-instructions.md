# Global Copilot Instructions

## Todo Management
- Always check for the file `.github/todo/Todo.md` in this repository.
- Process the todo list based on the instructions in `.github/todo/CopilotTodo.md`.
- Maintain the structure of the todo list while allowing me to freely add new items anywhere.
- Help me prioritize and work on tasks from the todo list.

## Markdown Linting
- Always ensure all Markdown files follow consistent linting rules:
  - Use proper heading hierarchy (h1 > h2 > h3)
  - Include blank lines around headings, code blocks, and lists
  - Indent nested list items properly
  - Use backticks for inline code and proper fenced code blocks with language specifiers
  - No bare URLs (use proper link syntax)
  - Include a single newline at the end of files
  - Include proper spacing in lists
  - Validate that ordered lists have proper sequential numbers
- When editing documentation, verify markdown lint compliance before committing

# GitHub Copilot Context for K3s Cluster Configuration
For detailed context about the K3s cluster, please refer to [cluster-context.md](./cluster-context.md).
This file contains information about:
- Cluster Overview
- Auto-Documentation Update procedures
- Repository Structure
- Lists of Fully and Partially Managed Applications
- Cluster Management Workflow
- Critical Protection Policies
- Key Repository Scripts
- Common Kubernetes Operations
- Command Reference
- MCP Server Tools for Kubernetes
- Context Awareness guidelines

## Kubernetes Best Practices & Learnings
- **Immutable Fields (e.g., `spec.selector`)**:
    - Be aware that fields like `spec.selector` in Deployments and StatefulSets are immutable after creation.
    - Avoid changing these fields on existing resources if possible.
    - If new labels are added to Pod templates, the `spec.selector.matchLabels` does not necessarily need to be updated if the existing selector is still sufficient and unique.
    - If a change to an immutable field is absolutely necessary and Flux reconciliation fails:
        - As a last resort, `spec: { force: true }` can be temporarily added to the Flux Kustomization.
        - This will cause resource recreation and potential downtime.
        - **Crucially, `force: true` must be removed from the Kustomization and committed once the issue is resolved.**
- **Standard Labels**: When adding or updating applications, ensure standard Kubernetes labels (`app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/version`, `app.kubernetes.io/component`, `app.kubernetes.io/part-of`, `app.kubernetes.io/managed-by`) are applied consistently to all created resources, including Pod templates within Deployments/StatefulSets.

