#!/bin/sh
set -eu

binary=/program/Admins.net_ws
token_file=/config/ws.admins.net/gateway-token
origin=${ORIGIN_PROTOCOL:-http}
api_url=${WS3_API_URL:-https://api.admins.net/v1/gateway/}

[ -x "$binary" ] || { echo "Missing executable $binary" >&2; exit 64; }
[ -r "$token_file" ] || { echo "Missing gateway token $token_file" >&2; exit 64; }
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
exec "$binary" --origin="$origin" --token-file="$token_file" --api-url="$api_url"
