# Startup Code Review: Sprint 518
## Interactive REPL Terminal Stream Hygiene & Zero-Copy KV Sharing Optimization

**Date**: 2026-10-03  
**Reviewer**: Supervisor Agent & Core Squad Leads  
**Targets**:
- `src/cartanc/core_runtime.car` (`cartan_read_line`)
- `src/std/transformer.cl` (`cartan_manifold_layer_forward_batch_int8`)
- `test/geomind/chat.cl` (`g_chat_context_limit`)
- `test/geomind/main.car` (`geomind_chat_interactive_loop`, CLI default context)

---

### 1. Executive Summary & Root Cause Analysis

#### A. REPL Early Exit After Turn 1 (Terminal CRLF Stdin Desynchronization)
- **Symptom**: GeoMind executes Turn 1, streams reply, prints `User> `, and immediately terminates without accepting Turn 2.
- **Root Cause**: On Windows, pressing Enter transmits `\r\n` (ASCII 13, 10). In `src/cartanc/core_runtime.car:833-847`, `cartan_read_line()` stopped reading on `ch == 13.0` (`\r`), leaving `\n` in the C library `stdin` buffer. When `cartan_read_line()` was called for Turn 2, `getchar()` immediately retrieved `\n` without user interaction. Because `len == 0.0` and `ch == 10.0` set `done = 1.0`, line 845 triggered:
  ```cartan
  if (len == 0.0 && done == 1.0) { return "exit"; }
  ```
  This returned `"exit"`, causing `test/geomind/main.car:588` to break the loop and shut down.
- **Remediation**:
  1. Discard leading `\r` and `\n` when `len == 0.0`.
  2. Only return `"exit"` on genuine EOF (`ch < 0.0`).
  3. Return `""` on empty/whitespace-only input so the REPL loop simply redisplays the prompt.

#### B. 18.4 GB Redundant `memcpy` on Shared KV Layers 24..41
- **Symptom**: At 128k context, prefill latency suffered heavy memory bus contention.
- **Root Cause**: In `src/std/transformer.cl:3542-3550`, `cartan_manifold_layer_forward_batch_int8` executed:
  ```cartan
  let prev_k = cartan_kv_cache_get_k(layer_idx - 1.0);
  let prev_v = cartan_kv_cache_get_v(layer_idx - 1.0);
  let cur_k = cartan_kv_cache_get_k(layer_idx);
  let cur_v = cartan_kv_cache_get_v(layer_idx);
  let kv_bytes = g_kv_cache_max_seq * kv_dim * 4.0;
  memcpy(cur_k, prev_k, kv_bytes);
  memcpy(cur_v, prev_v, kv_bytes);
  ```
  At 128k sequence length, `kv_bytes` is 512 MB. Across 18 shared layers (24..41), this churned 18.44 GB of RAM copies per prefill. In contrast, FP32 batch forward and single-token decode point directly to `kv_source_layer` (layer 22 or 23) with zero copying.
- **Remediation**:
  1. Remove `memcpy` blocks entirely.
  2. Set `kv_source_layer = (is_global > 0.0) ? 23.0 : 22.0` when `layer_idx >= 24.0`.
  3. Fetch `k_cache` and `v_cache` directly from `kv_source_layer`.

#### C. Unbounded 128k Default Context Memory Footprint (25.76 GB RAM)
- **Symptom**: Cold start allocated 25.76 GB host RAM, causing memory bus pressure and generation throttling.
- **Root Cause**: `g_chat_context_limit` defaulted to 131,072 in `chat.cl` and `main.car`.
- **Remediation**:
  1. Default to 8,192 tokens (8k) across 24 KV layers (~1.61 GB RAM) for instant startup and low latency.
  2. Retain full 128k capability on demand via `-context 131072` CLI argument or `/context 131072` REPL command.

---

### 2. Logical Dependency Tree

```
src/cartanc/core_runtime.car (cartan_read_line, cartan_flush, memory primitives)
    ├── linked into compiler (bin/cartanc.exe)
    └── linked into compiled applications (bin/geomind.exe)

src/std/transformer.cl (transformer execution, batched INT8 GEMV, KV caching)
    ├── depends on: core_runtime.car, llvm_codegen intrinsics (@cartan_simd_dot_i8_f32)
    └── consumed by: test/geomind/chat.cl, test/geomind/main.car

test/geomind/chat.cl (conversational orchestrator, context capacity manager)
    ├── depends on: transformer.cl, sqlite_vec.cl, geometry.cl
    └── consumed by: test/geomind/main.car

test/geomind/main.car (REPL loop, CLI argument parsing, thread pool lifecycle)
    └── depends on: chat.cl, core_runtime.car
```

---

### 3. Git Issues Identified & Tracked
- **[ISSUE-373]**: Stdin CRLF / Empty Input REPL Premature Termination Bug in `cartan_read_line()`
- **[ISSUE-374]**: 18.4 GB Redundant `memcpy` on Shared KV Layers 24..41 in Batched INT8 Forward Pass
- **[ISSUE-375]**: Unbounded 128k Default Context Memory Footprint (25.76 GB RAM) Causing Allocation Latency and Bus Contention
