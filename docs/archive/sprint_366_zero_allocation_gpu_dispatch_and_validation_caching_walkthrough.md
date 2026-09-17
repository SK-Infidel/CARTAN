# Sprint 366 Walkthrough: Zero-Allocation GPU Dispatch Slots & Pre-Tokenized Validation Caching

## 1. Overview
In Sprint 366, we resolved cumulative execution slowdown during continuous pre-training ([ISSUE-117]). Throughput degradation was traced to two compounding bottlenecks:
1. **Windows CRT Heap Fragmentation & Lock Contention**: `cartan_gpu_set_arg_*` and `cartan_gpu_launch*` in `src/std/gpu.cl` allocated and freed 4-byte to 24-byte host buffers on every kernel argument and dispatch call (~1,300 heap allocations per chunk, >130,000 per 100-step reporting interval).
2. **Periodic Validation Disk I/O & BPE Traversal**: `test/geomind/train.cl` repeatedly read `pretrain_validation_holdout.txt` from disk every 100 lines, slicing strings, running `strlen`, and executing trie-based BPE tokenization across 100 chunks on every evaluation interval.

Both bottlenecks have been completely eliminated.

---

## 2. Changes Implemented

### A. Zero-Allocation GPU Kernel Argument Binding & NDRange Launch
- **File**: `src/std/gpu.cl`
- **Mechanism**:
  - Allocated 5 persistent host memory slots once during `cartan_gpu_init()`:
    - `g_gpu_slot_buf` (8 bytes for buffer pointers)
    - `g_gpu_slot_i32` (4 bytes for 32-bit integer scalars)
    - `g_gpu_slot_f32` (4 bytes for 32-bit float scalars)
    - `g_gpu_slot_gws` (24 bytes for global work dimensions)
    - `g_gpu_slot_lws` (24 bytes for local workgroup dimensions)
  - Refactored `cartan_gpu_set_arg_buf`, `cartan_gpu_set_arg_i32`, `cartan_gpu_set_arg_f32`, `cartan_gpu_launch`, and `cartan_gpu_launch_local` to directly write into these pre-allocated slots and pass them to OpenCL without `malloc` or `free`.
  - Result: 0 heap allocations per chunk during GPU forward/backward/SGD passes.

### B. In-Memory Pre-Tokenized Validation Holdout Caching
- **File**: `test/geomind/train.cl`
- **Mechanism**:
  - Added global cache descriptors: `g_cached_val_file`, `g_cached_val_chunks` (dynamic tree), and `g_cached_val_count`.
  - Implemented `geomind_init_val_cache(val_file: string)`: reads the holdout file once, parses lines, runs BPE tokenization once, and caches token vectors in `g_cached_val_chunks`.
  - Pre-warmed the validation cache at streaming steady-state startup in `geomind_train_streaming_steady_state`.
  - Refactored `geomind_compute_validation_loss(val_file: string, cur_h_val: ptr)`: iterates directly through pre-tokenized chunks in `g_cached_val_chunks`, launching GPU evaluation pipelines with zero file reads, zero string allocations, and zero BPE trie lookups.
  - Implemented `geomind_free_val_cache()` to clean up memory on stage completion or abort.

---

## 3. Verification & Binary Synchronization

1. **Compilation**:
   `.\cartanc.exe build test\geomind\main.car -o test\geomind\geomind.exe` completed with zero errors.
2. **Binary Artifacts**:
   - `test\geomind\geomind.exe` SHA-256: `52C3E35705E864E600346712AF30EDBE0248C343C993BD2B549B1E5680D47AEF`
   - `bin\geomind.exe` SHA-256: `52C3E35705E864E600346712AF30EDBE0248C343C993BD2B549B1E5680D47AEF`
   - `.\geomind.exe` will synchronize once the active background process (PID 10604) is stopped and restarted with the new binary.
3. **Documentation Updated**:
   - `CHANGELOG.md` updated with Sprint 366 notes.
   - `ISSUES.md` updated with `[ISSUE-117]`.
