# Project Todo List

## Idea Dump
<!-- Place for dumping unorganized ideas -->

## Organized Tasks
<!-- Copilot will maintain this section -->

### High Priority
<!-- Critical bugs and important features -->

### Medium Priority
<!-- Enhancements and improvements -->
- #maintenance Update all kustomize manifests with correct labels and annotations - Ensure all manifests in kustomize/ directory (those actively reconciled by flux) have consistent and correct metadata
- #bug Investigate Traefik dashboard issues - Fix the Traefik dashboard that doesn't load information when accessed via port forwarding (note: using K3S bundled Traefik)
- #infrastructure Assess namespace.yaml requirements - Determine if namespace.yaml manifests need to be added to all kustomize/ resources for improved portability

### Low Priority
<!-- Nice-to-haves and maintenance tasks -->

## In Progress
<!-- Tasks currently being worked on -->

## Completed
<!-- Finished tasks -->
- #documentation Create self-documenting cluster system - Develop documentation about the cluster using MCP server for Kubernetes, integrate with k3s-config repo knowledge, update copilot-instructions for cluster awareness, and implement auto-documentation updates on repo pushes
- #security Protect PVC resources from deletion - Implement protections for all PVC resources in the kustomize/ directory

