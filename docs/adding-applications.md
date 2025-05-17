# Adding New Applications to the Cluster

This document provides step-by-step guidance for adding new applications to the k3s cluster following GitOps-first principles.

## Prerequisites

- Git repository cloned locally
- Basic understanding of Kubernetes manifests
- Basic understanding of Flux and GitOps principles

## Step 1: Create Namespace

First, create the namespace manually to ensure it's not managed by Flux (this prevents accidental deletion):

```bash
# Create namespace.yaml
cat > namespace.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: my-application
EOF

# Apply it manually
kubectl apply -f namespace.yaml
```

## Step 2: Create Application Manifests

Next, create the necessary Kubernetes manifests in the repository:

1. Create a directory structure for your application:

```bash
mkdir -p kustomize/my-application
```

2. Create kustomization.yaml (without namespace.yaml to protect the namespace):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: my-application
resources:
- deployment.yaml
- service.yaml
- ingress.yaml
- pvc.yaml
```

## Step 3: Create Flux Kustomization

Create a Flux Kustomization resource to deploy your application:

```yaml
# apps/my-application.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: my-application
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./kustomize/my-application
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

If your application is not yet fully ready for GitOps management, place it in `apps-incomplete/` instead.

## Step 4: Handle Sensitive Data

If your application requires sensitive data:

1. Create a Secret manifest (temporary, do not commit):

```yaml
# my-application-secret.yaml (temporary file)
apiVersion: v1
kind: Secret
metadata:
  name: my-application-secret
  namespace: my-application
type: Opaque
stringData:
  username: admin
  password: changeme
```

2. Seal the secret using kubeseal:

```bash
kubeseal --format yaml < my-application-secret.yaml > my-application-secret-sealed.yaml
rm my-application-secret.yaml  # Delete the unencrypted file
```

3. Add the sealed secret to your kustomization.yaml file:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: my-application
resources:
- deployment.yaml
- service.yaml
- ingress.yaml
- pvc.yaml
- my-application-secret-sealed.yaml  # Add the sealed secret
```

## Step 5: Apply Critical Protection Policies

### PVC Protection

All PersistentVolumeClaims must include the protection finalizer to prevent accidental deletion:

```yaml
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-application-data
  namespace: my-application
  finalizers:
  - kubernetes.io/pvc-protection
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

### Ingress Domain Schema

All ingress resources must follow the standardized domain schema:

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-application
  namespace: my-application
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  rules:
  - host: my-application.stillon.top
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-application
            port:
              number: 8080
  tls:
  - hosts:
    - my-application.stillon.top
    secretName: my-application-tls
```

## Step 6: Commit and Let Flux Deploy

1. Commit your changes to the repository:

   ```bash
   git add .
   git commit -m "Add my-application"
   git push
   ```

2. Flux will automatically detect the changes and deploy your application to the cluster.

3. Monitor the deployment status:

   ```bash
   flux get kustomizations
   ```

## Step 7: Verify Deployment

1. Verify that your application has been deployed successfully:

   ```bash
   kubectl get all -n my-application
   ```

2. Access your application using its domain name:

   `https://my-application.stillon.top`

## Step 8: Update Documentation

Once the application is successfully deployed and verified:

1. Run the documentation update script to refresh application lists:

   ```bash
   ./scripts/update_documentation.sh
   ```

2. Commit the updated documentation:

   ```bash
   git add docs/
   git commit -m "Update documentation with new application"
   git push
   ```

This completes the GitOps-first deployment process.
