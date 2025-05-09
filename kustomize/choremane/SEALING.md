# Sealing OAuth Secrets for Choremane

This document explains how to seal the OAuth secrets for the Choremane application.

## Prerequisites

- `kubeseal` CLI tool installed
- Access to the Kubernetes cluster with SealedSecrets controller
- The public key from the SealedSecrets controller

## Sealing the OAuth Client Secret

1. First, fetch the public key from the SealedSecrets controller:

```bash
kubeseal --fetch-cert > /tmp/sealed-secrets-public-key.pem
```

2. Run the `seal-oauth-secret.sh` script to seal the OAuth client secret:

```bash
./scripts/seal-oauth-secret.sh
```

This script will:
- Create SealedSecret for the base configuration
- Create environment-specific SealedSecrets for staging and production
- Remove the unsealed secret file for security
- Update the relevant kustomization.yaml files

## Manual Sealing

If you need to manually seal the secrets, follow these steps:

1. Create an unsealed secret file:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: choremane-oauth-secret
  namespace: choremane-staging
type: Opaque
stringData:
  OAUTH_CLIENT_SECRET: "your-secure-secret-here"
```

2. Seal the secret using kubeseal:

```bash
kubeseal --format=yaml \
  --cert=/tmp/sealed-secrets-public-key.pem \
  < unsealed-secret.yaml \
  > oauth-secret-sealed.yaml
```

3. Repeat for each target namespace (choremane, choremane-staging, choremane-prod)

4. Include the sealed secrets in the appropriate kustomization files

## Verification

To verify that the SealedSecrets can be decrypted by the controller:

```bash
kubectl apply -f oauth-secret-sealed.yaml --dry-run=server
```

If the SealedSecret is valid, the controller will accept it without errors.

## Security Considerations

- Never commit unsealed secrets to git
- Use different secrets for different environments
- Rotate secrets periodically for security
- Back up the SealedSecrets controller private key
