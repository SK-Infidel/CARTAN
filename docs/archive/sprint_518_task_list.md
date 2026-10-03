# Sprint 518 Task List
## Interactive REPL Terminal Stream Hygiene & Zero-Copy KV Sharing Optimization

- [x] **Gate 1: Core Runtime Stdin Stream Hygiene**
  - [x] Update `cartan_read_line()` in `src/cartanc/core_runtime.car` to discard leading `\r` and `\n` when `len == 0.0`.
  - [x] Restrict `"exit"` return strictly to genuine EOF conditions (`ch < 0.0`).
  - [x] Return empty string `""` on blank lines / whitespace-only entries.
  - [x] Free buffer appropriately on EOF path to prevent heap leak.

- [x] **Gate 2: Transformer Zero-Copy Shared KV Layer Optimization**
  - [x] Update `cartan_manifold_layer_forward_batch_int8` in `src/std/transformer.cl`.
  - [x] Remove `memcpy` calls for `cur_k`/`prev_k` and `cur_v`/`prev_v` when `is_kv_shared == 1.0`.
  - [x] Route `kv_source_layer` to layer 23.0 (if global) or layer 22.0 (if sliding window) when `layer_idx >= 24.0`.
  - [x] Direct `k_cache` and `v_cache` pointers to `kv_source_layer`.

- [x] **Gate 3: Context Horizon Normalization**
  - [x] Update default `g_chat_context_limit` in `test/geomind/chat.cl` from 131,072 to 8,192 tokens.
  - [x] Update default `-context` parameter in `test/geomind/main.car` from 131,072 to 8,192 tokens.
  - [x] Verify `/context` command and CLI `-context 131072` remain fully operational.

- [x] **Gate 4: Build, Bootstrap & Empirical Verification**
  - [x] Rebuild compiler: `cartanc.exe build src/cartanc/main.car -o bin/cartanc.exe`.
  - [x] Rebuild GeoMind: `bin/cartanc.exe build test/geomind/main.car -o bin/geomind.exe`.
  - [x] Execute multi-turn interactive session test to verify Turn 2+ continuity.
  - [x] Run compiler regression suite (`tools/run_affected_tests.ps1`).

- [x] **Gate 5: Retrospective & Documentation**
  - [x] Update `ISSUES.md` (record and resolve ISSUE-373, ISSUE-374, ISSUE-375).
  - [x] Update `docs/ROADMAP.md` (record Sprint 518 completion).
  - [x] Update `CHANGELOG.md`.
  - [x] Author `docs/archive/sprint_518_walkthrough.md`.
