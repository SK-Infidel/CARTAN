# Sprint 529 Task List: Windowed Repetition Penalty, Ghost Slot Masking & StreamingLLM Attention Sinks

- [x] **1. Windowed Repetition Penalty (`test/geomind/chat.cl`)**
  - [x] Update `cartan_apply_repetition_penalty`: bound all 4 penalty stages to the most recent 64 tokens in `history` (`window = 64.0`, `start_idx = h_len - window`).
  - [x] Protect common English connectives and punctuation from cross-turn cumulative logit suppression.

- [x] **2. Ghost Slot Large-Negative Masking (`src/std/transformer.cl`)**
  - [x] Update `cartan_kv_cache_clear_range`: initialize `g_kv_mask_block` with $-10000.0$ floats (4096 bytes).
  - [x] Fill cleared $K$ slots with $-10000.0$ and implement sentinel bypassing (`if (cartan_f32_at(k_ht, 0.0) > -9999.0)`), eliminating the $\sum Q_d < 0$ hazard and guaranteeing $0.0$ Softmax weight.
  - [x] Keep $V$ zeroed.

- [x] **3. StreamingLLM Attention Sinks & Local Sliding Window Attention (`src/std/transformer.cl`)**
  - [x] Define global attention sink and window parameters (`g_attention_sink_tokens = 4.0`, `g_attention_window_size = 256.0`).
  - [x] Implement getters/setters `cartan_transformer_set_attention_window` and `cartan_transformer_get_attention_window_size`.
  - [x] Update `cartan_manifold_layer_forward_native`:
    - When `max_seq > (sink_limit + window_size)`, evaluate attention only across sink tokens ($0 \dots \text{sink\_limit}-1$) and local sliding window ($\text{win\_start} \dots \text{max\_seq}-1$).
    - Skip intermediate positions, bounding attention dot products to $\le 260$ operations per head per layer.
  - [x] Update `cartan_manifold_layer_forward_batch_int4`, `batch_int8`, and `batch` with the same Attention Sinks + Sliding Window logic.

- [x] **4. Build, Benchmarks & Regression Suite**
  - [x] Rebuild `bin/geomind.exe` with `cartanc.exe`.
  - [x] Run multi-turn canary benchmark: verify decode throughput remains constant across turns, no grammar decay, and no ghost slot dilution.
  - [x] Add Sprint 529 preset to `tools/run_affected_tests.ps1` and run regression suite (16/16 PASS).

- [x] **5. Review, Documentation & Closure**
  - [x] Close `[ISSUE-387]` in `ISSUES.md`.
  - [x] Update `CHANGELOG.md` to `[8.485.0]`.
  - [x] Update Phase 25 in `docs/ROADMAP.md`.
  - [x] Save walkthrough to `docs/archive/sprint_529_walkthrough.md`.
