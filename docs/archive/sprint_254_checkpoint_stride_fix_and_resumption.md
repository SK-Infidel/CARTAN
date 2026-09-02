# Sprint 254: 42-Layer Checkpoint Loader Stride Fix & Causal CE Resumption

## Executive Summary
This sprint investigated and resolved an LM head matrix stride mismatch between host memory (`CARTAN_FULL_VOCAB_SIZE = 262144`) and GPU VRAM / serialized binary checkpoints (`CARTAN_LM_HEAD_VOCAB = 65536`). When resuming training from 42-layer checkpoints (`geomind_CAUSAL CE_best.bin`), the flat read into the host buffer caused rows $r \ge 1$ to shift and scramble next-token predictions, leading to an initial loss of ~14. 

## Root Cause Analysis
1. **Vocabulary Layouts**:
   - Host vocabulary memory allocated shape `(2560, 262144)`.
   - GPU VRAM (`d_cl_weights`) and signed `.bin` checkpoints allocate and store active vocabulary shape `(2560, 65536)`.
2. **The Stride Collision**:
   - `cartan_load_42layer_checkpoint_file` read $2560 \times 65536$ floats directly into `g_model_weights_flat`.
   - Filling the upper vocabulary columns indexed `g_model_weights_flat[r * 262144 + c]`, which overwrote rows $1, 2, 3...$ read from the file.
   - `cartan_sync_host_weights_to_gpu` then wrote to the GPU buffer using stride 65536, sending scrambled matrix rows to the GPU LM head kernel.

## Modifications Made
- `src/cartanc/c_runtime.c`:
  - **`cartan_load_42layer_checkpoint_file`**: Added intermediate buffer `head_buf` and row-by-row `memcpy` unpacking from $65\text{k}$ disk stride to $262\text{k}$ host stride.
  - **`cartan_sync_host_weights_to_gpu`**: Added row-by-row packing from $262\text{k}$ host stride to $65\text{k}$ GPU VRAM stride.
  - **`cartan_sync_42layers_from_gpu`**: Added row-by-row unpacking from $65\text{k}$ GPU VRAM stride to $262\text{k}$ host stride.
  - **`cartan_init_weights_if_needed`**: Enforced row-by-row strided transfer to GPU VRAM.
  - **`cartan_save_signed_checkpoint`**: Enforced row-by-row strided copy when saving active vocabulary to `.bin` checkpoint files.
- Synchronized runtime to `~/.cartan/c_runtime.c`.
- Rebuilt `bin/geomind.exe`, `build/geomind.exe`, and `test/geomind/geomind.exe`.

## Empirical Verification
- Resumed training with `geomind.exe --train-ce`:
  - Confirmed checkpoint loaded smoothly.
  - Initial training loss started at **8.38** (val loss **8.33**), smoothly converging to **7.86** within 20k samples, fully eliminating the 14.0 unaligned loss spike.
