# Sprint 483 Task List: Native CARTAN Self-Hosting

## Gate 1: Compiler Core Inlining & SIMD Intrinsics
- [x] **Task 1.1**: In `src/cartanc/llvm_codegen.car`, add `alwaysinline` attribute to definitions of `@cartan_f32_at` and `@cartan_set_f32`.
- [x] **Task 1.2**: In `src/cartanc/llvm_codegen.car`, implement native `cartan_simd_dot_f32(ptr, ptr, double)` emitting 8-way unrolled `<8 x float>` FMA vector operations.
- [x] **Task 1.3**: In `src/cartanc/lexer.car`, add `%` and `%=` tokenization and integrate `@cartan_f32_ptr_add` in `llvm_codegen.car`.
- [x] **Task 1.4**: Rebuild `cartanc.exe` using self-hosted toolchain; prove mathematical fixpoint convergence across stages 2 and 3 (SHA256: `9573E2A617626F4CC210E3762B07444963B5BE7ABDFD553CFAC642DCE62FA4DA`).

## Gate 2: Pure CARTAN LM Head Soft-Cap Integration
- [x] **Task 2.1**: In `test/geomind/chat.cl`, reimplement `cartan_compute_lm_head_softcap_native` in pure CARTAN using `cartan_simd_dot_f32`.
- [x] **Task 2.2**: Remove `c_cartan_compute_lm_head_softcap` declaration and invocation; `#if 0` in `src/std/cartan_native_io.c`.

## Gate 3: Pure CARTAN 42-Layer Decoder Execution
- [x] **Task 3.1**: In `src/std/transformer.cl`, implement `cartan_gemma_layer_forward_native` in pure CARTAN using `cartan_simd_dot_f32`, pinned scratch arenas, and `floor(qh / heads_per_kv)`.
- [x] **Task 3.2**: In `test/geomind/chat.cl`, replace all calls to `c_cartan_gemma_layer_forward_fast` with pure CARTAN pipeline (`cartan_gemma_layer_forward_raw`).
- [x] **Task 3.3**: Purge `c_cartan_gemma_layer_forward_fast` from active code; `#if 0` in `src/std/cartan_native_io.c`.

## Gate 4: Empirical Chat Verification, Regression Clearance & Binary Sync
- [x] **Task 4.1**: Recompile `geomind.exe` with Zig `-O3` LTO using promoted self-hosted `cartanc.exe`.
- [x] **Task 4.2**: Synchronize all 4 distribution binaries (`bin/geomind.exe`, `build/geomind.exe`, `test/geomind/geomind.exe`, `./geomind.exe`) with SHA256 `E1224DA00DBF26E8C19BAA334B97AB54DABE671A97F7323CDE149854C0126670`.
- [x] **Task 4.3**: Test interactive chat with prompt `"What is the capital of Iran"` verifying `"The capital of Iran is **Tehran**."`.
- [x] **Task 4.4**: Verify compiler test suite targets with zero regressions.
- [x] **Task 4.5**: Update `CHANGELOG.md`, `ISSUES.md`, and save `docs/archive/sprint_483_walkthrough.md`.
