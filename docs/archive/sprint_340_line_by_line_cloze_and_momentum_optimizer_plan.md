# Sprint 340: Line-by-Line Cloze Ingestion, Zero-JSON Training & GPU Momentum Optimizer Plan

## Problem Statement & Discoveries
1. **87.5% Corpus Blindspot**: `test/geomind/train.cl` used `window_size = 256` and `stride = 2048`, skipping 1,792 bytes out of every 2,048 bytes (87.5% of the corpus). The same 12.5% slice was repeated every epoch.
2. **Arbitrary Mid-Line Slicing**: Slicing 256-byte windows cut sentences and words in half, breaking transitional phrase learning.
3. **JSON Syntax Contamination**: Reading raw JSON lines trained the model on JSON boilerplate (`{"sentence_cloze": "`, quotes, colons, braces) rather than natural language transitions.
4. **Zero-Momentum Stagnation**: Vanilla SGD without momentum oscillated in 2,560-D space, while geometric LR decay throttled learning rate to 0.0001 by epoch 28, causing loss to drop only 0.4 over 77 epochs.

## Architecture & Implementation Directives
1. **Line-by-Line Natural Text Ingestion**:
   - Replace fixed-offset byte jumping with line-by-line scanning.
   - Each line is a single learning item; never slice mid-sentence.
   - If line is JSON (`{"sentence_cloze": ...}`), extract `sentence_cloze` and `target_phrase` and concatenate into clean natural text. If plain text, ingest directly.
   - Process 100% of lines sequentially across all datasets in the corpus (zero data skipped).
2. **GPU Momentum Optimizer in VRAM**:
   - Allocate `g_buf_cortical_velocity` (2,560 x 2,560 float32, 26.2 MB) in GPU VRAM.
   - Upgrade OpenCL kernel to `geomind_sgd_momentum_backward` with beta = 0.90:
     v_t = beta * v_{t-1} + lr * (h (x) delta)
     W_t = W_t * decay - v_t
3. **Adaptive Learning Rate Floor**:
   - Set minimum learning rate floor to 0.0005 to sustain steady descent.
4. **Empirical Verification & Binary Sync**:
   - Compile `bin/geomind.exe` with `cartanc.exe`.
   - Synchronize all 4 production binaries with identical SHA-256 hash.
   - Verify line-by-line training and accelerated loss descent on physical GPU.