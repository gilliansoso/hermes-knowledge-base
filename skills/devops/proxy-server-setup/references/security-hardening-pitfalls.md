# Security Hardening Pitfalls

Session-specific pitfalls discovered during server security audit and hardening (2026-06-17).

## SSH Service Name on Ubuntu 24.04

**PITFALL**: The SSH systemd service is `ssh.service`, NOT `sshd.service` on Ubuntu 24.04.

```bash
# WRONG — returns "Unit sshd.service not found"
sudo systemctl reload sshd

# CORRECT
sudo systemctl reload ssh
sudo systemctl restart ssh
```

This applies to all `systemctl` commands (status, restart, reload, is-active).

## fail2ban Requires Root for Status

**PITFALL**: `fail2ban-client status` requires root. Without sudo you get:
```
Permission denied to socket: /var/run/fail2ban/fail2ban.sock
```

Always use `sudo fail2ban-client status sshd`.

## apt/dpkg Can Leave Broken State

**PITFALL**: If `apt install` is interrupted (timeout, crash), dpkg enters a broken state:
```
E: dpkg was interrupted, you must manually run 'sudo dpkg --configure -a' to correct the problem.
```

**Fix sequence**:
```bash
sudo dpkg --configure -a
# If iptables-persistent config prompt blocks, force noninteractive:
sudo DEBIAN_FRONTEND=noninteractive dpkg --configure -a
# Then retry:
sudo apt install -y <package>
```

**Note**: `iptables-persistent` post-install script uses `whiptail` for interactive prompts. In non-interactive sessions, this fails with exit 255. Use `DEBIAN_FRONTEND=noninteractive` to skip the prompt (rules won't be auto-saved — run `sudo iptables-save | sudo tee /etc/iptables/rules.v4` manually afterward).

## SSH Config Drop-in Directory

On Ubuntu 24.04, `/etc/ssh/sshd_config` includes `Include /etc/ssh/sshd_config.d/*.conf`. Use this for hardening overrides instead of editing the main config:

```bash
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf << 'EOF'
PasswordAuthentication no
AllowUsers ubuntu
MaxAuthTries 3
LoginGraceTime 30
AllowTcpForwarding no
AllowAgentForwarding no
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
EOF
```

Verify syntax: `sudo sshd -t`

## Kernel Parameter Persistence

Use `/etc/sysctl.d/99-security-hardening.conf` (not `/etc/sysctl.conf`) for custom kernel params. Apply with `sudo sysctl --system`.

Key params for cloud VPS:
```ini
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.log_martians = 1
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
kernel.yama.ptrace_scope = 1
fs.suid_dumpable = 0
```

## PAM Password Complexity

Requires `libpam-pwquality`:
```bash
sudo apt install -y libpam-pwquality
```

Then in `/etc/pam.d/common-password`, add before `pam_deny.so`:
```
password requisite pam_pwquality.so retry=3 minlen=12 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1
```

Also update `/etc/login.defs`:
```
PASS_MAX_DAYS  90
PASS_MIN_DAYS  7
PASS_WARN_AGE  14
```

## Security Audit Quick-Check Commands

```bash
# Recent logins
last -20

# SSH brute-force attempts
grep "Failed password\|maximum authentication" /var/log/auth.log | tail -20

# Successful SSH logins
grep "Accepted" /var/log/auth.log | tail -10

# System errors (last 7 days)
journalctl --since "7 days ago" -p err --no-pager | tail -30

# Listening ports
ss -tlnp

# fail2ban status (requires root)
sudo fail2ban-client status sshd

# iptables rules (requires root)
sudo iptables -L -n --line-numbers

# SUID files
find / -perm -4000 -type f 2>/dev/null

# World-writable files (exclude temp)
find / -xdev -perm -002 -type f 2>/dev/null | grep -v -E "^/(tmp|proc|sys|dev)"
```
