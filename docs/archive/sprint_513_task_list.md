# Sprint 513 Task List: Configurable 128k Context Window Architecture

- [x] **Task 1: Core KV Cache & Buffer Scalability (`src/std/transformer.cl`)**
  - [x] Implement `g_kv_cache_max_seq: float = 2048.0` default in transformer library for fast unit test execution.
  - [x] Implement `cartan_kv_cache_set_capacity(max_seq: float) -> float`.
  - [x] Implement `cartan_kv_cache_get_capacity() -> float`.
  - [x] Update `cartan_kv_cache_init()`: allocate 24 layers * `g_kv_cache_max_seq` * 1024 floats.
  - [x] Update `cartan_kv_cache_get_k()` and `cartan_kv_cache_get_v()` to use `g_kv_cache_max_seq * 1024.0` stride.
  - [x] Resize `g_trans_scores` in `cartan_init_transformer_scratch_buffers` to `g_kv_cache_max_seq * 4.0` to prevent overflow.
  - [x] Replace all hardcoded `2048.0` and `4096.0` sequence bounds in native forward and batch forward with `g_kv_cache_max_seq`.
  - [x] Apply adaptive RoPE theta scaling: `rope_theta * (g_kv_cache_max_seq / 2048.0)`.

- [x] **Task 2: Model Driver & REPL Integration (`test/geomind/chat.cl`, `test/geomind/main.car`)**
  - [x] Implement `g_chat_context_limit: float = 131072.0` in `test/geomind/chat.cl`.
  - [x] Implement `geomind_chat_set_context_limit(limit: float)` and `geomind_chat_get_context_limit()`.
  - [x] Update FIFO context window guard to `g_chat_session_pos + guard >= g_chat_context_limit`.
  - [x] Parse `-context` / `--context` in `test/geomind/main.car` with default 131072.0 (with `=` syntax support).
  - [x] Implement `/context [N]` command in `test/geomind/main.car` REPL.
  - [x] Normalize biometric camera subprocess path with backslashes (`\`) for Windows `cmd.exe /c` execution (`[ISSUE-368]`).

- [x] **Task 3: Build & Verification**
  - [x] Rebuild `bin/geomind.exe` with `cartanc.exe`.
  - [x] Synchronize binaries across `bin/`, root, and `test/geomind/`.
  - [x] Verify 128k context allocation and prompt inference live.
  - [x] Run affected compiler suite targets (`tools/run_affected_tests.ps1 -Sprint 513`): 5/5 passed.

- [x] **Task 4: Sprint Review & Retrospective**
  - [x] Update `ISSUES.md`: add `[ISSUE-367]` and `[ISSUE-368]` as `[FIXED]`.
  - [x] Update `CHANGELOG.md` with version entry `[8.469.0]`.
  - [x] Save walkthrough to `docs/archive/sprint_513_walkthrough.md`.
