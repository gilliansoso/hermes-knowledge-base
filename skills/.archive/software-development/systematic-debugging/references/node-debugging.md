# Node.js Inspect Debugger

## Quick Reference

Two tools:
- **`node inspect`** — built-in, zero install, CLI REPL. Best for quick poking.
- **CDP via `chrome-remote-interface`** — scriptable from Node/Python; best for automating breakpoints, heap snapshots, profiling.

**Prefer `node inspect` first.** It's always available and the REPL is fast.

## `node inspect` REPL Commands

| Command | Action |
|---|---|
| `c` / `cont` | continue |
| `n` / `next` | step over |
| `s` / `step` | step into |
| `o` / `out` | step out |
| `sb('file.js', 42)` | set breakpoint at line 42 |
| `cb('file.js', 42)` | clear breakpoint |
| `breakpoints` | list all breakpoints |
| `bt` | backtrace (call stack) |
| `list(5)` | show 5 lines of source around current position |
| `watch('expr')` | evaluate expr on every pause |
| `repl` | drop into REPL in current scope |
| `exec expr` | evaluate expression once |
| `restart` | restart script |
| `.exit` | quit debugger |

## Recipes

### Launch paused on first line
```bash
node inspect path/to/script.js
```

### Debug TypeScript (tsx)
```bash
node --inspect-brk --import tsx script.ts
```

### Attach to running process
```bash
kill -SIGUSR1 <pid>        # enable inspector
node inspect -p <pid>      # or: node inspect ws://...
```

### Debug Hermes TUI (ui-tui)
```bash
hermes --tui &
TUI_PID=$(pgrep -f 'ui-tui/dist/entry' | head -1)
kill -SIGUSR1 "$TUI_PID"
curl -s http://127.0.0.1:9229/json/list
```

### Run vitest under debugger
```bash
cd /home/bb/hermes-agent/ui-tui
node --inspect-brk ./node_modules/vitest/vitest.mjs run --no-file-parallelism src/app/foo.test.tsx
```

## Common Pitfalls
1. **Wrong line numbers in TS source** — breakpoints hit emitted JS, not `.ts`. Use `sb('dist/app.js', N)` instead
2. **`--inspect` vs `--inspect-brk`** — `--inspect-brk` pauses on first line so you can set breakpoints before code runs
3. **Port collisions** — default 9229; `--inspect=0` picks random port
4. **Child processes** — `NODE_OPTIONS='--inspect-brk'` propagates to children
5. **Running through agent terminal** — use `terminal(pty=true)` or background mode
