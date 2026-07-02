# HeartMuLa — Open-Source Music Generation (Alternative to Suno)

HeartMuLa is a family of open-source music foundation models (Apache-2.0) that generates music conditioned on lyrics and tags, with multilingual support. Comparable to Suno for open-source.

**Note:** This skill is absorbed into `songwriting-and-ai-music`. The Suno prompt engineering section (Section 6 in the main skill) covers the craft side; this reference covers the HeartMuLa tool-specific setup for those who want to run music generation locally instead of via Suno's cloud service.

## Architecture

- **HeartMuLa** — Music language model (3B/7B) for generation from lyrics + tags
- **HeartCodec** — 12.5Hz music codec for high-fidelity audio reconstruction
- **HeartTranscriptor** — Whisper-based lyrics transcription
- **HeartCLAP** — Audio-text alignment model

## Hardware Requirements

- **Minimum**: 8GB VRAM with `--lazy_load true`
- **Recommended**: 16GB+ VRAM for single-GPU
- **Multi-GPU**: `--mula_device cuda:0 --codec_device cuda:1`
- 3B model with lazy_load peaks at ~6.2GB VRAM
- **CPU mode works** but extremely slow (30-60+ min per song vs ~4 min on GPU)

## Quick Install (Ubuntu/Debian with CUDA)

```bash
# Prerequisites: Python 3.10, NVIDIA GPU with CUDA drivers
git clone https://github.com/HeartMuLa/heartlib.git
cd heartlib
uv venv --python 3.10 .venv
. .venv/bin/activate
uv pip install -e .
uv pip install --upgrade datasets transformers
```

### Required Source Patches

As of early 2026, two patches are needed for transformers 5.x compatibility:

1. **RoPE cache fix** in `src/heartlib/heartmula/modeling_heartmula.py` — add RoPE reinitialization after `reset_caches`:
```python
from torchtune.models.llama3_1._position_embeddings import Llama3ScaledRoPE
for module in self.modules():
    if isinstance(module, Llama3ScaledRoPE) and not module.is_cache_built:
        module.rope_init()
        module.to(device)
```

2. **HeartCodec loading fix** in `src/heartlib/pipelines/music_generation.py` — add `ignore_mismatched_sizes=True` to ALL `HeartCodec.from_pretrained()` calls.

### Download Models

```bash
cd heartlib
hf download --local-dir './ckpt' 'HeartMuLa/HeartMuLaGen'
hf download --local-dir './ckpt/HeartMuLa-oss-3B' 'HeartMuLa/HeartMuLa-oss-3B-happy-new-year'
hf download --local-dir './ckpt/HeartCodec-oss' 'HeartMuLa/HeartCodec-oss-20260123'
```

All 3 can be downloaded in parallel. Total is several GB.

## Usage

```bash
cd heartlib && source .venv/bin/activate
python ./examples/run_music_generation.py \
  --model_path=./ckpt --version="3B" \
  --lyrics="./assets/lyrics.txt" --tags="./assets/tags.txt" \
  --save_path="./assets/output.mp3" --lazy_load true
```

### Input Formatting

**Tags** (comma-separated, no spaces):
```
piano,happy,wedding,synthesizer,romantic
rock,energetic,guitar,drums,male-vocal
```

**Lyrics** (use bracketed structural tags matching Suno conventions — see Section 6 in the main skill):
```
[Intro]
[Verse]
Your lyrics here...
[Chorus]
Chorus lyrics...
```

### Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--max_audio_length_ms` | 240000 | Max length in ms (240s = 4 min) |
| `--topk` | 50 | Top-k sampling |
| `--temperature` | 1.0 | Sampling temperature |
| `--cfg_scale` | 1.5 | Classifier-free guidance scale |
| `--lazy_load` | false | Load/unload models on demand (saves VRAM) |
| `--mula_dtype` | bfloat16 | Dtype for HeartMuLa |
| `--codec_dtype` | float32 | Dtype for HeartCodec (fp32 recommended for quality) |

## Pitfalls

1. **Do NOT use bf16 for HeartCodec** — degrades audio quality. Use fp32 (default).
2. **Tags may be ignored** — known issue (#90). Lyrics tend to dominate.
3. **Triton not available on macOS** — Linux/CUDA only for GPU acceleration.
4. The dependency pin conflicts require the upgrades and patches described above.
5. Output: MP3, 48kHz stereo, 128kbps. RTF ≈ 1.0 (4-min song takes ~4 min to generate).

## Links

- Repo: https://github.com/HeartMuLa/heartlib
- Models: https://huggingface.co/HeartMuLa
- Paper: https://arxiv.org/abs/2601.10547
- License: Apache-2.0