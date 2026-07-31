#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-/etc/porkbun-ddns.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE" >&2
  echo "Create it with PORKBUN_API_KEY, PORKBUN_SECRET_API_KEY, DOMAIN, and RECORDS." >&2
  exit 1
fi

# shellcheck source=/etc/porkbun-ddns.env
source "$ENV_FILE"

: "${PORKBUN_API_KEY:?PORKBUN_API_KEY is required}"
: "${PORKBUN_SECRET_API_KEY:?PORKBUN_SECRET_API_KEY is required}"
: "${DOMAIN:?DOMAIN is required (example: stillon.top)}"

RECORDS="${RECORDS:-chores share}"
TTL="${TTL:-600}"
IP_PROVIDER_URL="${IP_PROVIDER_URL:-https://api.ipify.org}"

read -r -a records_array <<<"$RECORDS"

# Safety guard: this updater is intended for explicit host cutovers only.
# It must not overwrite wildcard or apex records unless explicitly allowed.
for record in "${records_array[@]}"; do
  case "$record" in
    "*"|"@")
      if [[ "${ALLOW_WILDCARD_UPDATES:-0}" != "1" ]]; then
        echo "Refusing to update reserved record '$record'." >&2
        echo "Set ALLOW_WILDCARD_UPDATES=1 only when you intentionally want to modify wildcard/apex records." >&2
        exit 1
      fi
      ;;
  esac
done

current_ip="$(curl -4fsS "$IP_PROVIDER_URL")"

if [[ ! "$current_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "Invalid IPv4 from provider '$IP_PROVIDER_URL': $current_ip" >&2
  exit 1
fi

update_record() {
  local record_label="$1"
  local endpoint_name

  if [[ "$record_label" == "@" ]]; then
    endpoint_name="$DOMAIN"
  else
    endpoint_name="${record_label}.${DOMAIN}"
  fi

  local check_endpoint="https://api.porkbun.com/api/json/v3/dns/retrieveByNameType/${DOMAIN}/A/${endpoint_name}"
  local check_payload
  check_payload="$(cat <<JSON
{"apikey":"${PORKBUN_API_KEY}","secretapikey":"${PORKBUN_SECRET_API_KEY}"}
JSON
)"

  local check_response
  check_response="$(curl -fsS -H 'Content-Type: application/json' -d "$check_payload" "$check_endpoint")"

  local endpoint payload response

  # Porkbun editByNameType only updates existing records. If none exist (e.g. wildcard-only zones), create one.
  if printf '%s' "$check_response" | grep -q '"records":\[\]'; then
    endpoint="https://api.porkbun.com/api/json/v3/dns/create/${DOMAIN}"
    payload="$(cat <<JSON
{"apikey":"${PORKBUN_API_KEY}","secretapikey":"${PORKBUN_SECRET_API_KEY}","name":"${record_label}","type":"A","content":"${current_ip}","ttl":"${TTL}"}
JSON
)"
  else
    endpoint="https://api.porkbun.com/api/json/v3/dns/editByNameType/${DOMAIN}/A/${endpoint_name}"
    payload="$(cat <<JSON
{"apikey":"${PORKBUN_API_KEY}","secretapikey":"${PORKBUN_SECRET_API_KEY}","content":"${current_ip}"}
JSON
)"
  fi

  response="$(curl -fsS -H 'Content-Type: application/json' -d "$payload" "$endpoint")"

  local status
  status="$(printf '%s' "$response" | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"

  if [[ "$status" != "SUCCESS" ]]; then
    echo "Porkbun update failed for '${record_label}.${DOMAIN}'" >&2
    echo "$response" >&2
    return 1
  fi

  if [[ "$record_label" == "@" ]]; then
    echo "Updated ${DOMAIN} A -> ${current_ip}"
  else
    echo "Updated ${record_label}.${DOMAIN} A -> ${current_ip}"
  fi
}

for record in "${records_array[@]}"; do
  update_record "$record"
done
