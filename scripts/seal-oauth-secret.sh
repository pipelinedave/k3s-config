#!/bin/bash
# Script to seal the Choremane OAuth secret

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

echo "Sealing Choremane OAuth secret..."

# Create SealedSecret for staging environment
kubeseal --format yaml \
  < kustomize/choremane/base/oauth-secret-unsealed.yaml \
  > kustomize/choremane/base/oauth-secret-sealed.yaml

echo "Created SealedSecret at kustomize/choremane/base/oauth-secret-sealed.yaml"

# Create namespace-specific sealed secrets for staging and production
kubeseal --format yaml \
  --namespace choremane-staging \
  < <(sed 's/namespace: choremane/namespace: choremane-staging/' kustomize/choremane/base/oauth-secret-unsealed.yaml) \
  > kustomize/choremane/overlays/staging/oauth-secret-sealed.yaml

echo "Created staging SealedSecret at kustomize/choremane/overlays/staging/oauth-secret-sealed.yaml"

kubeseal --format yaml \
  --namespace choremane-prod \
  < <(sed 's/namespace: choremane/namespace: choremane-prod/' kustomize/choremane/base/oauth-secret-unsealed.yaml) \
  > kustomize/choremane/overlays/prod/oauth-secret-sealed.yaml

echo "Created production SealedSecret at kustomize/choremane/overlays/prod/oauth-secret-sealed.yaml"

# Remove the unsealed secret file for security
rm kustomize/choremane/base/oauth-secret-unsealed.yaml

echo "Done! SealedSecrets created successfully."
echo "Please update the respective kustomization.yaml files to include the new sealed secret."
