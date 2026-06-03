---
name: model-training-workflow
description: End-to-end LLM fine-tuning workflow — from dataset prep to evaluation
version: 1.0.0
author: Hermes Agent
tags: [fine-tuning, training, LLM, evaluation, mlops]
---

# Model Training Workflow

End-to-end guide for LLM fine-tuning projects. Use this skill when the user asks to train, fine-tune, or evaluate a model.

## 1. Environment Check

```bash
python3 -c "import torch; print(f'CUDA: {torch.cuda.is_available()}, GPUs: {torch.cuda.device_count()}')"
nvidia-smi --query-gpu=name,memory.total,memory.used --format=csv,noheader
```

## 2. Tool Selection

| Task | Tool | When to use |
|------|------|-------------|
| SFT / LoRA / QLoRA | Axolotl (YAML config) | Most cases |
| DPO / GRPO / PPO | TRL (HuggingFace) | Alignment / RLHF |
| Full pretraining | TorchTitan / Megatron | Large-scale distributed |
| Evaluation | lm-eval-harness | Benchmarking |
| Dataset prep | HuggingFace datasets | Data pipeline |

## 3. Quick Start: Axolotl LoRA

```bash
# Install
pip install axolotl torch transformers datasets peft

# Create config
cat > config.yml << 'EOF'
base_model: mistralai/Mistral-7B-v0.1
model_type: MistralForCausalLM
tokenizer_type: LlamaTokenizer

load_in_8bit: false
load_in_4bit: true
strict: false

datasets:
  - path: dataset.jsonl
    type: alpaca
dataset_prepared_path: last_run_prepared
val_set_size: 0.1
output_dir: ./lora-out

sequence_len: 2048
sample_packing: true

lora_r: 8
lora_alpha: 16
lora_dropout: 0.05
lora_target_modules:
  - q_proj
  - v_proj

train_on_inputs: false
group_by_length: false
bf16: auto
fp16: false

gradient_accumulation_steps: 4
micro_batch_size: 2
num_epochs: 3
optimizer: adamw_bnb_8bit
lr_scheduler: cosine
learning_rate: 2e-4

warmup_steps: 100
eval_steps: 50
save_steps: 50
logging_steps: 10
EOF

# Train
accelerate launch -m axolotl.cli.train config.yml
```

## 4. DPO with TRL

```bash
pip install trl transformers datasets peft accelerate

# Key params
python3 << 'EOF'
from trl import DPOTrainer
from transformers import AutoModelForCausalLM, AutoTokenizer

model = AutoModelForCausalLM.from_pretrained("model_name", load_in_4bit=True)
tokenizer = AutoTokenizer.from_pretrained("model_name")

trainer = DPOTrainer(
    model=model,
    train_dataset=dataset,
    tokenizer=tokenizer,
    args=TrainingArguments(output_dir="./dpo-out", per_device_train_batch_size=4),
)
trainer.train()
EOF
```

## 5. Evaluation

```bash
# Install
pip install lm-eval

# Run
lm_eval --model hf --model_args pretrained=model_name \
  --tasks mmlu,gsm8k,hellaswag \
  --batch_size auto \
  --output_path ./results
```

## 6. Export & Deploy

```bash
# Merge LoRA weights
python -m axolotl.cli.merge_lora config.yml --lora_model_dir ./lora-out/merged

# Export to GGUF (for llama.cpp)
# Use llama.cpp's convert.py
python convert.py ./lora-out/merged --outfile model.gguf --outtype q4_k_m
```

## Pitfalls

- **OOM**: reduce `micro_batch_size` or increase `gradient_accumulation_steps`
- **NaN loss**: reduce learning rate, check for bad data
- **Dataset format**: Axolotl expects `alpaca` or `sharegpt` format by default
- **Tokenizer mismatch**: ensure tokenizer matches base model exactly
- **DeepSpeed + 4bit**: not compatible; use 8bit or bf16 instead