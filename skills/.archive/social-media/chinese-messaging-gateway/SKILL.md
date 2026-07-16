---
name: chinese-messaging-gateway
description: "Use when setting up Hermes Gateway for Chinese messaging platforms — WeChat (iLink Bot API), QQ Bot (Official API v2), and WeCom (Enterprise WeChat)."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [wechat, qq, wecom, gateway, chinese-platforms, messaging]
    related_skills: [github-auth, hermes-agent, github-repo-management]
---

# Chinese Messaging Gateway Setup

## Overview

Configure Hermes Gateway to connect to Chinese messaging platforms. Hermes supports three Chinese platforms natively:

| Platform | Type | Adapter | Groups? | Voice? |
|----------|------|---------|---------|--------|
| **Weixin (微信)** | Personal | iLink Bot API | ❌ (iLink bot can't join normal groups) | ✅ |
| **QQ Bot** | Bot platform | Official QQ Bot API v2 | ✅ (@-mentions) | ✅ (ASR + STT) |
| **WeCom (企业微信)** | Enterprise | WeCom adapter | ✅ | ✅ |

Messages are delivered via long-polling (WeChat) or WebSocket (QQ Bot), so no public endpoint or webhook is required.

## Prerequisites

- Hermes Gateway installed and running
- For all platforms: `pip install aiohttp` (HTTP client)
- For WeChat: `pip install cryptography` (AES media decryption)
- For QQ Bot: `pip install httpx` (additional HTTP client)

## Platform Setup

### Weixin (WeChat) — Personal Account

See `references/weixin-wechat.md` for full documentation.

Quick start:
```bash
pip install aiohttp cryptography
hermes gateway setup   # Select "Weixin" → scan QR code with WeChat app
```

Key env vars in `~/.hermes/.env`:
```
WEIXIN_ACCOUNT_ID=<auto-saved-from-qr-login>
WEIXIN_TOKEN=<auto-saved-from-qr-login>
WEIXIN_DM_POLICY=allowlist
WEIXIN_ALLOWED_USERS=user_id_1,user_id_2
```

### QQ Bot — Official Bot Platform

See `references/qq-bot.md` for full documentation.

Quick start:
1. Register bot at https://q.qq.com → get App ID + App Secret
2. Enable intents: C2C messages, Group @-messages, Guild messages
3. Install: `pip install aiohttp httpx`
4. Configure: `hermes gateway setup` → QQ Bot

Key env vars in `~/.hermes/.env`:
```
QQ_APP_ID=your-app-id
QQ_CLIENT_SECRET=your-client-secret
QQ_ALLOWED_USERS=openid_1,openid_2
```

### WeCom (企业微信) — Enterprise

Two modes available:
- **Standard WeCom adapter** — full bot features (voice, images, files, typing, streaming)
- **WeCom Callback (Self-Built App)** — lighter callback-based integration

## Common Pitfalls

1. **iLink bot vs personal account** — QR login connects to an iLink bot identity (`xxx@im.bot`), NOT your personal WeChat account. @-mentioning your personal account ≠ @-mentioning the bot.
2. **WeChat groups likely won't work** — iLink bot identities typically cannot receive ordinary WeChat group messages. If DMs work but groups don't, it's an iLink limitation, not a Hermes bug.
3. **QQ Bot sandbox mode** — If the bot is in sandbox, it can only receive messages from QQ's sandbox test channel. You must publish the bot for production use.
4. **QQ Bot quick disconnect** — Usually means invalid App ID/Secret or missing intents. Double-check credentials at q.qq.com.
5. **Token lock (WeChat)** — Only one gateway instance can use the same WeChat token at a time. Stop the other gateway first.
6. **Session expiry (WeChat)** — WeChat sessions expire after some days/weeks. Re-run `hermes gateway setup` to scan a new QR code.

## Verification

```bash
# Check gateway status
hermes gateway status

# Review gateway logs for connection errors
grep -i "weixin\|qqbot\|wecom\|error\|failed" ~/.hermes/logs/gateway.log | tail -20

# List enabled platforms
hermes platforms
```

## Testing

1. Send a DM to the bot on the connected platform
2. Verify the agent responds
3. Check `~/.hermes/logs/gateway.log` for inbound message logs
4. Test media: send an image, file, or voice message

## Verification Checklist

- [ ] Platform dependencies installed (aiohttp, cryptography, httpx as needed)
- [ ] QR login or App credentials configured
- [ ] DM policy set to allowlist (recommended) and allowed user IDs configured
- [ ] Gateway running and showing connected status
- [ ] DM from your account receives a response
- [ ] No "Session expired" or "Quick disconnect" errors in gateway logs