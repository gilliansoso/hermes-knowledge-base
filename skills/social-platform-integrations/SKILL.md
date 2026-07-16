---
name: social-platform-integrations
description: "API integrations for social and messaging platforms: X/Twitter (xurl), Yuanbao (元宝) groups, WeChat/QQ/WeCom gateway, and other social platform APIs."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [social, messaging, twitter, x, yuanbao, wechat, qq, wecom, api]
    category: social-media
---

# Social Platform Integrations

Unified reference for social and messaging platform API integrations. Each platform is a labeled subsection below.

This umbrella consolidates the former `xurl`, `yuanbao`, and `chinese-messaging-gateway` skills.

---

## X/Twitter (via xurl CLI)

Post, search, DM, and manage content on X/Twitter using the official `xurl` CLI.

### Setup (user must do outside agent)

1. Install: `curl -fsSL https://raw.githubusercontent.com/xdevplatform/xurl/main/install.sh | bash`
2. Create app at https://developer.x.com/en/portal/dashboard
3. Register app: `xurl auth apps add my-app --client-id YOUR_CLIENT_ID --client-secret YOUR_CLIENT_SECRET`
4. Authenticate: `xurl auth oauth2 --app my-app YOUR_USERNAME`
5. Set default: `xurl auth default my-app`
6. Verify: `xurl auth status`

### Common Commands

| Action | Command |
|--------|---------|
| Post | `xurl post "Hello world!"` |
| Reply | `xurl reply POST_ID "Nice post!"` |
| Search | `xurl search "from:elonmusk" -n 10` |
| Timeline | `xurl timeline -n 20` |
| Like | `xurl like POST_ID` |
| DM | `xurl dm @handle "message"` |
| Follow | `xurl follow @handle` |
| Read post | `xurl read POST_ID` |
| Whoami | `xurl whoami` |
| Upload media | `xurl media upload photo.jpg` |
| Raw API | `xurl /2/users/me` |

### Safety Rules

- Never read, print, or send `~/.xurl` to LLM context
- Never use `--verbose` / `-v` in agent sessions (leaks auth headers)
- Never pass inline secrets via CLI flags
- Confirm with user before any write action (post, reply, like, DM, follow)

### Troubleshooting

- Auth errors after OAuth: token saved to `default` app instead of named app — re-run `xurl auth oauth2 --app my-app`
- 401 on every request: check `xurl auth status` for correct default app
- `UsernameNotFound` after OAuth: pass handle explicitly: `xurl auth oauth2 --app my-app USERNAME`

---

## Yuanbao (元宝) Groups

Interact with Yuanbao (元宝) groups: @mention users, query group info, send DMs.

### How It Works

Your text reply IS the message sent to the group. The gateway automatically delivers your response text. Include `@nickname` in reply text for real @mentions.

### Tools

| Tool | When to use |
|------|------------|
| `yb_query_group_info` | Query group name, owner, member count |
| `yb_query_group_members` | Find a user, list bots, list all members |
| `yb_send_dm` | Send a private message to a user, with optional media files |

### @Mention Workflow

1. Call `yb_query_group_members` with `action="find"`, `name="<target>"`, `mention=true`
2. Get the exact nickname
3. Include `@nickname` in your reply text

### DM Workflow

1. Call `yb_send_dm` with `group_code`, `name`, and `message`
2. Supports media: images (.jpg/.png/.gif/.webp/.bmp) as image messages, other files as documents

### Notes

- `group_code` comes from chat_id: `group:328306697` → `328306697`
- Groups are called "派 (Pai)" in the Yuanbao app
- Never guess nicknames — always query first

---

## Chinese Messaging Gateway (WeChat, QQ, WeCom)

Configure Hermes Gateway for Chinese messaging platforms: WeChat (iLink Bot API), QQ Bot (Official API v2), and WeCom (Enterprise WeChat).

### Architecture

All three platforms use the same gateway pattern:
```
Hermes Gateway → Platform-specific adapter → Platform API
```

### WeChat (iLink Bot API)

1. Register a bot at https://bot.ilnk.cn/
2. Get the bot's WebSocket URL and API key
3. Configure in `~/.hermes/config.yaml`:

```yaml
gateway:
  adapters:
    wechat:
      type: "wechat"
      api_key: "your_ilink_api_key"
      bot_ws_url: "wss://bot.ilnk.cn/ws"
```

### QQ Bot (Official API v2)

1. Create a bot at https://q.qq.com/
2. Get sandbox and production credentials
3. Configure:

```yaml
gateway:
  adapters:
    qq:
      type: "qq"
      app_id: "your_app_id"
      app_secret: "your_app_secret"
      token: "your_token"
```

### WeCom (Enterprise WeChat)

1. Create an app in WeCom admin console
2. Configure:

```yaml
gateway:
  adapters:
    wecom:
      type: "wecom"
      corp_id: "your_corp_id"
      agent_id: "your_agent_id"
      secret: "your_secret"
```

### Common Pitfalls

- All three require a public HTTPS endpoint for webhooks (use ngrok or a public server)
- WeChat and QQ use WebSocket for real-time messaging
- WeCom uses HTTP callback/webhook mode
- Test with sandbox environment before production