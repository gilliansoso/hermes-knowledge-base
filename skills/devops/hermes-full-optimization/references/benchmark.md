# Benchmark Reference

Script: `~/.hermes/scripts/benchmark.py`
Report: `~/.hermes/benchmark-report.json`

## Usage

```bash
# Default: 5 test prompts
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/benchmark.py

# Custom count
~/.hermes/hermes-agent/venv/bin/python3 ~/.hermes/scripts/benchmark.py 20
```

## Test Prompts (10 curated)

1. 用 Python 写一个斐波那契数列函数
2. 解释一下什么是 RESTful API
3. 把这段文字翻译成英文：今天天气真好
4. 写一个简单的 Dockerfile
5. 什么是 git rebase？
6. 用 markdown 写一个 TODO list
7. 解释 TCP 三次握手
8. Python 中 list 和 tuple 的区别
9. 写一个简单的二分查找
10. 什么是装饰器？给个例子

## Reference Result (2026-06-03)

Configuration: DeepSeek V4 Flash (OpenRouter), context compression on, 3 rounds.

| Metric | Value |
|--------|-------|
| Success rate | 3/3 (100%) |
| Avg response | 35.90s |
| Fastest | 21.85s (translation) |
| Slowest | 45.93s (RESTful API explanation) |

Note: Times include OpenRouter API network latency. Local models (via Ollama/llama.cpp) would be faster.