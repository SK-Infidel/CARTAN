# Sprint 513 Plan: Configurable 128k Context Window Architecture

**Target Issue**: `[ISSUE-367]` Configurable Long-Context Window Architecture (Up to 128k / 131,072 Tokens)  
**Date**: 2026-10-02  
**Supervisor**: Antigravity  

---

## Sprint Objectives
1. **Dynamic KV Cache Arena**:
   - Implement `cartan_kv_cache_set_capacity(max_seq: float) -> float` and `cartan_kv_cache_get_capacity() -> float` in `src/std/transformer.cl`.
   - Size the KV cache arena for the 24 active KV layers ($0..23$) with stride `layer_idx * (g_kv_cache_max_seq * 1024.0)`.
   - Support out-of-the-box 128k (131,072 tokens) capacity, utilizing 25.76 GB of the host system's 44.1 GB available RAM.
2. **Buffer Overflow Prevention (`g_trans_scores`)**:
   - Dynamically size `g_trans_scores` to `g_kv_cache_max_seq * 4.0` bytes (512 KB for 128k), eliminating the 4,096-token heap overflow bug.
3. **Adaptive RoPE Frequency Scaling**:
   - Apply proportional frequency scaling $\text{rope\_theta} \times (\text{max\_seq} / 2048.0)$ to prevent angle wrapping at positions $> 2,048$.
4. **CLI & REPL Controls**:
   - Add CLI parameter parsing for `-context <N>` and `--context <N>` in `test/geomind/main.car`, defaulting to `131072.0`.
   - Add REPL command `/context [N]` to inspect active token usage and resize the context window dynamically.
   - Update FIFO memory cycling horizon in `test/geomind/chat.cl` to scale with `g_chat_context_limit`.
5. **Targeted Verification**:
   - Recompile `cartanc.exe` and `geomind.exe`.
   - Verify 128k context initialization and active inference.
   - Run affected regression tests (Targets 58, 83, 84, 85, 86).
