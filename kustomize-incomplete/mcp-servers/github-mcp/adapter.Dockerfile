# Stage 1: Get socat
FROM alpine/socat:1.7.4.4-r0 AS socat_base

# Stage 2: Get the github-mcp-server binary
FROM ghcr.io/github/github-mcp-server:latest AS github_server_source

# Stage 3: Combine them
FROM socat_base
# Copy the github-mcp-server binary from the source image
COPY --from=github_server_source /server/github-mcp-server /usr/local/bin/github-mcp-server

# Ensure it's executable
RUN chmod +x /usr/local/bin/github-mcp-server

# Socat will be the entrypoint/command in the Kubernetes deployment spec.
# No CMD or ENTRYPOINT needed here as socat will be called directly.