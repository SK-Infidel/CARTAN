# Sprint 518 Walkthrough
## Interactive REPL Terminal Stream Hygiene & Zero-Copy KV Sharing Optimization

### 1. Overview & Problem Statement
- **Premature REPL Exit**: On Windows, pressing Enter sent CRLF (`\r\n`). In `cartan_read_line()`, the reader halted at `\r`, leaving `\n` in the C library buffer. On Turn 2, `getchar()` immediately read `\n`, observed `len == 0.0 && done == 1.0`, and returned `"exit"`, killing the session after Turn 1.
- **18.4 GB Redundant `memcpy`**: In `cartan_manifold_layer_forward_batch_int8`, layers 24..41 copied 512 MB per layer (total 18.44 GB) between KV caches on every sequence prefill pass.
- **Context Bloat**: A 128k default context window required 25.76 GB host RAM upon startup, degrading memory throughput and causing cache evictions.

---

### 2. Changes Made
1. **Core Runtime Stdin Stream Hygiene (`src/cartanc/core_runtime.car`)**:
   - `cartan_read_line()` ignores leading `\r` and `\n` when `len == 0.0`.
   - Never returns `"exit"` on empty lines; only returns `"exit"` on genuine EOF (`ch < 0.0`).
   - Cleanly deallocates memory on EOF and returns `""` on whitespace-only input.
2. **Zero-Copy Shared KV Layer Optimization (`src/std/transformer.cl`)**:
   - Eradicated all `memcpy` calls across shared layers 24..41 in `cartan_manifold_layer_forward_batch_int8`.
   - Routed `kv_source_layer` directly to layer 23.0 (if global attention) or layer 22.0 (if sliding window) when `layer_idx >= 24.0`.
   - Directed `k_cache` and `v_cache` directly to `kv_source_layer`.
3. **Context Horizon & Memory Footprint Normalization (`test/geomind/chat.cl`, `test/geomind/main.car`)**:
   - Balanced default context window from 131,072 to 8,192 tokens (8k, 1.50 GB RAM), speeding up allocation and memory access.
   - Retained full dynamic scaling up to 131,072 tokens via CLI `-context 131072` and REPL `/context 131072`.
   - Fixed CLI positional prompt parsing in `main.car` so option arguments (e.g. `-tokens 3`) are not mistaken for prompts.

---

### 3. Empirical Verification
- **Multi-Turn Interactive REPL Execution**:
  - Input: `hi` (Turn 1) -> `who are you` (Turn 2) -> `exit` (Turn 3).
  - Telemetry:
    - Biometrics: Evaluated face map -> `similarity: 0.9646 >= 0.85` (Authenticated as Rick).
    - Turn 1: Prefill 4616 ms (44 tokens) | Decode 3354 ms (3 tokens).
    - Prompt re-displayed `User> ` without exiting.
    - Turn 2: Prefill 3765 ms (13 tokens) | Decode 2620 ms (3 tokens) | Context Horizon: 63.
    - Clean thread pool shutdown on `exit`.
- **Compiler Regression Test Suite**:
  - `tools/run_affected_tests.ps1`: **14/14 passed** (Targets 1, 2, 3, 4, 5, 23, 46, 59, 82, 83, 84, 85, 86, 87) in 45.23s. Zero regressions.
