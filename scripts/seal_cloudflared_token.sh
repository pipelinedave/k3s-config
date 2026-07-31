#!/usr/bin/env bash
set -euo pipefail

: "${TUNNEL_TOKEN:?Set TUNNEL_TOKEN to your Cloudflare tunnel token before running this script.}"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required but not found in PATH." >&2
  exit 1
fi

if ! command -v kubeseal >/dev/null 2>&1; then
  echo "kubeseal is required but not found in PATH." >&2
  exit 1
fi

OUTPUT_PATH="${1:-kustomize/cloudflare-tunnel/cloudflared-token-sealed.yaml}"
NAMESPACE="${NAMESPACE:-kube-system}"
CONTROLLER_NAME="${CONTROLLER_NAME:-sealed-secrets-controller}"
CONTROLLER_NAMESPACE="${CONTROLLER_NAMESPACE:-kube-system}"
KUBE_CONFIG_PATH="${KUBE_CONFIG_PATH:-$HOME/.kube/config-nucy}"

# Default to nucy kubeconfig if caller did not provide KUBECONFIG.
if [[ -z "${KUBECONFIG:-}" && -f "$KUBE_CONFIG_PATH" ]]; then
  export KUBECONFIG="$KUBE_CONFIG_PATH"
fi

if ! kubectl -n "$CONTROLLER_NAMESPACE" get deploy "$CONTROLLER_NAME" >/dev/null 2>&1; then
  echo "Cannot access Sealed Secrets controller '$CONTROLLER_NAME' in namespace '$CONTROLLER_NAMESPACE'." >&2
  echo "Set KUBECONFIG (or KUBE_CONFIG_PATH) to a cluster context that can read kube-system resources." >&2
  exit 1
fi

kubectl -n "$NAMESPACE" create secret generic cloudflared-tunnel-token \
  --from-literal=TUNNEL_TOKEN="$TUNNEL_TOKEN" \
  --dry-run=client -o yaml \
  | kubeseal \
      --controller-name "$CONTROLLER_NAME" \
      --controller-namespace "$CONTROLLER_NAMESPACE" \
      --format yaml > "$OUTPUT_PATH"

echo "Wrote sealed secret manifest to $OUTPUT_PATH"
echo "Add this file to kustomize/cloudflare-tunnel/kustomization.yaml resources, then commit and reconcile." 