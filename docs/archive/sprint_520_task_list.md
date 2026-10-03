# Sprint 520 Task List
## Thermodynamic Layer Early Exit & Hopfield Speculative Drafting

- [x] **Gate 1: Thermodynamic Layer Early Exit Implementation**
  - [x] Implement `cartan_vec_relative_delta(v1: ptr, v2: ptr, dim: float) -> float` in `src/std/transformer.cl`.
  - [x] Add configurable parameters: `g_early_exit_enabled`, `g_early_exit_min_layer`, `g_early_exit_threshold`.
  - [x] Wire early exit evaluation into `geomind_execute_manifold_decode_step` in `test/geomind/chat.cl`.
  - [x] Ensure `geomind_poll_char_stream(41.0, 42.0)` flushes remaining characters when early exit triggers.

- [x] **Gate 2: Continuous Hopfield Speculative Drafting**
  - [x] Implement `cartan_hopfield_draft_candidate_tokens(cur_h: ptr, max_draft: float, min_resonance: float) -> ptr` in `src/std/resonator.cl`.
  - [x] Integrate speculative burst verification in `geomind_chat_generate_reply_multimodal` in `test/geomind/chat.cl` via `cartan_manifold_layer_forward_batch_int8`.
  - [x] Implement candidate acceptance / rejection verification loop with KV cache advancing.

- [x] **Gate 3: Empirical Testing & Regression Verification**
  - [x] Rebuild `bin/geomind.exe` with `cartanc.exe`.
  - [x] Benchmark live prompt generation: verify response coherence, early exit telemetry, and decode speedup.
  - [x] Run regression suite via `tools/run_affected_tests.ps1`.

- [x] **Gate 4: Issue Tracking & Documentation**
  - [x] Update `ISSUES.md` (record and resolve ISSUE-377).
  - [x] Update `docs/ROADMAP.md` (Phase 25 Sprint 520).
  - [x] Update `CHANGELOG.md`.
  - [x] Author `docs/archive/sprint_520_walkthrough.md`.
