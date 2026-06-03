# Cloud Firewall Configuration for Proxy Port

## AWS Lightsail

Lightsail has its own firewall separate from OS-level iptables/ufw.

1. Go to [Lightsail Console](https://lightsail.aws.amazon.com) → Instances → your instance
2. Click the **Networking** tab
3. Under **IPv4 Firewall**, click **Add rule**
   - Application: **Custom**
   - Protocol: **TCP**
   - Port: **443** (or your proxy port)
   - Source: `0.0.0.0/0`
4. Click **Create**

Changes take effect within ~10 seconds.

## AWS EC2 (Security Groups)

1. EC2 Console → Security Groups → select the group attached to your instance
2. **Edit inbound rules** → **Add rule**
   - Type: **Custom TCP**
   - Port: **443**
   - Source: `0.0.0.0/0` (or restrict to specific IPs for security)
3. **Save rules**

## DigitalOcean

1. Cloud Console → Networking → Firewalls
2. Choose or create a firewall for your droplet
3. **Inbound Rules** → **Add Rule**
   - Type: **Custom**
   - Protocol: **TCP**
   - Ports: **443**
   - Sources: `0.0.0.0/0`
4. Apply to the droplet

## Vultr

1. Vultr Console → your instance → **Settings** → **Firewall**
2. **Add Firewall Group** or edit existing
3. **Add Rule**
   - Type: **TCP**
   - Port: **443**
   - Source: `0.0.0.0/0`
4. Assign to the instance

## Verification

From any external machine:

```bash
curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 https://YOUR_SERVER_IP
# Expected output: connection refused = firewall still blocking
# If REALITY is running: you'll get no HTTP response (TLS handshake succeeds but curl fails on cert mismatch — this is expected)
```

Better test with openssl:

```bash
timeout 5 bash -c 'echo | openssl s_client -connect YOUR_SERVER_IP:443 -servername apple.com 2>/dev/null' | openssl x509 -noout -subject
# Expected: CN = apple.com
```

If the openssl command times out or hangs, the firewall is still blocking the port.