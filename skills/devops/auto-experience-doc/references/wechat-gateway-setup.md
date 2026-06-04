# WeChat (Weixin) iLink Bot Gateway Setup

## When to Reference

When setting up the WeChat messaging platform for Hermes Agent on a headless server (no GUI, no QR code display capability).

## Prerequisites

```bash
pip install aiohttp cryptography
# Optional but recommended for terminal QR rendering:
pip install qrcode
```

## Setup Flow

### 1. Launch the setup wizard in PTY mode

The wizard is interactive (curses-style terminal UI). Must use a PTY:

```bash
# Run in interactive PTY (or tmux)
hermes gateway setup
```

### 2. Navigate to Weixin / WeChat

The radio-button list has ~23 platforms. "Weixin / WeChat" is at position ~13. Navigate with arrow keys from the top, or at the bottom from "Done" by pressing ↑ 12 times (position depends on total platform count).

Select it and press Enter.

### 3. Confirm QR login

The wizard shows:

```
1. Hermes will open Tencent iLink QR login in this terminal.
2. Use WeChat to scan and confirm the QR code.
3. Hermes will store the returned account_id/token in ~/.hermes/.env.

Start QR login now? [Y/n]: Y
```

### 4. QR code display

**If `qrcode` package is installed**: An ASCII QR code renders in the terminal. The user scans it with WeChat.

**If `qrcode` package is NOT installed**: A URL is printed instead:

```
https://liteapp.weixin.qq.com/q/7GiQu1?qrcode=...&bot_type=3
（终端二维码渲染失败: No module named 'qrcode'，请直接打开上面的二维码链接）
```

The user opens this URL in a browser (phone or desktop), which displays the QR code. They scan it with WeChat's "扫一扫" and confirm login.

### 5. Post-login

After scanning, the wizard stores credentials to `~/.hermes/weixin/accounts/` and adds `WEIXIN_ACCOUNT_ID` to `~/.hermes/.env`.

The gateway can then be started to begin polling.

## Important Limitations

- **iLink Bot identity, not personal account** — QR login connects to an iLink bot (e.g. `xxx@im.bot`), not the user's personal WeChat account directly.
- **Groups likely don't work** — iLink bot identities generally cannot receive ordinary WeChat group events. Only DMs to the bot are reliable.
- **Token lock** — Only one gateway instance can use a given Weixin token at a time.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `aiohttp and cryptography are required` | `pip install aiohttp cryptography` |
| QR code expired during setup | The wizard auto-refreshes up to 3 times. If it keeps expiring, check network. |
| `WEIXIN_TOKEN is required` | Run `hermes gateway setup` to complete QR login. |
| `Session expired (errcode=-14)` | Re-login: re-run `hermes gateway setup`. |
| Gateway startup fails with token lock | Stop other gateway instances: `systemctl --user stop hermes-gateway` |