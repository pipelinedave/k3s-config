#!/bin/bash
# Deploy Dex and update Choremane with authentication

set -e  # Exit on any error

# 1. Create the dex namespace if it doesn't exist
kubectl get namespace dex &> /dev/null || kubectl create namespace dex

# 2. Apply Dex Google credentials secret
kubectl apply -f /home/dave/src/k3s-config/kustomize-incomplete/dex/dex-google-credentials-secret.yaml

# 3. Deploy Dex using kustomize
kubectl apply -k /home/dave/src/k3s-config/kustomize-incomplete/dex

# 4. Wait for Dex deployment to be ready
echo "Waiting for Dex to be ready..."
kubectl -n dex rollout status deployment dex

# 5. Apply Choremane authentication updates
kubectl apply -k /home/dave/src/k3s-config/kustomize/choremane-staging

# 6. Wait for Choremane backend deployment to be ready
echo "Waiting for Choremane backend to be ready..."
kubectl -n choremane-staging rollout status deployment choremane-backend

echo ""
echo "Deployment complete!"
echo "Dex is available at: https://dex.stillon.top"
echo "Choremane is available at: https://chores.stillon.top"
echo ""
echo "Authentication should now be working. Users will be redirected to Google login through Dex."
