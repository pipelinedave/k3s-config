#!/usr/bin/env bash
set -euo pipefail

: "${TUNNEL_TOKEN:?Set TUNNEL_TOKEN to your Cloudflare tunnel token before running this script.}"

OUTPUT_PATH="${1:-kustomize/cloudflare-tunnel/cloudflared-token-sealed.yaml}"
NAMESPACE="${NAMESPACE:-kube-system}"
CONTROLLER_NAME="${CONTROLLER_NAME:-sealed-secrets-controller}"
CONTROLLER_NAMESPACE="${CONTROLLER_NAMESPACE:-kube-system}"

kubectl -n "$NAMESPACE" create secret generic cloudflared-tunnel-token \
  --from-literal=TUNNEL_TOKEN="$TUNNEL_TOKEN" \
  --dry-run=client -o yaml \
  | kubeseal \
      --controller-name "$CONTROLLER_NAME" \
      --controller-namespace "$CONTROLLER_NAMESPACE" \
      --format yaml > "$OUTPUT_PATH"

echo "Wrote sealed secret manifest to $OUTPUT_PATH"
echo "Add this file to kustomize/cloudflare-tunnel/kustomization.yaml resources, then commit and reconcile." 