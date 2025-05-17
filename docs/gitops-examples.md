# GitOps-First Examples

This document provides practical examples of the GitOps-first approach for common tasks in the k3s cluster.

## Adding a New Application

### Example: Adding Linkding Bookmark Manager

Following GitOps principles, we start by creating all necessary manifests in the repository:

1. **Create directory structure**:

```bash
mkdir -p kustomize/linkding
```

2. **Create namespace, deployment, service, and ingress**:

```yaml
# kustomize/linkding/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: linkding
```

```yaml
# kustomize/linkding/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: linkding
  namespace: linkding
spec:
  replicas: 1
  selector:
    matchLabels:
      app: linkding
  template:
    metadata:
      labels:
        app: linkding
    spec:
      containers:
      - name: linkding
        image: sissbruecker/linkding:latest
        ports:
        - containerPort: 9090
        env:
        - name: LD_SUPERUSER_NAME
          value: "admin"
        - name: LD_SUPERUSER_PASSWORD
          valueFrom:
            secretKeyRef:
              name: linkding-credentials
              key: password
        volumeMounts:
        - name: linkding-data
          mountPath: /etc/linkding/data
      volumes:
      - name: linkding-data
        persistentVolumeClaim:
          claimName: linkding-pvc
```

```yaml
# kustomize/linkding/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: linkding
  namespace: linkding
spec:
  selector:
    app: linkding
  ports:
  - port: 80
    targetPort: 9090
  type: ClusterIP
```

```yaml
# kustomize/linkding/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: linkding
  namespace: linkding
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  ingressClassName: traefik
  rules:
  - host: linkding.stillon.top
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: linkding
            port:
              number: 80
  tls:
  - hosts:
    - linkding.stillon.top
    secretName: linkding-tls
```

3. **Create PVC with protection finalizer**:

```yaml
# kustomize/linkding/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: linkding-pvc
  namespace: linkding
  finalizers:
  - kubernetes.io/pvc-protection
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

4. **Create sealed secret for credentials**:

First, create a regular secret:
```yaml
# linkding-credentials.yaml (temporary, do not commit)
apiVersion: v1
kind: Secret
metadata:
  name: linkding-credentials
  namespace: linkding
type: Opaque
stringData:
  password: "super-secure-password"
```

Then seal it:
```bash
kubeseal --format yaml < linkding-credentials.yaml > kustomize/linkding/linkding-credentials-sealed.yaml
rm linkding-credentials.yaml  # Delete the unencrypted file
```

5. **Create kustomization.yaml**:

```yaml
# kustomize/linkding/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: linkding
resources:
- namespace.yaml
- deployment.yaml
- service.yaml
- ingress.yaml
- pvc.yaml
- linkding-credentials-sealed.yaml
commonLabels:
  app: linkding
commonAnnotations:
  description: "Bookmark management system"
```

6. **Create Flux Kustomization**:

```yaml
# apps/linkding.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: linkding
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./kustomize/linkding
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
```

7. **Commit and push changes**:

```bash
git add .
git commit -m "Add linkding bookmark manager"
git push
```

8. **Monitor deployment**:

```bash
flux get kustomization linkding
kubectl get all -n linkding
```

## Updating an Application

### Example: Updating Linkding Image Version

1. **Edit the deployment manifest**:

```yaml
# kustomize/linkding/deployment.yaml (updated)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: linkding
  namespace: linkding
spec:
  replicas: 1
  selector:
    matchLabels:
      app: linkding
  template:
    metadata:
      labels:
        app: linkding
    spec:
      containers:
      - name: linkding
        image: sissbruecker/linkding:1.2.0  # Updated from latest to specific version
        # ... rest of the container spec remains the same
```

2. **Commit and push changes**:

```bash
git add kustomize/linkding/deployment.yaml
git commit -m "Update linkding to version 1.2.0"
git push
```

3. **Monitor the update**:

```bash
flux get kustomization linkding
kubectl get pods -n linkding
```

## Troubleshooting

### Example: Debugging Linkding Connection Issues

1. **Check pod status**:

```bash
bb7_pods_list_in_namespace namespace=linkding
```

2. **View logs from the pod**:

```bash
bb7_pods_log name=linkding-758496756-a2b3c namespace=linkding
```

3. **Check if ingress is configured correctly**:

```bash
bb7_resources_get apiVersion=networking.k8s.io/v1 kind=Ingress name=linkding namespace=linkding
```

4. **Check if Flux has reconciled the latest changes**:

```bash
bb7_reconcile_flux_kustomization name=linkding namespace=flux-system with_source=true
```

5. **Make necessary corrections in repository files**:

```bash
bb7_edit_file path=/home/dave/src/k3s-config/kustomize/linkding/ingress.yaml
```

6. **Commit and push changes**:

```bash
bb7_git_add repo_path=/home/dave/src/k3s-config files=["kustomize/linkding/ingress.yaml"]
bb7_git_commit repo_path=/home/dave/src/k3s-config message="Fix linkding ingress configuration"
```

Remember: The GitOps workflow means we always make changes to the repository, not directly to the cluster. Any temporary debugging changes should be documented and then properly implemented through the repository.
