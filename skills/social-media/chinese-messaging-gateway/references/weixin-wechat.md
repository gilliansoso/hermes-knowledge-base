# Weixin (WeChat) Gateway — Reference

## Architecture

Hermes connects to WeChat personal accounts via Tencent's **iLink Bot API**. Messages are delivered via **long-polling** (35-second timeout), not WebSocket or webhook. No public endpoint is needed.

```
WeChat App → iLink API → Hermes Gateway (long-poll GET)
Hermes Gateway → iLink API → WeChat App (POST send/upload)
```

## Setup Flow

```bash
# 1. Install dependencies
pip install aiohttp cryptography

# 2. Run interactive setup (QR login)
hermes gateway setup
# → Select "Weixin"
# → QR code displayed in terminal
# → Scan with WeChat mobile app
# → Confirm login on phone

# 3. Credentials auto-saved to ~/.hermes/weixin/accounts/
# After success, you'll see: 微信连接成功，account_id=your-account-id
```

## Key Limitations

**iLink bot identity** — QR login connects to an iLink bot (e.g. `a5ace6fd482e@im.bot`), NOT your personal WeChat account.

This means:
- The bot **cannot be invited into normal WeChat groups**
- iLink typically **doesn't deliver group events** (including @-mentions)
- @-mentioning your personal WeChat account ≠ @-mentioning the iLink bot
- Group policy settings (`WEIXIN_GROUP_POLICY`) may have **no effect** because iLink never sends group events to the gateway

In practice, **only DMs work reliably** for most deployments.

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `WEIXIN_ACCOUNT_ID` | ✅ | — | iLink Bot account ID (from QR login) |
| `WEIXIN_TOKEN` | ✅ | — | iLink Bot token (auto-saved) |
| `WEIXIN_DM_POLICY` | — | `open` | `open` / `allowlist` / `disabled` / `pairing` |
| `WEIXIN_GROUP_POLICY` | — | `disabled` | `open` / `allowlist` / `disabled` (likely no effect) |
| `WEIXIN_ALLOWED_USERS` | — | — | Comma-separated user IDs for DM allowlist |
| `WEIXIN_HOME_CHANNEL` | — | — | Chat ID for cron/notification delivery |
| `WEIXIN_SPLIT_MULTILINE_MESSAGES` | — | `false` | Legacy: split multi-line replies into multiple messages |

## Finding User IDs for Allowlist

1. Set `WEIXIN_DM_POLICY=open` temporarily
2. Each allowed user sends a DM to the iLink bot
3. Read user IDs from gateway logs: `grep -i "weixin\|inbound" ~/.hermes/logs/gateway.log`
4. Add those IDs to `WEIXIN_ALLOWED_USERS`, restart gateway

## Session Expiry

WeChat iLink sessions expire after some days/weeks. When this happens:
- Gateway logs: `Session expired (errcode=-14)`
- Fix: Re-run `hermes gateway setup`

## Token Lock

Only one gateway instance can use the same WeChat token. If a second instance starts, it fails with an explicit error. Stop the first gateway before starting another.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `aiohttp and cryptography are required` | `pip install aiohttp cryptography` |
| `WEIXIN_TOKEN is required` | Run `hermes gateway setup` |
| `WEIXIN_ACCOUNT_ID is required` | Set in `.env` or run `hermes gateway setup` |
| `Another local gateway is already using this token` | Stop the other instance |
| `Session expired (errcode=-14)` | Re-run `hermes gateway setup` |
| Bot ignores group messages | Group policy defaults to disabled, but likely irrelevant — iLink bot can't receive group events anyway |
| QR code expired during setup | QR auto-refreshes up to 3 times. Check network if it keeps expiring |
| Media download fails | Ensure `cryptography` is installed. Check network to `novac2c.cdn.weixin.qq.com` |

## Config.yaml (platforms.weixin.extra)

```yaml
platforms:
  weixin:
    enabled: true
    extra:
      account_id: "your-account-id"
      token: "your-token"
      dm_policy: "allowlist"
      allow_from:
        - "user_openid_1"
      group_policy: "disabled"
      split_multiline_messages: false
      text_batch_delay_seconds: 3.0
      text_batch_split_delay_seconds: 5.0
```