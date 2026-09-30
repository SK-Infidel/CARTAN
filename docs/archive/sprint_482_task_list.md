# Sprint 482 Task List: Genuine 42-Layer Transformer Chat Inference & Binary Sync

## Gate 1: Stopword Purge & Exact Lemma Resolution
- [x] **Task 1.1**: In `src/std/semantics.cl`, implement stopword filtering in `cartan_taxonomy_extract_primary_concept` to ignore generic articles and prepositions.
- [x] **Task 1.2**: In `src/std/semantics.cl`, update `cartan_taxonomy_resolve_path` to avoid substring matches on node paths, preventing false positives like `"the"` matching `"photosynthesis"`.

## Gate 2: High-Performance Memory-Mapped Layer Streaming
- [x] **Task 2.1**: In `src/std/cartan_native_io.c`, implement `c_cartan_mmap_layer(double layer_idx, const char* path)` supporting cached Windows `MapViewOfFile` mappings for all 42 layer files.
- [x] **Task 2.2**: In `test/geomind/chat.cl`, update `geomind_get_layer_buffer` to invoke `c_cartan_mmap_layer`.

## Gate 3: Genuine 42-Layer Transformer Decode Integration
- [x] **Task 3.1**: In `test/geomind/chat.cl`, replace the linear momentum formula in the generation loop with `geomind_execute_gemma_decode_step(sampled_tok, pos)` across all 42 layers.
- [x] **Task 3.2**: In `test/geomind/chat.cl`, execute proper KV cache ingestion during prompt processing so attention attends causally across the full conversation.

## Gate 4: Empirical Chat Verification, Regression Clearance & Binary Sync
- [x] **Task 4.1**: Recompile `geomind.exe` with Zig `-O3` LTO.
- [x] **Task 4.2**: Synchronize all 4 production binary locations: `build/geomind.exe`, `bin/geomind.exe`, `test/geomind/geomind.exe`, `./geomind.exe`.
- [x] **Task 4.3**: Test interactive chat with prompt `"What is the capital of Iran"`.
- [x] **Task 4.4**: Verify 4/4 affected regression targets in `tools/run_affected_tests.ps1 -Sprint 482`.
- [x] **Task 4.5**: Update `CHANGELOG.md`, `ISSUES.md`, and save `docs/archive/sprint_482_walkthrough.md`.
