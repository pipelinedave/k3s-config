# Project Todo List

## Inbox
<!-- Add new tasks here for Copilot to organize -->

## Organized Tasks
<!-- Copilot will maintain this section -->

### High Priority
<!-- Critical bugs and important features -->
-   [X] #infrastructure Move toward GitOps-first approach - Update all documentation and workflows to reflect a GitOps-first methodology, emphasizing repository changes over direct cluster modification. Ensure MCP tools are presented as the primary means of interaction for Copilot. (Copilot: Ongoing, major updates to cluster-context.md, docs/README.md, docs/adding-applications.md, docs/mcp-tools.md, docs/mcp-flux-tools.md)
-   [X] #documentation Complete MCP server tools documentation - Ensure all available tools are documented with examples in `docs/mcp-tools.md` and `docs/mcp-flux-tools.md`. (Copilot: Completed mcp-tools.md and mcp-flux-tools.md)

### Medium Priority
<!-- Enhancements and improvements -->
- [ ] #documentation Update repository documentation structure to reflect GitOps-first approach with comprehensive MCP tools
- [ ] #documentation Create documentation on how to use MCP Flux tools for reconciliation and monitoring
- #maintenance Update all kustomize manifests with correct labels and annotations - Ensure all manifests in kustomize/ directory (those actively reconciled by flux) have consistent and correct metadata
- #bug Investigate Traefik dashboard issues - Fix the Traefik dashboard that doesn't load information when accessed via port forwarding (note: using K3S bundled Traefik)

### Low Priority
<!-- Nice-to-haves and maintenance tasks -->

## In Progress
<!-- Tasks currently being worked on -->

## Completed
<!-- Finished tasks -->
- #feature Implement Dex authentication for Choremane - Set up Dex as OpenID Connect provider according to the PR plan in docs/pull-requests/dex-choremane-auth.md
- #security In the linkding deployment, we need to make the env variable for the superuser password a sealed secret
- #maintenance Deprecate legacy scripts - Move away from script-heavy workflow toward Copilot-managed workflows
- #enhancement Modularize copilot-instructions.md
- #documentation Create self-documenting cluster system - Develop documentation about the cluster using MCP server for Kubernetes, integrate with k3s-config repo knowledge, update copilot-instructions for cluster awareness, and implement auto-documentation updates on repo pushes
- #security Protect PVC resources from deletion - Implement protections for all PVC resources in the kustomize/ directory
