# QQ Bot Gateway — Reference

## Architecture

Hermes connects to QQ via the **Official QQ Bot API v2**. It uses:
- **WebSocket** persistent connection to receive messages (QQ Gateway)
- **REST API** to send replies (text, markdown, images, files, voice)

Channel types supported: private (C2C), group @-mentions, guild messages.

## Prerequisites

### Register a Bot at q.qq.com

1. Go to https://q.qq.com and create a new application
2. Note your **App ID** and **App Secret**
3. Enable the required **intents**:
   - `C2C messages` — private chat
   - `Group @-messages` — group mentions
   - `Guild messages` — QQ guild channels
4. Start in **sandbox mode** for testing, then publish for production

### Install Dependencies

```bash
pip install aiohttp httpx
```

## Setup

```bash
# Interactive setup
hermes gateway setup
# → Select "QQ Bot"
# → Enter App ID and App Secret when prompted

# Or manual config in ~/.hermes/.env:
QQ_APP_ID=your-app-id
QQ_CLIENT_SECRET=your-client-secret
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `QQ_APP_ID` | ✅ | — | QQ Bot App ID |
| `QQ_CLIENT_SECRET` | ✅ | — | QQ Bot App Secret |
| `QQBOT_HOME_CHANNEL` | — | — | OpenID for cron/notification delivery |
| `QQBOT_HOME_CHANNEL_NAME` | — | `Home` | Display name for home channel |
| `QQ_ALLOWED_USERS` | — | `open` | Comma-separated user OpenIDs for DM |
| `QQ_GROUP_ALLOWED_USERS` | — | — | Comma-separated group OpenIDs |
| `QQ_ALLOW_ALL_USERS` | — | `false` | Set to `true` to allow all DMs |
| `QQ_PORTAL_HOST` | — | `q.qq.com` | Override (use `sandbox.q.qq.com` for sandbox) |
| `QQ_STT_API_KEY` | — | — | API key for voice-to-text provider |
| `QQ_STT_MODEL` | — | `glm-asr` | STT model name |

## Voice Transcription (STT)

Two-stage processing:
1. **QQ built-in ASR** — free, always tried first. Provides `asr_refer_text` in voice message attachments
2. **Configured STT fallback** — if QQ's ASR doesn't return text:
   - Default: **Zhipu/GLM** (`glm-asr` model via Z.AI API)
   - Alternative: **OpenAI Whisper** (set `QQ_STT_BASE_URL` and `QQ_STT_MODEL`)
   - Any OpenAI-compatible STT endpoint

## Config.yaml

```yaml
platforms:
  qqbot:
    enabled: true
    extra:
      app_id: "your-app-id"
      client_secret: "your-secret"
      markdown_support: true         # enable QQ markdown (msg_type 2)
      dm_policy: "open"              # open | allowlist | disabled
      allow_from:
        - "user_openid_1"
      group_policy: "open"           # open | allowlist | disabled
      group_allow_from:
        - "group_openid_1"
      stt:
        provider: "zai"              # zai (GLM-ASR), openai (Whisper), etc.
        baseUrl: "https://open.bigmodel.cn/api/coding/paas/v4"
        apiKey: "your-stt-key"
        model: "glm-asr"
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| **Bot disconnects immediately** | Invalid App ID/Secret. Check credentials at q.qq.com. Or sandbox-only bot trying to access production API. Set `QQ_PORTAL_HOST=sandbox.q.qq.com` |
| **Missing intents** | Go to q.qq.com → Bot settings → enable C2C/Group/Guild intents |
| **Voice not transcribed** | Check if QQ's built-in `asr_refer_text` is present. Verify `QQ_STT_API_KEY` if using custom STT |
| **Messages not delivered** | Check `QQ_ALLOWED_USERS`. For groups, bot must be @-mentioned. Verify intents are enabled |
| **Connection errors** | Ensure `aiohttp` and `httpx` are installed. Check network to `api.sgroup.qq.com` |
| **Sandbox-only bot can't receive real messages** | Publish the bot on q.qq.com, or use `QQ_PORTAL_HOST=sandbox.q.qq.com` for sandbox testing |

## Finding User/Group OpenIDs

1. Set `dm_policy` to `open` temporarily
2. Each user sends a DM to the bot
3. Check gateway logs for user OpenIDs
4. Add those IDs to `QQ_ALLOWED_USERS`

For group OpenIDs, @-mention the bot in the group and check the group_openid in logs.