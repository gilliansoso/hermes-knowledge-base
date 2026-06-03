#!/bin/bash
# Firewall rules for proxy server — run as root (sudo bash firewall-rules.sh)
# Only opens :22 (SSH) and :443 (proxy). Everything else is dropped.
# Persists via netfilter-persistent (install separately).

set -euo pipefail

IPT=/usr/sbin/iptables

# Flush existing
$IPT -F
$IPT -X
$IPT -Z

# Defaults: block incoming, allow outgoing
$IPT -P INPUT DROP
$IPT -P FORWARD DROP
$IPT -P OUTPUT ACCEPT

# Loopback
$IPT -A INPUT -i lo -j ACCEPT

# Established sessions (don't break existing SSH)
$IPT -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH
$IPT -A INPUT -p tcp --dport 22 -j ACCEPT

# VLESS/REALITY proxy
$IPT -A INPUT -p tcp --dport 443 -j ACCEPT

# Ping (optional — remove if you want full stealth)
$IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Log drops (rate-limited)
$IPT -A INPUT -m limit --limit 5/min -j LOG --log-prefix "FW-DROP: "

echo "=== iptables rules applied ==="
$IPT -L -n -v