# Sprint 329: Zero-Leak Persistent Tensor Buffers & Working Memory Plan

## 1. Context & Objective
- **Problem**: Long-running streaming cloze training (`--train-cloze`) allocated fresh 64 KB heap buffers (`cartan_vec_create`) on every token step inside `geomind_train_streaming_steady_state` and `e8_attention_forward_step`, accumulating 255 GB of unreleased virtual memory and crashing the Windows DWM / Antigravity session ([`ISSUE-078`](../../ISSUES.md#issue-078)).
- **Goal**: Achieve strict zero-allocation steady-state training ($O(1)$ memory consumption) across millions of cloze tokens by introducing `cartan_vec_free` and persistent ping-pong working buffers.

## 2. Architectural Design: Lowest-Entropy Solution
1. **Core Runtime Primitive (`src/cartanc/core_runtime.car`)**:
   - Introduce `cartan_vec_free(v: ptr) -> float` wrapping native `free(v)`.
   - Expose in runtime header and standard library.
2. **GeoMind Attention Engine In-Place/Ping-Pong Buffers (`test/geomind/e8_attention_engine.cl`, `test/geomind/streams.cl`)**:
   - Establish dedicated double-buffered scratch vectors (`g_stream_buf_a`, `g_stream_buf_b`, `g_route_weights_buf`) pre-allocated once on first use.
   - Mutate stream activations in-place or swap ping-pong buffer pointers instead of calling `cartan_vec_create()` on every token step.
3. **Steady-State Training Loop Zero-Allocation (`test/geomind/train.cl`)**:
   - Allocate `g_train_cur_h` working buffer once.
   - Cleanly release transient token vectors and chunk substring allocations with `cartan_vec_free` / `cartan_string_free` at the end of each chunk.
4. **Verification & DoD**:
   - Compile `cartanc.exe` and `geomind.exe`.
   - Run `--train-cloze` continuously for 500+ steps while monitoring process memory with PowerShell (`Get-Process geomind | Select-Object WorkingSet64, PrivateMemorySize64`).
   - Confirm RSS/Virtual Memory remains completely constant ($\le 120\text{ MB}$) with 0 growth.

## 3. Sprint Task Breakdown
- [ ] **Task 1**: Implement `cartan_vec_free` in [`src/cartanc/core_runtime.car`](../../src/cartanc/core_runtime.car) and recompile `cartanc.exe`.
- [ ] **Task 2**: Convert `geomind_streams_manifold_forward_routed` and `cartan_sasaki_brainstem_route_vec` to reusable static scratch buffers.
- [ ] **Task 3**: Refactor `geomind_train_streaming_steady_state` in [`test/geomind/train.cl`](../../test/geomind/train.cl) to eliminate transient vector leaks.
- [ ] **Task 4**: Empirically verify memory stability under active cloze training and update `CHANGELOG.md` & `ISSUES.md`.
