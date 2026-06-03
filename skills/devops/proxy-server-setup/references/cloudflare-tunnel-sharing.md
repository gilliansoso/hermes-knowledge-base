# Sharing Proxy Configs via Cloudflare Quick Tunnel

## Why This Pattern

After setting up a VLESS+REALITY proxy on a VPS, the user needs to get client config files to their devices (iPhone, Windows laptop, etc.). Common constraints:
- No SCP client on the target device (iPhone)
- QR code requires visual access (can't scan from headless server)
- User doesn't want to install additional file transfer tools
- VPS firewall only allows port 22 (SSH) and 443 (Xray)

Cloudflare Tunnel solves this by creating a public HTTPS URL that proxies to a local HTTP server, without opening any VPS firewall ports.

## Architecture

```
[User's Browser] 
    ↓ HTTPS (Cloudflare edge)
Cloudflare Network
    ↓ QUIC tunnel (outbound from VPS)
cloudflared (on VPS)
    ↓ HTTP
[Python HTTP Server :18888]
    ↓ serves static files
Config files (JSON, HTML, PNG)
```

## Known Quirks & Their Fixes

### Port 18888 Occupied After Session Ends

The Python HTTP server from a previous session may still be running and holding port 18888.

**Detection**: `curl http://127.0.0.1:18888/` fails or returns wrong content.

**Fix**:
```bash
fuser -k 18888/tcp 2>/dev/null
sleep 1
# Then restart the server
```

### Old cloudflared Process Still Running

The previous cloudflared tunnel may still be alive but is connected to a dead origin (since the HTTP server was killed). It keeps serving 502 errors.

**Detection**: Tunnel URL returns HTTP 502, but local HTTP server works fine on `http://127.0.0.1:18888/`.

**Fix**: Kill and restart cloudflared:
```bash
pkill -f "cloudflared tunnel" 2>/dev/null
/tmp/cloudflared tunnel --url http://127.0.0.1:18888 --no-autoupdate &
```

### Tunnel URL Changed

Every restart of cloudflared generates a new trycloudflare.com URL. The old one immediately returns 404.

**Mitigation**: Tell the user explicitly that the URL changes each session. For a permanent URL, recommend a named Cloudflare Tunnel (requires Cloudflare account + domain).

### Cloudflare Propagation Delay

After starting cloudflared, the tunnel URL may return 502 for 5-15 seconds while Cloudflare's edge propagates the route.

**Workaround**: Wait 8-10 seconds after starting cloudflared before testing. Use a retry loop:
```bash
for i in 1 2 3; do
  result=$(curl -s -o /dev/null -w "%{http_code}" "https://TUNNEL/FILE" 2>/dev/null)
  [ "$result" = "200" ] && break
  sleep 5
done
```

## Verification Checklist

1. Local HTTP server is up: `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18888/FILE` → `200`
2. cloudflared process is running (check via `process poll` or `ps aux | grep cloudflared`)
3. cloudflared log shows the tunnel URL (look for "Your quick Tunnel has been created!")
4. Remote tunnel URL returns 200: `curl -s -o /dev/null -w "%{http_code}" https://TUNNEL/FILE` → `200`