---
name: proxy-server-setup
category: devops
tags: [xray, vless, reality, proxy, vpn, aws-lightsail, shadowrocket]
description: >
  Set up a VLESS+REALITY proxy server with Xray-core on a cloud VPS.
  Covers installation, key generation, server config, systemd permissions,
  client configs for Windows (v2rayN) and iPhone (Shadowrocket),
  and cloud firewall setup.
usage: |
  Load this skill when the user asks to set up a proxy/VPN server,
  configure Xray-core, create a VLESS+REALITY connection, or bypass
  network restrictions with a self-hosted proxy on a cloud VPS.
triggers:
  - "set up a proxy server"
  - "install xray"
  - "vless reality"
  - "configure vpn on vps"
  - "bypass network restrictions"
  - "self-hosted proxy"
---

# VLESS+REALITY Proxy Server Setup

Deploy a VLESS+REALITY proxy using Xray-core, masquerading as `apple.com` TLS traffic. This is the most secure and undetectable proxy protocol available — traffic is indistinguishable from a regular HTTPS connection to Apple.

## Prerequisites

- Cloud VPS (AWS Lightsail / EC2 / DigitalOcean / Vultr) with **sudo/root access**
- Ubuntu/Debian (this workflow was tested on Ubuntu 24.04)
- Port 443 free on the server (or choose another port)
- **Cloud firewall** must allow inbound TCP on the chosen port (see references/cloud-firewall.md)

## Step-by-Step

### 1. Install Xray-core

```bash
sudo bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"
```

This installs Xray to `/usr/local/bin/xray`, config to `/usr/local/etc/xray/config.json`.

### 2. Generate REALITY Key Pair

```bash
sudo /usr/local/bin/xray x25519
```

Keep the output — you need both **PrivateKey** (server) and **PublicKey** (client).

### 3. Generate UUID and ShortId

```bash
uuidgen                                           # client UUID
openssl rand -hex 8                               # shortId (8 bytes hex)
```

### 4. Write Server Config

Replace `config.json` at `/usr/local/etc/xray/config.json` with the VLESS+REALITY template. See `templates/xray-server-config.json` for the full structure.

Key config points:
- `port`: 443 (or your chosen port)
- `protocol`: vless
- `security`: reality
- `dest`: `apple.com:443` (the TLS target to masquerade as)
- `serverNames`: `["apple.com", "www.apple.com"]`
- `flow`: `xtls-rprx-vision` on the client

### 5. Fix Systemd Permission for Port < 1024

**PITFALL**: The default Xray systemd service runs as `nobody`. On most systems, `nobody` cannot bind to ports < 1024 even with `CAP_NET_BIND_SERVICE` ambient capabilities. The service starts but doesn't actually listen.

**Fix**: Override the service to run as `root`:

```bash
echo '[Service]
ExecStart=
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
User=root' | sudo tee /etc/systemd/system/xray.service.d/10-donot_touch_single_conf.conf > /dev/null

sudo systemctl daemon-reload
sudo systemctl restart xray
```

### Verify the Service

```bash
# Check status
systemctl status xray --no-pager

# Confirm port is listening
ss -tlnp | grep 443

# Test TLS handshake locally (REALITY returns apple.com's real cert)
timeout 3 bash -c 'echo | openssl s_client -connect 127.0.0.1:443 -servername apple.com 2>/dev/null' | openssl x509 -noout -subject
# Expected: CN = apple.com
```

### 6.5 SSH Private Key Handling (When User Provides Key for Server Access)

**Context**: User may need to provide an SSH private key for the agent to access the proxy server for diagnostics. Handle with care.

**Reliable write method**: Use `cat > file << 'KEYEOF'` heredoc via `terminal()`. The `write_file()` tool may corrupt PEM keys due to whitespace/formatting issues. Heredoc preserves exact content.

```bash
cat > /home/ubuntu/.ssh/server-key.pem << 'KEYEOF'
-----BEGIN RSA PRIVATE KEY-----
... (user pastes content) ...
-----END RSA PRIVATE KEY-----
KEYEOF
chmod 600 /home/ubuntu/.ssh/server-key.pem
```

**Cleanup**: Always remove the key from disk after use. `rm -f` may be blocked by security approval — if so, tell the user to manually delete it.

**PITFALL**: Do NOT paste keys into the terminal tool's inline string with `\n` escape sequences — the key line breaks get corrupted. Cat heredoc is the only reliable method.

**PITFALL**: Security approval required for key file write AND key file deletion. Both may be blocked. Have a fallback: if write is blocked, ask user to SSH in themselves and run diagnostic commands, then paste output.

### 6.6 Full Diagnostic Checklist (When Proxy Stops Working)

Run this on the server via SSH to triage connectivity issues:

```bash
echo '=== XRAY STATUS ==='
sudo systemctl status xray --no-pager 2>&1 | head -15
echo '=== PORT CHECK ==='
sudo ss -tlnp | grep 443
echo '=== YOUTUBE DIRECT (server, no proxy) ==='
curl -s -o /dev/null -w 'HTTP %{http_code} in %{time_total}s' --connect-timeout 10 https://www.youtube.com 2>&1
echo ''
echo '=== YOUTUBE via SOCKS5 proxy ==='
curl -s -o /dev/null -w 'HTTP %{http_code} in %{time_total}s' --connect-timeout 10 --socks5 127.0.0.1:1080 https://www.youtube.com 2>&1
echo ''
echo '=== FULL CONFIG ==='
sudo cat /usr/local/etc/xray/config.json | python3 -m json.tool
echo '=== RECENT LOGS ==='
sudo journalctl -u xray --no-pager -n 30
echo '=== LISTENING PORTS ==='
sudo ss -tlnp
echo '=== FIREWALL ==='
sudo iptables -L -n | head -20
```

#### Interpreting Results

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `HTTP 000` on SOCKS5, `HTTP 200` direct | No SOCKS5/HTTP inbound configured | Client is using VLESS directly; no SOCKS5 port exists. Normal unless user expects local proxy. |
| Xray not running | Service crashed or config error | `sudo journalctl -u xray --no-pager -n 50` for errors, fix config, `sudo systemctl restart xray` |
| Port 443 not listening | Nobody user can't bind low port, or systemd override missing | See Step 5 — ensure User=root override exists |
| Xray shows `changed on disk` warning | Config modified but daemon not reloaded | `sudo systemctl daemon-reload && sudo systemctl restart xray` |
| Direct YouTube fails from server | IP blocked by Google | Out of scope for Xray fix — consider different VPS IP or CDN relay |

**Routing rules missing**: A bare VLESS+REALITY config with no `routing` section sends ALL traffic directly (`freedom` outbound). This means the proxy works as a tunnel but doesn't do split tunneling. If the client shows `[direct]` for all domains and YouTube is slow/blocked, the issue is usually on the **client side** — check the client's routing rules, not the server.

### 7. Generate Client Configs

#### Windows (v2rayN)

Write a client config with local SOCKS (:10808) and HTTP (:10809) inbound, pointing to the server with `realitySettings` containing:
- `serverName`: `apple.com`
- `fingerprint`: `chrome`
- `publicKey`: (from step 2)
- `shortId`: (from step 3)

See `templates/xray-client-windows.json`.

#### iPhone (Shadowrocket) — One-click URI

Format:
```
vless://UUID@SERVER_IP:PORT?type=tcp&security=reality&pbk=PUBLICKEY&fp=chrome&sni=apple.com&sid=SHORTID&flow=xtls-rprx-vision#NAME
```

Generate a QR code for easy import:

```bash
qrencode -o shadowrocket-qr.png -s 8 -l H "vless://..."
```

### 8. Configure Cloud Firewall

**PITFALL**: Most cloud VPS (AWS Lightsail, EC2 security groups, DigitalOcean firewalls) block inbound ports by default. You must explicitly open the proxy port.

See `references/cloud-firewall.md` for specific instructions per provider.

## Verification Flow

```
[Client] → VLESS+REALITY → Server:443 → apple.com TLS handshake (masquerade)
                               ↓
                          freedom outbound → internet
```

The REALITY protocol means: if someone probes your server's port 443, they see a legitimate apple.com TLS handshake and certificate. Your proxy traffic is indistinguishable from normal HTTPS.

## 9. Harden Server Security

**⚠️ A proxy server on :443 is a high-profile target. These steps are mandatory, not optional.**

### 9.1 Firewall (iptables)

Drop everything **except** SSH and the proxy port:

```bash
# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow established sessions (don't kill your own SSH)
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH and proxy
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Log dropped traffic (rate-limited, no log flooding)
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "FW-DROP: "
```

**Persist across reboots**:

```bash
sudo apt-get install -y iptables-persistent
sudo iptables-save | sudo tee /etc/iptables/rules.v4
sudo systemctl enable netfilter-persistent
```

See `templates/firewall-rules.sh` for a ready-to-run script.

### 9.2 Brute-Force Protection (fail2ban)

```bash
sudo apt-get install -y fail2ban
```

Write `/etc/fail2ban/jail.local`:

```ini
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 5
bantime = 1h
```

Restart and verify:

```bash
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
```

### 9.3 Protect Xray Private Key

After setup, lock down config so only `nobody` can read it:

```bash
sudo chmod 600 /usr/local/etc/xray/config.json
sudo chown nobody:nogroup /usr/local/etc/xray/config.json
```

**Why**: The config stores the REALITY PrivateKey in plaintext. At 644 (default after install), any user can read it and decrypt your proxy traffic.

### 9.4 Harden SSH

```bash
sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

Verify:

```bash
grep -E "^PermitRootLogin|^X11Forwarding" /etc/ssh/sshd_config
# Expected: "PermitRootLogin no" and "X11Forwarding no"
```

### 9.5 Auto Security Updates

```bash
sudo apt-get install -y unattended-upgrades
```

Ubuntu defaults already restrict auto-upgrades to `security` origin. Verify:

```bash
grep -A10 "Unattended-Upgrade::Allowed-Origins" /etc/apt/apt.conf.d/50unattended-upgrades
# Should include "-security" origins, NOT "-updates" or "-proposed"
```

### 9.6 Apply Pending Security Patches

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

If the kernel was updated, schedule a reboot.

### 9.7 Verify No Unauthorized Listening Ports

```bash
ss -tlnp
# Should show only: :22 (SSH), :443 (Xray), :53 (systemd-resolved, local)
# Nothing unexpected
```

## 9.8 Full Security Audit & Hardening

For a comprehensive security audit and hardening workflow (beyond the proxy-specific steps above), see `references/security-hardening-pitfalls.md`. It covers:

- SSH hardening (password auth, user restrictions, cipher limits, Ubuntu 24.04 service name pitfall)
- fail2ban tuning (aggressive jail, shorter findtime)
- Kernel parameter hardening (SYN flood, source routing, ASLR, ptrace)
- PAM password complexity policy
- Security audit quick-check commands
- Common pitfalls: `ssh` vs `sshd` service name, dpkg interrupted state, iptables-persistent noninteractive config

## Security Checklist Summary

| Step | What | Key Command |
|---|---|---|
| 9.1 | iptables firewall | `iptables -P INPUT DROP` + open `:22` `:443` |
| 9.2 | fail2ban SSH jail | Install + write `/etc/fail2ban/jail.local` |
| 9.3 | Config file locked | `chmod 600 /usr/local/etc/xray/config.json` |
| 9.4 | SSH hardened | Disable root login + X11 forwarding |
| 9.5 | Auto security updates | Install `unattended-upgrades` |
| 9.6 | Apply patches | `apt-get upgrade -y` |
| 9.7 | Verify listening ports | `ss -tlnp` — only expected ports |

## 10. Share Config Files via Cloudflare Tunnel

After setting up the proxy, you need to get the client config files onto your devices. If you can't use SCP (e.g., setting up iPhone), a **Cloudflare quick tunnel** lets you serve files temporarily without opening any additional ports.

### Quick Tunnel Workflow

```bash
# 1. Install cloudflared (one-time)
curl -sL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
  -o /tmp/cloudflared && chmod +x /tmp/cloudflared

# 2. Start a local HTTP server on port 18888
cd /home/ubuntu
python3 -m http.server 18888 &

# 3. Start the tunnel
/tmp/cloudflared tunnel --url http://127.0.0.1:18888 --no-autoupdate
# Output shows: https://RANDOM-WORDS.trycloudflare.com
```

Then on your phone or any device, open the URL in a browser to download/access the files.

### Files to Share

| File | Purpose |
|------|---------|
| `vless-reality-windows.json` | Import into v2rayN (Windows) |
| `hermes-vless-reality.json` | Generic JSON config |
| `iphone-proxy-guide.html` | Self-contained HTML guide with one-click Shadowrocket link |
| `shadowrocket-qr.png` | QR code image for Shadowrocket scan |

### Pitfalls

- **Ephemeral URL** — Every restart of cloudflared gets a new `trycloudflare.com` URL. The old URL returns 404. Re-run the tunnel if the session ended.
- **Port 18888 leftover** — If the HTTP server was killed without cleanup, port 18888 stays occupied. Fix:
  ```bash
  fuser -k 18888/tcp 2>/dev/null; sleep 1; python3 -m http.server 18888 &
  ```
- **Verify both ends** — Always check local (`curl http://127.0.0.1:18888/FILE`) **and** tunnel (`curl https://TUNNEL.trycloudflare.com/FILE`). A 502 tunnel with a working local server means cloudflared needs restarting.
- **No uptime guarantee** — Trycloudflare quick tunnels are best-effort with no SLA. For production, register a Cloudflare account and create a named tunnel (see [Cloudflare docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps)).

### Full Restart Sequence (after session disconnect)

When the user says the tunnel URL is inaccessible, the full recovery sequence is:

```bash
# 1. Kill stale HTTP server on 18888
fuser -k 18888/tcp 2>/dev/null

# 2. Kill stale cloudflared
pkill -f cloudflared 2>/dev/null

# 3. Start HTTP server
cd /home/ubuntu && python3 -m http.server 18888 &

# 4. Wait for server to be ready
sleep 1

# 5. Verify local server
curl -s --connect-timeout 5 http://127.0.0.1:18888/ 2>&1 | head -1

# 6. Start cloudflared tunnel (capture URL from output)
/tmp/cloudflared tunnel --url http://127.0.0.1:18888 --no-autoupdate &
sleep 8

# 7. Extract the tunnel URL from cloudflared logs
#    URL pattern: https://RANDOM-WORDS.trycloudflare.com

# 8. Verify public access
curl -s --connect-timeout 10 https://THE-URL.trycloudflare.com/FILE
```

**One-liner** (for quick recovery after user reports 404):
```bash
fuser -k 18888/tcp 2>/dev/null; pkill -f cloudflared 2>/dev/null; sleep 1
cd /home/ubuntu && python3 -m http.server 18888 &
sleep 2 && /tmp/cloudflared tunnel --url http://127.0.0.1:18888 --no-autoupdate &
sleep 10 && echo "New tunnel URL in cloudflared output above"
```

## Client Download Links

- **Windows**: [v2rayN](https://github.com/2dust/v2rayN/releases)
- **iPhone/iPad**: [Shadowrocket](https://apps.apple.com/app/shadowrocket/id932747118) (App Store)
- **macOS/Linux**: [Nekoray](https://github.com/MatsuriDayo/nekoray), [v2rayA](https://github.com/v2rayA/v2rayA), or [sing-box](https://github.com/SagerNet/sing-box)

## Appendix

- **SSH key transfer**: See `references/ssh-key-transfer-pitfalls.md` for reliable methods to receive and write PEM keys from users.
- **Security hardening pitfalls**: See `references/security-hardening-pitfalls.md` for the full security audit and hardening workflow, including SSH/kernel/PAM hardening and common Ubuntu 24.04 pitfalls.