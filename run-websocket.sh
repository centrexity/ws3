#!/bin/sh
set -eu

binary=/program/Admins.net_ws
token_file=/config/ws.admins.net/gateway-token
runtime_token=/run/ws3-gateway-token
origin=${ORIGIN_PROTOCOL:-http}
api_url=${WS3_API_URL:-https://api.admins.net/v1/gateway/}
gateway_id=${WS3_GATEWAY_ID:-ws-1}

[ -x "$binary" ] || { echo "Missing executable $binary" >&2; exit 64; }
[ -r "$token_file" ] || { echo "Missing gateway token $token_file" >&2; exit 64; }
# Pass exactly the 64 hex bytes to older gateway executables too. Allow only
# whitespace after the key, such as a pasted CRLF or final newline.
umask 077
head -c 64 "$token_file" > "$runtime_token"
if [ "$(wc -c < "$runtime_token")" -ne 64 ] || ! LC_ALL=C grep -Eq '^[0-9a-f]{64}$' "$runtime_token" \
    || [ "$(tail -c +65 "$token_file" | LC_ALL=C tr -d '[:space:]' | wc -c)" -ne 0 ]; then
    echo 'Gateway token must contain 64 lowercase hex characters followed only by whitespace.' >&2
    exit 64
fi
case "$origin" in
    http) ;;
    tls)
        cert_dir=/config/ws.admins.net/certs
        mkdir -p "$cert_dir"
        if [ ! -s "$cert_dir/server.pem" ] || [ ! -s "$cert_dir/server-key.pem" ]; then
            openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
                -subj '/CN=ws.admins.net' \
                -keyout "$cert_dir/server-key.pem" -out "$cert_dir/server.pem" >/dev/null 2>&1
            chmod 0600 "$cert_dir/server-key.pem"
        fi
        ;;
    *) echo 'ORIGIN_PROTOCOL must be http or tls' >&2; exit 64 ;;
esac

cd /config/ws.admins.net
exec "$binary" --origin="$origin" --token-file="$runtime_token" --api-url="$api_url" --gateway-id="$gateway_id"
