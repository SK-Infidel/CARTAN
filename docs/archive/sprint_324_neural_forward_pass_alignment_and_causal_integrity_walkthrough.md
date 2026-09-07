# Sprint 324 Walkthrough: Neural Forward Pass Alignment, Causal Integrity & Categorical Sampling

## Overview
This walkthrough details the resolution of the training-inference disconnect, causal lookahead leakage, repetition penalty miscalibration, and premature EOS termination.

## Key Changes
1. **`test/geomind/train.cl`**:
   - `e8_attention_forward_step` declared and invoked on every step of `geomind_train_streaming_steady_state`.
   - Replaced full-chunk pre-computation with strict causal initialization from `tokens[0]`.
   - Each token step computes step loss on the genuine neural manifold state `cur_h` before advancing context with `next_tok`.
2. **`src/std/tokenizer.cl`**:
   - `cartan_tokenizer_sample_topp_topk` upgraded from argmax to authentic categorical softmax sampling with temperature scaling.
3. **`test/geomind/chat.cl`**:
   - `cartan_apply_repetition_penalty` refactored to prevent character loops without penalizing natural multi-word letter occurrences.
   - `min_gen_tokens = 32.0` floor prevents premature EOS termination.
4. **`test/geomind/main.car`**:
   - `get_cli_param("-prompt", arg_count)` and parameter extractions configured for `--chat`.

## Verification Results
- `cartanc build test/geomind/main.car -o build/geomind.exe`: SUCCESS.
- Training loss: 5.69 -> 4.12 across 50 KB through the full neural manifold.
- Regression test suite: 62/62 targets PASS.
