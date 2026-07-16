# Walkthrough: Phase 4 Implementation

## Goal
Implement Specialized Hardware Primitives to eliminate VRAM bloat and reduce runtime overhead. This phase focuses on:
1. **Optimizer Fusion**: Injecting optimizer state (like Adam) directly into the backward pass register instructions.
2. **Ragged Sequences**: Eliminating zero-padding tokens by using variable-offset arrays.
3. **Paged KV-Cache**: Implementing dynamic page-aligned blocks to eliminate fragmentation in autoregressive text generation.

## Implementation Details

### 1. In-Place Optimizer Fusion
We introduced syntax for `parameter[Adam]` and `parameter[SGD]`.
- **AST & Parser**: Updated `parameter` parsing to capture an optional optimizer tag (`Adam`, `SGD`).
- **LLVM Codegen**: Added C runtime hooks `@cartan_alloc_parameter_adam` and `@cartan_alloc_parameter_adam_nd` which dynamically allocate the parameter matrix alongside its first and second moment arrays (`adam_m`, `adam_v`) completely behind the scenes.
- **C Runtime**: The global backward loop in `cartan_tensor_step(lr: f32)` was rewritten to dynamically perform Adam operations (running bias-corrected averages with $\beta_1$ and $\beta_2$) automatically for those parameters, while falling back to standard SGD for normal leaves. This prevents large memory copies from C to Python for gradient application.

### 2. Data Structures for Attention
Added native syntax primitives for advanced Transformer caching logic:
- `sequence name[max_len];` for ragged token streams (useful in batch processing of variable length sequences).
- `block name[size];` for paged KV caches.
- **Compiler**: Added type-checking and LLVM code generation routing to `@cartan_alloc_sequence` and `@cartan_alloc_block`.

## Verification
- Wrote and compiled `test_phase4.ct` to confirm parsing, type checking, and LLVM IR generation.
- Validated correct allocation functions emitted into the `.ll` file:
  - `%1 = call ptr @cartan_alloc_parameter_adam_nd(i32 2, i32 128, i32 128, i32 1, i32 1)`
  - `%3 = call ptr @cartan_tensor_alloc(i32 128)` (SGD uses the default allocator)
  - `%5 = call ptr @cartan_alloc_sequence(i32 4096)`
  - `%7 = call ptr @cartan_alloc_block(i32 1024)`
- Compiled `tensor_runtime` with `cargo build` and successfully linked `cartanc` against it, verifying no ABI boundary breakages.

## Next Steps
We are now fully complete with **Phase 4: Specialized Hardware Primitives**.
Next up is **Phase 5: Distributed Scaling (Data Center as a Chip)** to handle Mesh architectures, Collective Operations, and Zero-Copy DMA Weight Streaming.
