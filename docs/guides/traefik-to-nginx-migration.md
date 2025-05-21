# Traefik to Nginx Ingress Migration Guide

This document outlines how to migrate ingress resources from Traefik to Nginx Ingress Controller.

## Common Annotation Mappings

| Traefik Annotation | Nginx Equivalent | Notes |
|---|---|---|
| `kubernetes.io/ingress.class: traefik` | `kubernetes.io/ingress.class: nginx` | Basic ingress class |
| `traefik.ingress.kubernetes.io/router.entrypoints: websecure` | `nginx.ingress.kubernetes.io/ssl-redirect: "true"` | Force HTTPS |
| `traefik.ingress.kubernetes.io/router.tls: "true"` | `nginx.ingress.kubernetes.io/ssl-redirect: "true"` | TLS configuration |
| `traefik.ingress.kubernetes.io/rewrite-target: /` | `nginx.ingress.kubernetes.io/rewrite-target: /` | Path rewriting |
| `traefik.ingress.kubernetes.io/whitelist-source-range` | `nginx.ingress.kubernetes.io/whitelist-source-range` | IP whitelisting |
| `traefik.ingress.kubernetes.io/redirect-regex` | `nginx.ingress.kubernetes.io/server-snippet` | Requires custom NGINX conf |

## Migration Example

### Before (Traefik):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: default
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - app.stillon.top
    secretName: app-tls
  rules:
  - host: app.stillon.top
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

### After (Nginx):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - app.stillon.top
    secretName: app-tls
  rules:
  - host: app.stillon.top
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

## Cert-Manager Integration

Cert-manager annotations work the same way with both ingress controllers:

```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt-prod
```

### TLS Secret Handling

When migrating from Traefik to Nginx, it's important to properly handle TLS secrets:

1. **Delete existing TLS secrets**: After updating your ingress to use Nginx, delete the existing TLS secret that was created for Traefik:

```bash
kubectl delete secret <secret-name> -n <namespace>
```

For example:

```bash
kubectl delete secret linkding-tls -n linkding
```

2. **Let cert-manager create a new secret**: Once you delete the old secret, cert-manager will automatically create a new one for the Nginx ingress controller.

3. **Verify certificate issuance**: You can check the status of the certificate:

```bash
kubectl get certificate -n <namespace>
```

4. **Troubleshooting**: If the certificate doesn't get issued, check the cert-manager logs and ensure that:
   - The ClusterIssuer is properly configured for Nginx (using `ingress.class: nginx` in the solver configuration)
   - There are no old challenges or certificate resources that need to be cleaned up

This step is critical because cert-manager resources are tied to the specific ingress controller that requested them, and certificates may not renew properly if they were initially created for a different controller.

## Authentication

For authentication, NGINX Ingress Controller offers a few options:

### Basic Authentication

```yaml
annotations:
  nginx.ingress.kubernetes.io/auth-type: basic
  nginx.ingress.kubernetes.io/auth-secret: basic-auth
  nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
```

You'll need to create a secret with `htpasswd` credentials:

```bash
htpasswd -c auth username
kubectl create secret generic basic-auth --from-file=auth
```

### OAuth2 Proxy

For more complex authentication (replacing Traefik ForwardAuth):

1. Deploy OAuth2 Proxy 
2. Add the following annotations:

```yaml
annotations:
  nginx.ingress.kubernetes.io/auth-url: "https://oauth2-proxy.example.com/oauth2/auth"
  nginx.ingress.kubernetes.io/auth-signin: "https://oauth2-proxy.example.com/oauth2/start?rd=$escaped_request_uri"
```

## Rate Limiting

```yaml
annotations:
  nginx.ingress.kubernetes.io/limit-rps: "10"
  nginx.ingress.kubernetes.io/limit-connections: "5"
```

## Custom Headers

```yaml
annotations:
  nginx.ingress.kubernetes.io/configuration-snippet: |
    more_set_headers "X-Frame-Options: DENY";
    more_set_headers "X-Content-Type-Options: nosniff";
```

## CORS

```yaml
annotations:
  nginx.ingress.kubernetes.io/enable-cors: "true"
  nginx.ingress.kubernetes.io/cors-allow-methods: "GET, PUT, POST, DELETE, PATCH, OPTIONS"
  nginx.ingress.kubernetes.io/cors-allow-headers: "DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization"
  nginx.ingress.kubernetes.io/cors-allow-origin: "*"
```