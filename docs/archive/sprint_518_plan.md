# Sprint 518 Implementation Plan
## Interactive REPL Terminal Stream Hygiene & Zero-Copy KV Sharing Optimization

**Sprint**: 518  
**Mission**: Deliver seamless multi-turn interactive REPL operation, eliminate 18.4 GB of redundant RAM churn in INT8 prefill, and configure a balanced default context horizon.

---

### Objectives
1. **Stdin Terminal Stream Hygiene (`src/cartanc/core_runtime.car`)**:
   - Discard leading `\r` and `\n` characters in `cartan_read_line()` when `len == 0.0`.
   - Never return `"exit"` on empty lines; only return `"exit"` when EOF is detected (`ch < 0.0`).
   - Free allocation and return static `""` or trimmed string safely.
2. **Zero-Copy Shared KV Layer Optimization (`src/std/transformer.cl`)**:
   - In `cartan_manifold_layer_forward_batch_int8`, eradicate `memcpy(cur_k, prev_k, kv_bytes)` and `memcpy(cur_v, prev_v, kv_bytes)` for layers 24..41.
   - Route `kv_source_layer` to layer 23.0 (if global attention) or layer 22.0 (if sliding window) when `layer_idx >= 24.0`.
   - Access `k_cache` and `v_cache` directly from `kv_source_layer`.
3. **Balanced Default Context Horizon (`test/geomind/chat.cl`, `test/geomind/main.car`)**:
   - Update default `g_chat_context_limit` from 131,072 to 8,192 tokens.
   - Maintain full dynamic expansion up to 131,072 tokens via CLI flag `-context <N>` and REPL command `/context <N>`.
4. **Empirical Verification & Regression Testing**:
   - Recompile `bin/cartanc.exe` and verify 3-stage bootstrap fixpoint.
   - Recompile `bin/geomind.exe`.
   - Execute multi-turn test to verify REPL stays active for Turn 2+.
   - Run regression test suite (`tools/run_affected_tests.ps1`).
