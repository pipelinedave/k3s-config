# ToolHive Operator

The ToolHive Kubernetes Operator manages MCP (Model Context Protocol) servers in Kubernetes clusters. It allows you to define MCP servers as Kubernetes resources and automates their deployment and management.

## Overview

This deployment uses Flux HelmRelease resources to install and manage the ToolHive operator, following our GitOps workflow patterns.

## Installation

The operator is deployed via two Helm charts:
1. **toolhive-operator-crds**: Custom Resource Definitions
2. **toolhive-operator**: The operator itself

Both are managed through Flux HelmRelease resources that reference an OCI-based Helm repository.

## Components

### Core Resources

- `namespace.yaml`: Creates the `toolhive-system` namespace
- `helm-repository.yaml`: Defines the OCI Helm repository source
- `helm-release-crds.yaml`: Installs the CRDs
- `helm-release-operator.yaml`: Installs the operator with custom configuration

### Configuration

The operator is configured with:
- **Security**: Non-root containers, read-only filesystem, dropped capabilities
- **Resources**: Appropriate CPU/memory limits and requests
- **RBAC**: Minimal required permissions for operator and toolhive pods
- **Health checks**: Liveness and readiness probes
- **Dependencies**: CRDs installed before operator

### Networking

The operator exposes:
- Port 8080: Metrics endpoint
- Port 8081: Health check endpoint

## Usage

### Creating MCP Servers

Once deployed, you can create MCP servers using the `MCPServer` custom resource:

```yaml
apiVersion: toolhive.stacklok.io/v1alpha1
kind: MCPServer
metadata:
  name: my-mcp-server
  namespace: toolhive-system
spec:
  image: "your-mcp-server:latest"
  transport: "sse"  # or "stdio"
  port: 8080
  env:
    - name: API_URL
      value: "https://api.example.com"
  resources:
    requests:
      cpu: "50m"
      memory: "64Mi"
    limits:
      cpu: "100m"
      memory: "128Mi"
```

### Using Secrets

For sensitive configuration, reference Kubernetes secrets:

```yaml
spec:
  secrets:
    - secretName: api-credentials
      key: api-key
      targetEnvName: API_KEY
```

### Checking Status

Monitor your MCP servers:

```bash
kubectl get mcpservers -n toolhive-system
kubectl describe mcpserver my-mcp-server -n toolhive-system
```

## Example

An example MCP server configuration is provided in `example-mcp-server.yaml`. To deploy it:

1. Uncomment the resource in `kustomization.yaml`
2. Modify the image and configuration as needed
3. Commit and push changes

## Architecture

The operator creates:
- **Deployment**: Runs the MCP server container
- **Service**: Exposes the MCP server within the cluster
- **RBAC**: Configures appropriate permissions

## Security Considerations

- All containers run as non-root users
- Read-only root filesystems where possible
- Minimal RBAC permissions
- Network policies can be applied to restrict communication

## Monitoring

The operator exposes metrics on port 8080 that can be scraped by Prometheus or other monitoring systems.

## Troubleshooting

### Common Issues

1. **CRDs not installed**: Ensure the CRDs HelmRelease is healthy
2. **RBAC issues**: Check service account permissions
3. **Image pull errors**: Verify image registry access

### Useful Commands

```bash
# Check operator status
kubectl get helmreleases -n toolhive-system

# View operator logs
kubectl logs -n toolhive-system deployment/toolhive-operator

# Check MCP server status
kubectl get mcpservers -A

# Debug MCP server issues
kubectl describe mcpserver <name> -n toolhive-system
kubectl logs -n toolhive-system <mcp-server-pod>
```

## Deployed MCP Servers

### fetch

- **Purpose**: Web content fetching capabilities for LLMs
- **Image**: `mcp/fetch:latest`
- **Transport**: stdio
- **Tools**: `fetch` - Fetches content from websites
- **Secrets**: None required
- **Network**: Outbound connections allowed

### Example Server (mkp)

- **Purpose**: Example Kubernetes MCP server for testing
- **Image**: `ghcr.io/stackloklabs/mkp/server`
- **Transport**: sse (Server-Sent Events)
- **Tools**: Kubernetes API interactions
- **Port**: 8080

## Available MCP Servers from Registry

The ToolHive project maintains a curated registry of MCP servers. Some notable ones include:

**Development & DevOps:**

- `git` - Git repository interaction
- `github` - GitHub API integration (requires token)
- `gitlab` - GitLab API integration (requires token)
- `terraform` - Terraform/IaC development
- `k8s` (mkp) - Kubernetes cluster interaction

**Data & Analysis:**

- `postgres` - PostgreSQL database access
- `sqlite` - SQLite database with business insights
- `redis` - Redis key-value store interaction

**Security & Monitoring:**

- `semgrep` - Code security scanning
- `osv` - Open Source Vulnerabilities database
- `grafana` - Monitoring and observability

**Web & APIs:**

- `fetch` - Web content fetching
- `brave-search` - Web search capabilities
- `firecrawl` - Advanced web scraping

**Productivity:**

- `slack` - Slack workspace integration
- `atlassian` - Confluence and Jira integration
- `gdrive` - Google Drive file operations

To see the full registry: [ToolHive Registry JSON](https://raw.githubusercontent.com/stacklok/toolhive/main/pkg/registry/data/registry.json)

## References

- [ToolHive GitHub Repository](https://github.com/stacklok/toolhive)
- [Operator Documentation](https://github.com/stacklok/toolhive/blob/main/cmd/thv-operator/README.md)
- [Model Context Protocol](https://modelcontextprotocol.io/)
