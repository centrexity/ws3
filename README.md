# ws3

`ws3` is an Unraid friendly Docker image for the Admins.net WebSocket gateway. It follows the [`centrexity/s3`](https://github.com/centrexity/s3) container's Alpine, Supervisor, SSH, and Cloudflare Tunnel layout. It has no Apache, PHP, MariaDB, or cron service. The image contains no gateway executable or credentials: those live on mounted volumes.

## Unraid container settings

| Setting | Value |
| --- | --- |
| Name | `centrexity-ws3` |
| Repository after publishing | `ghcr.io/centrexity/ws3:main` |
| Network | Bridge |
| Host ports | None for the WebSocket service; map SSH port 22 only if needed |
| Config volume | Host `/mnt/user/appdata/centrexity-ws3/config` → container `/config` |
| Program volume | Host `/mnt/user/appdata/centrexity-ws3/program` → container `/program` |

Place the compiled gateway at `/mnt/user/appdata/centrexity-ws3/program/Admins.net_ws` and make it executable. Build it from the Admins.net workspace's `Admins.net_ws` project with `./build.sh`; the image never builds or copies it. Place its private API gateway credential at `/mnt/user/appdata/centrexity-ws3/config/ws.admins.net/gateway-token`. Keep that file readable only by the service administrator. The current gateway refuses to start without a valid credential. This is a separate credential from the Cloudflare tunnel token. The first gateway is registered on the API server as `ws-1`. Additional gateways use distinct IDs and tokens created with `Admins.net_api/scripts/gateway-keys.php`; see the API project's deployment guide. Never invent or commit a replacement token, because the API stores the matching hash.

The mounted gateway token file may end with a pasted newline, CRLF, or trailing whitespace. The launcher passes a private runtime copy containing only the 64 hex characters, including for older gateway executables. Whitespace within the key or any other trailing data is rejected.

Cloudflare continues to read its tunnel token from `/config/cloudflared/token.txt`, as in `s3`. Put the **ws3 tunnel's** token at `/mnt/user/appdata/centrexity-ws3/config/cloudflared/token.txt`. The image does not create, rotate, or change the tunnel or its public hostname configuration. The existing route for `ws.admins.net` must target `http://localhost:8080` in the container for the default origin mode. Public clients keep using `wss://ws.admins.net/`. Use the token for the intended WS tunnel; reusing an unrelated server's tunnel token would attach this container to that tunnel.

The default origin mode is HTTP on port 8080. Set `ORIGIN_PROTOCOL=tls` to run the gateway on HTTPS port 8443; the route must already target that origin. TLS mode uses `/config/ws.admins.net/certs/server.pem` and `server-key.pem`, generating a self-signed pair on the volume if absent. The launcher passes `https://api.admins.net/v1/gateway/` explicitly to the current gateway; set `WS3_API_URL` only for another HTTPS API endpoint.

`WS3_GATEWAY_ID` defaults to `ws-1`. Set it to the ID assigned to another server, and mount that server's matching token at `/config/ws.admins.net/gateway-token`. Revoking an ID on the API server immediately rejects that gateway without affecting other IDs.

SSH host keys persist under `/config/ssh/host_keys/`. An optional `/config/ssh/sshd_config` replaces the default password-disabled configuration. An optional `/config/ssh/setup.sh` runs at startup, following `s3`'s custom setup convention. No host ports are published by the image itself.

Supervisor manages the gateway, Cloudflare Tunnel, and SSH. It restarts the gateway whenever it exits, including a crash during its first second. Missing required volume files stop the container during startup so the configuration error is visible. The [GitHub workflow](.github/workflows/build.yml) publishes the image to GitHub Container Registry on pushes to `main`, using the same pattern as `s3`.
