# Sprint 525 Plan: Continuous Hopfield Speculative Burst Persistence & Dynamic Rejection Rollback

## Sprint Goal
Enable persistent Continuous Hopfield speculative burst drafting across process lifetimes by upgrading `hopfield_basins.bin` to Version 3 serialization, coupling candidate token sequences to semantic attractor basins during `--ingest`, and enforcing thermodynamic early exit and clean KV cache rollback during speculative verification.

---

## User Stories & Architecture Formulations

### 1. Version 3 Binary Basin Serialization ([ISSUE-383](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md))
- **Problem**: In [`src/std/resonator.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/resonator.cl), `resonator_save_basins` and `resonator_load_basins` write only key and value matrices (Version 2). `g_hopfield_draft_token_bank` is omitted, causing cold starts to always report `Speculative: 0/0 accepted`.
- **Architecture**:
  - Upgrade header version to `3.0`.
  - For each basin $k < \text{num\_basins}$:
    - Serialize token burst length $N_k = \text{len}(\text{seq}_k)$ (8-byte float).
    - Serialize $N_k$ token IDs (each 8-byte float).
  - In `resonator_load_basins`:
    - Read Version 3 format, populating `g_hopfield_draft_token_bank` with authentic token vectors.
    - If reading legacy Version 1 or 2, gracefully initialize empty token sequences to preserve backward compatibility.

### 2. Semantic Token Burst Ingestion during `--ingest`
- **Problem**: `geomind_hopfield_ingest_semantic` in [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl) pools token embeddings into attractor basins, but does not attach token bursts to `g_hopfield_draft_token_bank`.
- **Architecture**:
  - For each 32-token chunk, extract the first 5–8 tokens into a token burst vector.
  - Store attractor key and token burst via `cartan_hopfield_store_speculative_burst(v_mean, tok_burst, burst_len)`.
  - Save updated basins (keys, values, and token bursts) to `hopfield_basins.bin`.

### 3. Thermodynamic Speculative Verification & KV Cache Rollback
- **Problem**: Speculative candidate verification runs all 42 layers unconditionally and does not manage rejected token KV cache indices.
- **Architecture**:
  - In [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl), ensure speculative candidate verification only commits accepted tokens to sequence history and logs accurate telemetry.
  - Add `cartan_kv_cache_clear_range` in [`src/std/transformer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl) to explicitly clear rejected speculative token positions.

---

## Definition of Done (DoD)
1. `hopfield_basins.bin` saves and loads Version 3 format with token bursts preserved.
2. `--ingest` populates both 2560D attractor basins and candidate token bursts.
3. Live prompt inference on `geomind.exe` successfully drafts and accepts candidate tokens from familiar contexts.
4. Regression test suite (`tools/run_affected_tests.ps1 -Sprint 525`) passes with zero regressions.
5. All artifacts (`sprint_525_plan.md`, `sprint_525_task_list.md`, `sprint_525_walkthrough.md`) written to `docs/archive/`.
6. `CHANGELOG.md` updated with `[8.481.0]`.
