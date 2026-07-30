#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="${ACCOUNT_ID:-a2cf92efff3b498bce86124be2ce4352}"
PROJECT_NAME="${PROJECT_NAME:-novaestudio}"
ZONE_NAME="${ZONE_NAME:-nvaestudio.com}"
HOSTNAME="${HOSTNAME:-www.nvaestudio.com}"
PAGES_TARGET="${PAGES_TARGET:-novaestudio.pages.dev}"
KEYCHAIN_SERVICE="${KEYCHAIN_SERVICE:-cloudflare-dns-api-token}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need curl
need jq

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  if command -v security >/dev/null 2>&1; then
    CLOUDFLARE_API_TOKEN="$(security find-generic-password -s "$KEYCHAIN_SERVICE" -w 2>/dev/null || true)"
  fi
fi

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  cat >&2 <<EOF
Missing Cloudflare DNS API token.

Create one Cloudflare API token with:
  Permissions: Zone / DNS / Edit
  Zone Resources: Include / Specific zone / ${ZONE_NAME}

Then store it once in macOS Keychain:
  security add-generic-password -a "$USER" -s "$KEYCHAIN_SERVICE" -w 'PASTE_TOKEN_HERE' -U

Or run this script with:
  CLOUDFLARE_API_TOKEN='PASTE_TOKEN_HERE' $0
EOF
  exit 2
fi

api() {
  local method="$1"
  local path="$2"
  local data="${3:-}"

  if [[ -n "$data" ]]; then
    curl -fsS \
      -X "$method" "https://api.cloudflare.com/client/v4${path}" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H "Content-Type: application/json" \
      --data "$data"
  else
    curl -fsS \
      -X "$method" "https://api.cloudflare.com/client/v4${path}" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H "Content-Type: application/json"
  fi
}

echo "Checking Cloudflare token..."
token_status="$(api GET "/user/tokens/verify" | jq -r '.success')"
if [[ "$token_status" != "true" ]]; then
  echo "Cloudflare token verification failed." >&2
  exit 3
fi

echo "Finding zone ${ZONE_NAME}..."
zone_response="$(api GET "/zones?name=${ZONE_NAME}")"
zone_id="$(jq -r '.result[0].id // empty' <<<"$zone_response")"
if [[ -z "$zone_id" ]]; then
  echo "Zone not found in Cloudflare account: ${ZONE_NAME}" >&2
  exit 4
fi

echo "Adding ${HOSTNAME} to Pages project ${PROJECT_NAME}..."
set +e
pages_add_response="$(api POST "/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/domains" "{\"name\":\"${HOSTNAME}\"}" 2>&1)"
pages_add_code="$?"
set -e
if [[ "$pages_add_code" -ne 0 ]]; then
  if grep -qi "already" <<<"$pages_add_response"; then
    echo "Pages domain already exists."
  else
    echo "$pages_add_response" >&2
    exit 5
  fi
fi

echo "Upserting DNS CNAME ${HOSTNAME} -> ${PAGES_TARGET}..."
records_response="$(api GET "/zones/${zone_id}/dns_records?type=CNAME&name=${HOSTNAME}")"
record_id="$(jq -r '.result[0].id // empty' <<<"$records_response")"
record_payload="$(jq -cn \
  --arg type "CNAME" \
  --arg name "$HOSTNAME" \
  --arg content "$PAGES_TARGET" \
  '{type:$type,name:$name,content:$content,ttl:1,proxied:true}')"

if [[ -n "$record_id" ]]; then
  api PUT "/zones/${zone_id}/dns_records/${record_id}" "$record_payload" >/dev/null
  echo "DNS record updated."
else
  api POST "/zones/${zone_id}/dns_records" "$record_payload" >/dev/null
  echo "DNS record created."
fi

echo "Current DNS:"
if command -v dig >/dev/null 2>&1; then
  dig +short CNAME "$HOSTNAME" || true
fi

echo "Pages domain status:"
api GET "/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/domains" |
  jq -r --arg hostname "$HOSTNAME" '
    .result[]
    | select(.name == $hostname)
    | {
        name,
        status,
        verification: .verification_data.status,
        verification_error: .verification_data.error_message,
        validation: .validation_data.status
      }'

echo "Done. Open: https://${HOSTNAME}"
