# Pre-Sprint Scrum & Implementation Plan: Sprint 99 — Original GeoMind (.ctn) Codebase Modernization & Architecture Upgrade

**Sprint Goal:** Modernize the original GeoMind legacy `.ctn` codebase into clean, bare-metal, self-hosting modern CARTAN (`.car`) source files using `cartanc.exe`, integrating all recent language, compiler, standard library, non-Euclidean geometry, and generative GEMM advancements.  
**Date:** August 11, 2026  
**Archive File:** `docs/archive/sprint99_geomind_ctn_modernization_plan.md`  

---

## I. Pre-Sprint Scrum: Code Review Discoveries & Findings

### 1. Key Discoveries from the Code Review
- **Syntax & Language Evolution**: The original GeoMind codebase in `C:\Users\rich-\source\repos\GeoMind\source` was authored in an early iteration of CARTAN using `.ctn` extensions, raw un-typed tensor buffers, manual C-style heap linked-lists (`tokenizer.ctn`), and un-tiled matrix multiplication.
- **Modern CARTAN Capabilities Available**:
  1. **Typestate Declarations**: `parameter[Adam]`, `in Minkowski`, `in PoincareDisk`, `layout(Tiled(8,8))`, and `@location("hbm")`.
  2. **Standard Library Abstractions (`src/std/`)**: Modular implementations of hardware autotuning (`std::autotune`), SLERP/TIES weight fusion (`std::fusion`), KL divergence distillation (`std::distill`), SentencePiece/BPE tokenizers (`std::tokenizer`), WordNet LCA semantic tree distance (`std::semantics`), and $E_8$ geometry (`std::geom`).
  3. **Dual Inverse Randers Backpropagation**: Sherman-Morrison inverse metric projections ($G^{-1} = I - \frac{b b^T}{1 + \|b\|^2}$) in `geometry.car` (`geomind_inverse_randers_backward_project`) and `engine.car` (`step_randers`).
  4. **Authentic 2D GEMM Generative Activations**: Matrix projections ($W_{\text{head}} \cdot h$) replacing trigonometric shortcuts across HuggingFace ($V=49,152$) and Gemma ($V=256,000$) vocabulary matrices.
  5. **Implicit CoT & Hopfield Energy Attractor Basins**: 32-layer continuous residual stream transformations ($h_0 \dots h_{32}$) with Banach fixed-point contraction mapping proofs.

### 2. Blocking Issues & Architectural Risks
- **Parser Keyword Collisions**: Identifiers matching compiler keywords (`grad`, `TileConfig`, `block`) must be systematically guarded or renamed to prevent AST parse errors.
- **C-ABI Linked Runtime Header Synchronization**: Any C-runtime modifications in `src/cartanc/c_runtime.c` MUST be synchronized with `C:\Users\rich-\.cartan\c_runtime.c` before building `.car` targets.
- **Struct Parameter Arity & Bounds Safety**: Pointer arguments and array indices must be strictly validated with `cartan_assert` and bounds checking.

### 3. Read-Ahead & Forward-Thinking Objectives
- **Zero Two-Language Overhead**: Ensure every upgraded component in `test/geomind/` compiles natively via `cartanc.exe` to LLVM IR / C binaries without external Python or C++ dependencies.
- **Extensible 8-Stream Subgroup Modular Architecture**: Preserve the mathematical elegance of the 8 maximal Lie subgroups ($SO(16)$, $E_7 \times SU(2)$, $E_6 \times SU(3)$, $SU(9)$, $F_4 \times G_2$, $SO(10) \times SU(4)$, $SU(5) \times SU(5)$, $SU(3)^3$) while leveraging modern `.car` standard library modules.

---

## II. Sprint 99 Implementation Task List

- [ ] **Task 1: Core Geometry & Anisotropic Metric Upgrade (`test/geomind/geometry.car`)**
  - Verify $E_8$ 248D lattice projection, Finsler-Randers metric calculations ($F = \alpha + \beta \lambda$), and Sherman-Morrison dual Randers metric backpropagation (`geomind_inverse_randers_backward_project`).

- [ ] **Task 2: 8-Stream & Sasaki Tangent Bundle MoE Upgrade (`test/geomind/moe.car` & `e8_attention_engine.car`)**
  - Wire `std::autotune` micro-kernel tiling (`autotune_matmul_tiled`) into the 8 geometric streams ($SO(16) \dots SU(3)^3$) and the $4 \times 4$ Freudenthal division algebra MoE grid ($\mathbb{R}, \mathbb{C}, \mathbb{H}, \mathbb{O}$).

- [ ] **Task 3: Engine & Generative 2D GEMM Unembedding Upgrade (`test/geomind/engine.car` & `chat.car`)**
  - Standardize 2D matrix inner products ($W_{\text{lm\_head}} \cdot h_{\text{relaxed}}$), continuous Hopfield spin relaxation (`ising_state_machine.car`), and LCA tree distance logit boosting (`src/std/semantics.car`).

- [ ] **Task 4: Pretraining, Fine-Tuning & Self-Play Integration (`test/geomind/sft_train.car` & `main.car`)**
  - Ensure `--train-sft`, `--merge-slerp`, `--train-distill`, `--rlaif`, and `--azr-selfplay` CLI flags execute cleanly.

- [ ] **Task 5: Native Compilation Verification & QA Sign-Off**
  - Rebuild release compiler `cartanc.exe` and compile native `geomind.exe`.
  - Execute `geomind.exe --help` and verify exit code 0 across compiler regression test suites.

---

## III. Verification Metrics & Success Criteria
1. `cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe` completes cleanly with **exit code 0**.
2. Native `geomind.exe --help` and `geomind.exe --mode chat` execute with 0 runtime errors.
3. SFT training loss converges cleanly with dual inverse Randers backpropagation enabled.
