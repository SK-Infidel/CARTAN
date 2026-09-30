# Sprint 484 Plan: Eradicating Inference Stubs, Logit Hacks & Remaining C Runtime Kernels

## 1. Context & Motivation
Following the comprehensive code review audit with Rick, this sprint eliminates all artificial heuristics, hardcoded string fallback tables, logit suppression clamps, and remaining C runtime bypass kernels in `cartan_native_io.c`.

---

## 2. Sprint 484 Architecture & Deliverables

### A. Gate 1: Standard Library NSES Hygiene (`src/std/nses_pipeline.cl`)
1. **Purge Hardcoded String Table**:
   - Completely remove lines 360–485 containing 40+ hardcoded string branches (`if (n_id == 6.0) ...`).
2. **Dynamic Knowledge Retrieval**:
   - When a node ID is traversed in BFS, retrieve text from `pipe.graph_file`. If absent, query SQLite cognitive memory (`pipe.db`). If still unbacked, record an unresolved node metric and skip without injecting synthetic strings.

### B. Gate 2: Chat Inference Purity (`test/geomind/chat.cl`)
1. **Purge Leading Punctuation Logit Clamping**:
   - Delete manual clamping at lines 1419–1425 (`cartan_vec_set_f32(logits_vec, 236881.0, -10000.0)`).
2. **Clean Conceptual Steering**:
   - Remove arbitrary additive logit boosts (`semantics_apply_concept_logit_boost(+4.0)`).
   - Route domain concept guidance through authentic latent state priming ($h' = 0.85 \cdot h + 0.15 \cdot v_{\text{concept}}$) before transformer execution.

### C. Gate 3: Eradicate Remaining C Compute & Memory Bypasses (`src/std/cartan_native_io.c`)
1. **Pure CARTAN Analogy Search**:
   - Port `c_cartan_analogy_search_topk` to native CARTAN in [`src/std/geom.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/geom.cl) using `@cartan_simd_dot_f32`.
   - Update [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car) to call the native CARTAN function.
2. **Pure CARTAN KV Cache & PLE Arenas**:
   - Manage the 411 MB KV cache arena in pure CARTAN in [`src/std/transformer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl).
   - Implement `cartan_update_pli_cache` natively in CARTAN.
3. **Generic `cartan_mmap_file` Compiler Intrinsic**:
   - Implement `cartan_mmap_file(path: string) -> ptr` in [`src/cartanc/llvm_codegen.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/llvm_codegen.car) and standard runtime.
4. **Purge Dead C Kernels**:
   - Delete unused functions in [`src/std/cartan_native_io.c`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/cartan_native_io.c).

### D. Gate 4: Empirical Chat & Full Regression Clearance
1. Recompile `cartanc.exe` and `geomind.exe`.
2. Verify interactive chat with `"What is the capital of Iran"` retains authentic bit-accurate answer without any logit clamps.
3. Verify all 87 compiler regression test targets pass with zero regressions.
4. Synchronize all 4 production binaries.
