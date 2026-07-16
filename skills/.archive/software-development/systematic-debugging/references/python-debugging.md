# Python Debugger (pdb + debugpy)

## Quick Reference

| Tool | When |
|---|---|
| **`breakpoint()` + pdb** | Local, interactive. Add `breakpoint()` in source, run normally. |
| **`python -m pdb`** | Launch script under pdb with no source edits. |
| **`debugpy`** | Remote / headless / attach to running process. Talks DAP. |

**Start with `breakpoint()`.** It's the cheapest thing that works.

## pdb Commands

| Command | Action |
|---|---|
| `h` / `h cmd` | help |
| `n` | next line (step over) |
| `s` | step into |
| `r` | return from current function |
| `c` | continue |
| `unt N` | continue until line N |
| `l` / `ll` | list source / full function |
| `w` | where (stack trace) |
| `u` / `d` | move up / down the stack |
| `a` | print args of current function |
| `p expr` / `pp expr` | print / pretty-print |
| `b file:line` | set breakpoint |
| `cl N` | clear breakpoint N |
| `!stmt` | execute arbitrary Python |
| `interact` | full Python REPL in current scope |
| `q` | quit |

## Recipes

### Local breakpoint
```python
def compute(x, y):
    result = some_helper(x)
    breakpoint()           # drops into pdb here
    return result + y
```

### Launch script under pdb
```bash
python -m pdb path/to/script.py arg1 arg2
```

### Debug pytest test
```bash
scripts/run_tests.sh tests/test_file.py::test_name --pdb -p no:xdist
```

### Post-mortem on exception
```python
try:
    run_the_thing()
except Exception:
    pdb.post_mortem(sys.exc_info()[2])
```

### Remote debug with debugpy
```bash
python -m debugpy --listen 127.0.0.1:5678 --wait-for-client your_script.py
```

### Remote-pdb (agent-friendliest)
```bash
pip install remote-pdb
# In code:
from remote_pdb import set_trace
set_trace(host="127.0.0.1", port=4444)
# Then: nc 127.0.0.1 4444
```

## Common Pitfalls
1. **pdb under pytest-xdist silently does nothing** — use `-p no:xdist` or `-n 0`
2. **`breakpoint()` in CI** — hangs the process. Never commit it
3. **`PYTHONBREAKPOINT=0`** disables all breakpoint() calls
4. **`debugpy.listen` blocks only with `wait_for_client()`**
5. **Attach to PID fails on hardened kernels** — `ptrace_scope=1` blocks it
6. **Threads** — pdb only debugs current thread; use debugpy for multi-threaded
7. **asyncio** — `await` in pdb needs Python 3.13+; use `interact` on older versions
