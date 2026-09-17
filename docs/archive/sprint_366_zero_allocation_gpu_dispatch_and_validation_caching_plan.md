# Sprint 366 Plan: Zero-Allocation GPU Dispatch Slots & In-Memory Validation Caching

## 1. Context & Objectives
During prolonged Stage 2 pre-training, execution speed steadily decays over time. Profiling revealed two primary computational bottlenecks:
1. **Heap Allocation Churn in GPU Dispatch**: `cartan_gpu_set_arg_buf`, `cartan_gpu_set_arg_i32`, `cartan_gpu_set_arg_f32`, `cartan_gpu_launch`, and `cartan_gpu_launch_local` dynamically allocate and free 4-byte to 24-byte host buffers on every kernel argument and dispatch. With 8 kernels per token and ~100 tokens per chunk, this generates ~1,300 `malloc`/`free` calls per chunk (tens of millions over hours), causing Windows heap fragmentation and increasing allocation search times.
2. **Repeated Validation Disk I/O & BPE Re-Tokenization**: Every 100 lines, `geomind_compute_validation_loss` re-reads the validation file from disk, parses strings, calls `strlen` across the buffer, and re-executes BPE tokenization before dispatching GPU passes.

## 2. Technical Architecture & Changes
1. **Zero-Allocation GPU Argument & Dispatch Slots (`src/std/gpu.cl`)**:
   - Allocate persistent host memory slots once during initialization (`g_gpu_slot_buf`, `g_gpu_slot_i32`, `g_gpu_slot_f32`, `g_gpu_slot_gws`, `g_gpu_slot_lws`).
   - Eliminate all dynamic `malloc`/`free` calls inside `cartan_gpu_set_arg_buf`, `cartan_gpu_set_arg_i32`, `cartan_gpu_set_arg_f32`, `cartan_gpu_launch`, and `cartan_gpu_launch_local`.
2. **In-Memory Pre-Tokenized Validation Holdout Cache (`test/geomind/train.cl`)**:
   - Implement `geomind_init_val_cache(val_file: string)` to read, parse, and BPE-tokenize validation lines once into memory (`g_cached_val_chunks`).
   - Refactor `geomind_compute_validation_loss` to iterate directly over cached token vectors, bypassing disk I/O, string parsing, and BPE trie traversal during training intervals.
   - Cleanly free cached validation vectors upon training completion.
3. **Compilation, Verification & Synchronization**:
   - Recompile `test/geomind/geomind.exe` with `cartanc.exe`.
   - Synchronize across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
   - Empirically verify throughput and memory stability.
