# Sprint 524 Task List: Invariant-Safe Sparse Cortical MoE & Live Hippocampal Fast Weights

- [x] **Task 1: Pre-Sprint Scrum & Squad Alignment**
  - [x] Review Startup Code Review and architectural invariants with Architect, Runtime, and QA Squad leads.
  - [x] Validate invariant-safe layer 24 bypass boundary and 2560D semantic Hopfield vector representation.

- [x] **Task 2: Implement Invariant-Safe Sparse Cortical MoE Dynamic Routing**
  - [x] In `test/geomind/chat.cl`: Remove raw-embedding bypass from lines 2546-2582.
  - [x] Enforce that layers 0..23 execute unconditionally for all decode tokens, writing genuine KV cache entries.
  - [x] At layer 24: Evaluate Sasaki Brainstem router on $(h_{24}, \dot{h}_{24})$.
  - [x] If $w^* \ge g\_sasaki\_stream\_threshold$: Apply dominant Lie stream transformation to $h_{24}$ and bypass layers 25..40 directly to Anchor Layer 41.
  - [x] If $w^* < g\_sasaki\_stream\_threshold$: Pre-condition $h_{24}$ with 10% stream blend and proceed through remaining layers.

- [x] **Task 3: Implement Live Hippocampal Fast Weights & Semantic Memory Ingestion**
  - [x] In `test/geomind/main.car` / `test/geomind/chat.cl`: Upgrade `--ingest` to tokenize text chunks via `cartan_hub_encode_text_to_tokens`, compute 2560D mean-pooled embeddings, and register them as attractor basins in `g_hopfield_key_bank` / `val_bank`.
  - [x] In `test/geomind/chat.cl`: Enable dynamic 2560D Hopfield fast-weight ingestion (`cartan_hopfield_store_vector(cur_h, 2560.0)`) on completed turns.
  - [x] Enable continuous Hopfield associative relaxation on 2560D hidden states.

- [x] **Task 4: Compilation, Empirical Verification & Regression Testing**
  - [x] Rebuild `geomind.exe` with `cartanc.exe`.
  - [x] Run live prompt inference test (`-prompt "Hello" -tokens 30`) and verify 100% natural, coherent English output.
  - [x] Run `--ingest` on a sample document and verify genuine attractor creation and persistence in `hopfield_basins.bin`.
  - [x] Run compiler regression suite `tools/run_affected_tests.ps1 -Sprint 524`.

- [x] **Task 5: Documentation & Git Artifacts**
  - [x] Update `CHANGELOG.md` and `ISSUES.md`.
  - [x] Save `docs/archive/sprint_524_walkthrough.md`.
  - [x] Update `docs/ROADMAP.md`.
