# Dex Authentication for Choremane

This directory contains the Kubernetes manifests for deploying Dex as an OpenID Connect (OIDC) provider for Choremane and other applications.

## Overview

Dex serves as an identity broker that can connect to various external identity providers (like Google, GitHub, LDAP, etc.) and provide a consistent OIDC interface for applications.

## Configuration

### Clients

The following clients are configured to use Dex:

1. **Choremane**
   - Client ID: `choremane`
   - Redirect URIs:
     - https://chores.stillon.top/api/auth/callback
     - http://localhost:8080/api/auth/callback (for local development)

### Identity Providers

The following external identity providers are configured:

1. **Google**
   - Client credentials are stored in a Kubernetes secret
   - Redirect URI: https://dex.stillon.top/callback

## Deployment

Dex is deployed using FluxCD as defined in `/apps/dex.yaml`. The deployment includes:

- Namespace: `dex`
- ConfigMap: Configuration for Dex
- Deployment: Dex server
- Service: Internal Kubernetes service
- Ingress: External access via Traefik
- Secret: Google OAuth credentials

## Authentication Flow

1. User attempts to access Choremane
2. If not authenticated, user is redirected to Dex
3. Dex presents identity provider options (Google)
4. User authenticates with the identity provider
5. Identity provider redirects back to Dex
6. Dex issues OIDC tokens
7. User is redirected back to Choremane with tokens
8. Choremane validates tokens with Dex

## Troubleshooting

- Check Dex logs: `kubectl logs -n dex deployment/dex`
- Verify Google credentials: `kubectl get secret -n dex dex-google-credentials -o yaml`
- Test Dex connectivity: `curl -k https://dex.stillon.top/.well-known/openid-configuration`

## Security Considerations

- Client secrets should be rotated regularly
- Consider implementing IP restrictions for administrative access
- Monitor Dex logs for unusual authentication patterns
