#!/usr/bin/env bash
#
# QR MPM Generate load test — auto-fetches a fresh access token then fires N requests.
#
# Usage:
#   ./qr-load-test.sh [-n <count>] [-s <start>] [-c <concurrency>] [-u <base_url>]
#
# Examples:
#   ./qr-load-test.sh                        # 10 requests starting at 100
#   ./qr-load-test.sh -n 50 -s 200          # 50 requests starting at 200
#   ./qr-load-test.sh -n 1001 -s 500 -c 50  # 1001 requests, 50 at a time

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── defaults ──────────────────────────────────────────────────────────────────
COUNT=10
START=100
CONCURRENCY=1
BASE_URL="http://localhost:8000"
CLIENT_KEY="019db976-90de-7659-9339-1ca3e184de80"
PRIVATE_KEY_FILE="$SCRIPT_DIR/merchant_private_key.pem"
STORE_ID="ID2025091100003"
AMOUNT="100000.00"

# ── args ──────────────────────────────────────────────────────────────────────
while getopts "n:s:c:u:" opt; do
  case $opt in
    n) COUNT="$OPTARG" ;;
    s) START="$OPTARG" ;;
    c) CONCURRENCY="$OPTARG" ;;
    u) BASE_URL="$OPTARG" ;;
    *) echo "Usage: $0 [-n count] [-s start] [-c concurrency] [-u base_url]"; exit 1 ;;
  esac
done

# ── fetch fresh access token ───────────────────────────────────────────────────
echo "==> Fetching access token..."

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
SIGN_PAYLOAD="${CLIENT_KEY}|${TIMESTAMP}"
SIGNATURE=$(echo -n "$SIGN_PAYLOAD" | openssl dgst -sha256 -sign "$PRIVATE_KEY_FILE" | openssl base64 -A)

TOKEN=$(curl -s -X POST "$BASE_URL/v1.0/access-token/b2b" \
  -H "Content-Type: application/json" \
  -H "X-CLIENT-KEY: $CLIENT_KEY" \
  -H "X-TIMESTAMP: $TIMESTAMP" \
  -H "X-SIGNATURE: $SIGNATURE" \
  -d '{"grantType":"client_credentials"}' | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

if [[ -z "$TOKEN" ]]; then
  echo "Error: failed to fetch access token"
  exit 1
fi

echo "==> Token acquired (expires in 900s)"

# ── fire requests ──────────────────────────────────────────────────────────────
ENDPOINT="$BASE_URL/v1.0/qr/qr-mpm-generate"
PREFIX=$(date +%Y%m%d)

fire() {
  local i=$1
  local ref
  ref="${PREFIX}$(printf '%014d' "$i")"

  local timestamp external_id
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
  external_id="${i}$(date +%s%3N)"

  local body
  body=$(cat <<EOF
{
  "partnerReferenceNo": "$ref",
  "amount": { "value": "$AMOUNT", "currency": "IDR" },
  "storeId": "$STORE_ID",
  "validityPeriod": 900,
  "additionalInfo": { "deviceId": "device001", "channel": "mobile" }
}
EOF
)

  local response http_code body_out
  response=$(curl -s -w "\n%{http_code}" \
    -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-TIMESTAMP: $timestamp" \
    -H "X-EXTERNAL-ID: $external_id" \
    -H "X-SIGNATURE: dummy-signature" \
    -d "$body")

  http_code=$(echo "$response" | tail -n 1)
  body_out=$(echo "$response" | sed '$d')

  if [[ "$http_code" != "200" ]]; then
    echo "[$i] ref=$ref → $http_code | $body_out"
  else
    echo "[$i] ref=$ref → $http_code"
  fi
}

export -f fire
export TOKEN ENDPOINT PREFIX AMOUNT STORE_ID

echo "==> Firing $COUNT requests (start=$START, concurrency=$CONCURRENCY)"
echo ""

seq "$START" "$((START + COUNT - 1))" | xargs -P "$CONCURRENCY" -I{} bash -c 'fire "$@"' _ {}

echo ""
echo "==> Done"
