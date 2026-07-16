# Debugging Hermes TUI Slash Commands

Commands span three layers — Python command registry, tui_gateway JSON-RPC bridge, and the Ink/TypeScript frontend.

## Architecture
```
Python backend (hermes_cli/commands.py)     <- canonical COMMAND_REGISTRY
       │
       ▼
TUI gateway (tui_gateway/server.py)         <- slash.exec / command.dispatch
       │
       ▼
TUI frontend (ui-tui/src/app/slash/)        <- local handlers + fallthrough
```

## Investigation Steps

1. **Check TUI frontend:** `search_files --pattern "/commandname" --file_glob "*.ts" --path ui-tui/`
2. **Check Python backend:** `search_files --pattern "CommandDef" --path hermes_cli/commands.py`
3. **Check gateway:** `search_files --pattern "slash.exec" --path tui_gateway/`

## Common Issues

| Symptom | Likely Cause |
|---|---|
| Command shows in TUI but not autocomplete | Missing from `COMMAND_REGISTRY` in `hermes_cli/commands.py` |
| Command in autocomplete but doesn't work | Missing handler in TUI frontend or `tui_gateway/server.py` |
| Behavior differs between CLI and TUI | Different implementations in `cli.py` vs Ink frontend |
| Config persists but UI doesn't update | Need to patch nanostore state + re-render (not just `config.set`) |

## Fix: Missing Command Autocomplete

1. Add `CommandDef` entry to `COMMAND_REGISTRY`:
```python
CommandDef("commandname", "Description", "Session",
           cli_only=True, aliases=("alias",),
           args_hint="[arg1|arg2]", subcommands=("arg1", "arg2")),
```

2. Pick availability: `cli_only=True` (CLI/TUI only), `gateway_only=True` (messaging only), or neither (everywhere)

3. Add handler in `cli.py::process_command()` for CLI commands

4. Add handler in `gateway/run.py` for gateway-available commands

5. Rebuild TUI: `npm --prefix ui-tui run build`

## Debugging Tactics

- **Python side hangs:** use `python-debugging.md` — `remote-pdb` at handler entry
- **Ink side not reacting:** use `node-debugging.md` — `sb('dist/app.js', <line>)` after `npm run build`
- **Registry mismatch:** compare `COMMAND_REGISTRY` entries against TUI's local command list