# Sprint 315 Pre-Sprint Scrum Plan: Manifold RMSNorm & Conversational Stability

## 1. Context & Code Review Discoveries
- **Compiler Toolchain Sync**: `C:\Users\rich-\.cartan\bin\cartanc.exe` was rebuilt and synchronized from `src/cartanc/main.car`, restoring LLVM codegen definitions for `cartan_byte_at` and `cartan_set_byte`.
- **Manifold Activation Explosion**: In `test/geomind/e8_attention_engine.cl`, 16 un-normalized GeLU+FFN updates without LayerNorm compounded activations exponentially into $10^{17}$ over 4 autoregressive token steps, yielding `NaN` and access violation `0xC0000005`.
- **Doubt Argument Alignment**: In `test/geomind/chat.cl`, `cartan_doubt_checkpoint` and `cartan_doubt_rewind` were passing `prev_h` instead of the tangent bundle momentum vector `mom`.

## 2. Sprint 315 User Stories & Tasks
- **Story 1: Manifold RMSNorm Normalization**:
  - Implement `cartan_tensor_rmsnorm(v: ptr, eps: float)` in `test/geomind/e8_attention_engine.cl`.
  - Apply RMSNorm across layer transitions in `e8_attention_forward_step_with_momentum`.
- **Story 2: Doubt Verification Signature Alignment**:
  - Update `test/geomind/chat.cl` lines 340 and 357 to initialize and pass momentum vector `mom`.
- **Story 3: End-to-End Empirical Verification**:
  - Rebuild `geomind.exe` using `cartanc build test/geomind/main.car -o build/geomind.exe`.
  - Validate interactive `--chat` prompt generation across 20+ autoregressive tokens with stable confidence and entropy.
  - Validate `--train-webgpu`, `--train-ce`, and regression test suite (62/62 PASS).
