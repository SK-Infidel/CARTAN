# Sprint 457 Walkthrough: AST Variant Hardening, Statement Collisions & Attention/Fused Codegen

## Overview & Mission
Sprint 457 hardened the CARTAN self-hosted compiler frontend, AST declarations, and code generation pipelines to eliminate statement and expression discriminant collisions, provide authentic native `@attention` runtime execution, support `fuse { ... }` kernel execution, enable full multi-argument `MethodCall` parameter dispatch, and define missing AST enum variants.

---

## Key Achievements & Implementation Details

### 1. Statement & Expression Discriminant Collision Rectification (`[ISSUE-237]`, `src/cartanc/llvm_codegen.car`)
- Aligned obsolete statement line indices to canonical `ast.ch:enum Stmt` definitions:
  - `SequenceDecl`: aligned to `9.0 || 127.0` (unblocking `EvolveBlock` at 32.0).
  - `BlockDecl`: aligned to `10.0 || 128.0` (unblocking `ImplDecl` at 34.0).
  - `LatticeDecl`: aligned to `11.0 || 129.0` (unblocking `Spawn` at 36.0).
  - `TreeDecl`: aligned to `12.0 || 130.0` (unblocking `JitBlock` at 39.0).
  - `ParameterDecl`: aligned to `7.0 || 125.0` (unblocking `Throw` at 21.0).
  - `ExternFunctionDecl`: aligned to `15.0 || 133.0` (unblocking `MultimodalBlock` at 48.0).
  - `Block`: aligned to `40.0 || 158.0` (unblocking `Spawn` at 36.0).
  - `FunctionCall`: aligned to `17.0 || 81.0` (unblocking `Expr::Attention` at 27.0).

### 2. AST Variant Declarations & Type Safety (`[ISSUE-238]`, `src/cartanc/ast.ch`, `src/cartanc/type_checker.car`, `src/cartanc/llvm_codegen.car`)
- Declared 5 previously missing enum variants in `src/cartanc/ast.ch:enum Expr`:
  - `SievingCacheInit` (51.0 / 115.0)
  - `FractalAttentionInit` (52.0 / 116.0)
  - `ElasticVocabularyInit` (53.0 / 117.0)
  - `SpikePrimitive` (54.0 / 118.0)
  - `NeuronPrimitive` (55.0 / 119.0)
- Added dual discriminant typing in `src/cartanc/type_checker.car` returning `CartanType::Ptr` and `CartanType::Float`.
- Added LLVM IR lowering in `src/cartanc/llvm_codegen.car` allocating tree instances or primitive values.

### 3. Authentic `@attention` Primitives & Codegen (`[ISSUE-239]`, `src/cartanc/core_runtime.car`, `src/cartanc/lexer.car`, `src/cartanc/parser.car`, `src/cartanc/llvm_codegen.car`)
- Implemented authentic `cartan_attention(target: ptr, routing: ptr) -> ptr` in `src/cartanc/core_runtime.car`:
  - Computes RMS norm across target dimensions: $\text{rms} = \sqrt{\frac{1}{N} \sum t_i^2 + 10^{-6}}$.
  - Computes Sigmoid gating from routing vector: $g_i = \frac{1}{1 + e^{-r_i}}$.
  - Emits scaled, modulated output: $o_i = \frac{t_i}{\text{rms}} \cdot (1.0 + g_i)$.
- Implemented `cartan_init_fractal_attention() -> ptr` initializing hierarchical attention vectors `[1.0, 0.5, 0.25]`.
- Exported top-level wrapper `fn attention(target: ptr, routing: ptr) -> ptr`.
- Enhanced `src/cartanc/lexer.car` to tokenize `@` prefix operators (`@attention`, `@simd`, `@inbounds`).
- Updated `src/cartanc/parser.car:unary` to parse arbitrary routing expressions `routing = <expr>`.
- Lowered `Expr::Attention` (27.0 / 91.0) in `src/cartanc/llvm_codegen.car` calling `@cartan_attention`.

### 4. `fused { ... }` Kernel Codegen (`[ISSUE-240]`, `src/cartanc/type_checker.car`, `src/cartanc/llvm_codegen.car`)
- Added dual discriminant typing (`26.0 || 90.0`) in `src/cartanc/type_checker.car`.
- Lowered `Expr::FusedKernel` in `src/cartanc/llvm_codegen.car:llvm_visit_expr`: traverses statements within the block, evaluates intermediate effects, and returns the evaluated register of the terminal expression statement.

### 5. Multi-Parameter `MethodCall` Argument Dispatch (`[ISSUE-241]`, `src/cartanc/llvm_codegen.car`)
- Updated discriminant check to `18.0 || 82.0`.
- Iterated across all arguments in `args`, evaluating each parameter node, determining pointer vs float typing, and formatting complete parameter lists:
  `call <ret_type> @cartan_method_<name>(ptr clean_obj, double/ptr arg1, ...)`

---

## Empirical Verification Results

### 1. Target 67 Regression Test (`test/compiler_suite/test_attention_fused_methods.car`)
- **Test 1**: Authentic `@attention(routing = routing) tgt` and `attention(tgt, routing)` wrapper:
  - Output values verified positive, non-uniform, matching between direct operator and wrapper function.
- **Test 2**: `fuse { ... }` kernel block:
  - Correctly executed inner expressions $(14.5 \times 3.0 + 2.5) - 6.0 = 40.0$.
- **Test 3**: Multi-parameter `MethodCall` dispatch:
  - Invoked `test_vec.compute_weighted(4.0, 5.0)` producing $(3.0 + 7.0) \times 4.0 + 5.0 = 45.0$.
- **Test 4**: `FractalAttentionBlock` initialization:
  - Verified hierarchy levels `[1.0, 0.5, 0.25]`.
- **Test 5**: Statement declarations:
  - `sequence`, `block`, `lattice`, and `tree` declarations executed cleanly with non-null pointer allocation.

### 2. Full Regression Suite (`build/run_tests.exe`)
- Rebuilt `cartanc.exe` with all frontend, AST, and codegen changes.
- Rebuilt `build/run_tests.exe` with Target 67 registered.
- **Result**: **All 67 compiler snapshot test targets executed successfully with 0 failures (Exit Code 0).**

---

## Deliverables & Artifacts
- `src/cartanc/ast.ch`: Added 5 enum variants to `Expr`.
- `src/cartanc/core_runtime.car`: Added `cartan_attention`, `attention`, and `cartan_init_fractal_attention`.
- `src/cartanc/lexer.car`: Added `@` operator lexing and keyword recognition.
- `src/cartanc/parser.car`: Enhanced `@attention` routing parsing.
- `src/cartanc/type_checker.car`: Added typing for new variants, `FusedKernel`, and `Attention`.
- `src/cartanc/llvm_codegen.car`: Rectified statement & expression discriminant collisions, declared externs, lowered new AST variants, `FusedKernel`, and multi-argument `MethodCall`.
- `test/compiler_suite/test_attention_fused_methods.car`: Target 67 regression test.
- `test/compiler_suite/run_tests.car`: Updated suite to 67 targets.
- `ISSUES.md`: `[ISSUE-237]` through `[ISSUE-241]` marked `[FIXED]`.
- `CHANGELOG.md`: Logged release `[8.415.0]`.
- `docs/roadmap.md`: Updated Phase 17 milestone list.
- `docs/archive/sprint_457_task_list.md`: Checked off all tasks.
