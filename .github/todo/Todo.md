# Project Todo List

## Inbox
<!-- Add new tasks here for Copilot to organize -->

## Organized Tasks
<!-- Copilot will maintain this section -->

### High Priority
<!-- Critical bugs and important features -->
- #security In the linkding deployment, we need to make the env variable for the superuser password a sealed secret
- #infrastructure Move toward GitOps-first approach - Update all documentation and workflows to prioritize repository changes over direct cluster interaction
- #documentation Complete MCP server tools documentation - Ensure all available tools are documented with examples
- #feature Implement Dex authentication for Choremane - Set up Dex as OpenID Connect provider according to the PR plan in docs/pull-requests/dex-choremane-auth.md

### Medium Priority
<!-- Enhancements and improvements -->
- #documentation Update repository documentation structure to reflect GitOps-first approach with comprehensive MCP tools
- #documentation Create documentation on how to use MCP Flux tools for reconciliation and monitoring
- #maintenance Update all kustomize manifests with correct labels and annotations - Ensure all manifests in kustomize/ directory (those actively reconciled by flux) have consistent and correct metadata
- #bug Investigate Traefik dashboard issues - Fix the Traefik dashboard that doesn't load information when accessed via port forwarding (note: using K3S bundled Traefik)
- #infrastructure Assess namespace.yaml requirements - Determine if namespace.yaml manifests need to be added to all kustomize/ resources for improved portability

### Low Priority
<!-- Nice-to-haves and maintenance tasks -->
- #maintenance Deprecate legacy scripts - Move away from script-heavy workflow toward Copilot-managed workflows

## In Progress
<!-- Tasks currently being worked on -->

## Completed
<!-- Finished tasks -->
- #enhancement Modularize copilot-instructions.md
- #documentation Create self-documenting cluster system - Develop documentation about the cluster using MCP server for Kubernetes, integrate with k3s-config repo knowledge, update copilot-instructions for cluster awareness, and implement auto-documentation updates on repo pushes
- #security Protect PVC resources from deletion - Implement protections for all PVC resources in the kustomize/ directory
