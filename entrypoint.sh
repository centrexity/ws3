#!/bin/sh
set -eu

echo 'Starting WS3'
mkdir -p /config/cloudflared /config/ws.admins.net /config/ssh /run/sshd

if [ ! -x /program/Admins.net_ws ]; then
    echo 'Missing executable /program/Admins.net_ws on the program volume.' >&2
    exit 64
fi
if [ ! -r /config/ws.admins.net/gateway-token ]; then
    echo 'Missing /config/ws.admins.net/gateway-token on the config volume.' >&2
    exit 64
fi

if [ ! -s /config/cloudflared/token.txt ]; then
    echo 'Missing Cloudflare token at /config/cloudflared/token.txt.' >&2
    exit 64
fi

/usr/local/bin/persist-ssh-host-keys.sh
if [ -f /config/ssh/sshd_config ]; then
    cp /config/ssh/sshd_config /etc/ssh/sshd_config
else
    cat > /etc/ssh/sshd_config <<'EOF'
Port 22
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
UsePAM no
Subsystem sftp internal-sftp
EOF
fi
if [ -f /config/ssh/setup.sh ]; then
    /bin/sh /config/ssh/setup.sh
fi
/usr/sbin/sshd -t
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
