#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo install -m 0755 "$SCRIPT_DIR/porkbun_ddns_update.sh" /usr/local/bin/porkbun-ddns-update
sudo install -m 0644 "$SCRIPT_DIR/systemd/porkbun-ddns-update.service" /etc/systemd/system/porkbun-ddns-update.service
sudo install -m 0644 "$SCRIPT_DIR/systemd/porkbun-ddns-update.timer" /etc/systemd/system/porkbun-ddns-update.timer

if [[ ! -f /etc/porkbun-ddns.env ]]; then
  sudo tee /etc/porkbun-ddns.env >/dev/null <<'EOF'
# Porkbun API credentials
PORKBUN_API_KEY=replace-me
PORKBUN_SECRET_API_KEY=replace-me

# Zone and records to update (space-separated labels)
DOMAIN=stillon.top
RECORDS="chores share"

# Optional settings
TTL=600
IP_PROVIDER_URL=https://api.ipify.org
EOF
  sudo chmod 600 /etc/porkbun-ddns.env
fi

sudo systemctl daemon-reload
sudo systemctl enable --now porkbun-ddns-update.timer

echo "Installed porkbun-ddns-update systemd timer."
echo "Edit /etc/porkbun-ddns.env with real Porkbun API credentials, then run:"
echo "  sudo systemctl start porkbun-ddns-update.service"
