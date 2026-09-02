# Sprint 261 Implementation Plan: Full-Stack Compiler & Runtime Optimization

## Sprint Goal
Execute end-to-end performance optimizations across the CARTAN compiler code generator, standard library memory pools, SentencePiece vocabulary trie, and OpenCL GPU streaming pipeline.

---

## User Stories & Phased Tasks

### Story 1: Compiler Vectorization & Inlining (`src/cartanc/main.car`, `src/cartanc/llvm_codegen.car`)
- Upgrade Zig compilation flags in `src/cartanc/main.car` from `-O2` to `-O3 -flto -march=native -ffast-math`.
- Ensure native executables benefit from loop vectorization, inter-procedural optimization (IPO), and SIMD instructions.

### Story 2: Flat Contiguous Vocabulary Trie Arena (`src/cartanc/c_runtime.c`, `src/std/tokenizer.cl`)
- Replace fragmented `calloc` node allocations with a single contiguous `CartanTrieNode` arena pool.
- Enable high-locality $O(L)$ cache-aligned prefix matching across 256,000 vocabulary tokens.

### Story 3: Standard Library Vector & String Memory Tuning (`src/std/string.cl`, `src/std/collections.cl`)
- Optimize buffer allocations and eliminate redundant copy operations.

### Story 4: Double-Buffered OpenCL GPU Queue Tuning (`src/cartanc/c_runtime.c`)
- Streamline asynchronous micro-batch pipeline for non-blocking PCIe transfers.

### Story 5: Empirical Verification & Regression Testing
- Recompile self-hosted `cartanc.exe` with new optimization flags.
- Recompile `bin/geomind.exe` and verify zero regressions across all modes.
