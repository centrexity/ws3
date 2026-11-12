#!/bin/sh
set -eu

token_file=/config/cloudflared/token.txt
[ -r "$token_file" ] || { echo "Missing $token_file" >&2; exit 64; }
token=$(tr -d '\r\n[:space:]' < "$token_file")
if [ -z "$token" ] || [ "$token" = YOUR_CLOUDFLARE_TOKEN_HERE ]; then
    echo "Cloudflare token is not configured in $token_file" >&2
    exit 64
fi
exec /usr/bin/cloudflared tunnel --no-autoupdate run --token "$token"
