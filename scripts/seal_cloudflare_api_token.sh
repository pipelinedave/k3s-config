#!/usr/bin/env bash
#
# Erzeugt eine SealedSecret fuer den Cloudflare API-Token (DNS01 / cert-manager).
#
# Benoetigt: einen Cloudflare API-Zugriffstoken mit Scope "Zone -> DNS -> Edit"
# fuer die Zone stillon.top  (NICHT der Tunnel-Token!).
#
# Verwendung:
#   CLOUDFLARE_API_TOKEN='<token aus Cloudflare Dashboard>' ./scripts/seal_cloudflare_api_token.sh
#
# Ausgabe: kustomize/cloudflare-dns01/cloudflare-api-token-sealed.yaml
# danach dem cert-manager-Kustomization hinzufuegen ODER vorgehen wie im Tunnel-Skript.
set -euo pipefail

: "${CLOUDFLARE_API_TOKEN:?Set CLOUDFLARE_API_TOKEN (Zone DNS:Edit fuer stillon.top) before running.}"

OUTPUT_PATH="${1:-kustomize/cloudflare-dns01/cloudflare-api-token-sealed.yaml}"
NAMESPACE="${NAMESPACE:-cert-manager}"
CONTROLLER_NAME="${CONTROLLER_NAME:-sealed-secrets-controller}"
CONTROLLER_NAMESPACE="${CONTROLLER_NAMESPACE:-kube-system}"
KUBE_CONFIG_PATH="${KUBE_CONFIG_PATH:-$HOME/.kube/config-nucy}"

if [[ -z "${KUBECONFIG:-}" && -f "$KUBE_CONFIG_PATH" ]]; then
  export KUBECONFIG="$KUBE_CONFIG_PATH"
fi

if ! kubectl -n "$CONTROLLER_NAMESPACE" get deploy "$CONTROLLER_NAME" >/dev/null 2>&1; then
  echo "Cannot access Sealed Secrets controller '$CONTROLLER_NAME' in namespace '$CONTROLLER_NAMESPACE'." >&2
  echo "Set KUBECONFIG (or KUBE_CONFIG_PATH) to a cluster context that can read kube-system resources." >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"

kubectl -n "$NAMESPACE" create secret generic cloudflare-api-token \
  --from-literal=api-token="$CLOUDFLARE_API_TOKEN" \
  --dry-run=client -o yaml \
  | kubeseal \
      --controller-name "$CONTROLLER_NAME" \
      --controller-namespace "$CONTROLLER_NAMESPACE" \
      --format yaml > "$OUTPUT_PATH"

echo "Wrote sealed secret manifest to $OUTPUT_PATH"
echo "Add '$OUTPUT_PATH' to the cert-manager kustomization resources, then commit and reconcile."
