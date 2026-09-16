# Sprint 329: Zero-Leak Persistent Tensor Buffers & Memory Reclamation Walkthrough

## Summary of Changes
- **Core Runtime Primitives**:
  - Implemented `cartan_vec_clear(v: ptr) -> float` in [`src/cartanc/core_runtime.car`](../../src/cartanc/core_runtime.car) to reset vector size to 0 while preserving underlying 64 KB capacity.
  - Implemented `cartan_vec_free(v: ptr) -> float` in [`src/cartanc/core_runtime.car`](../../src/cartanc/core_runtime.car) to safely deallocate heap-allocated vector buffers back to the OS via native `free()`.
  - Exposed both primitives in standard library module [`src/std/collections.cl`](../../src/std/collections.cl).
- **Manifold & Sasaki Routing Zero-Allocation Refactoring**:
  - Replaced dynamic allocations in `geomind_sasaki_stream_routing` ([`test/geomind/moe.cl`](../../test/geomind/moe.cl)) with persistent static scratch buffers `g_sasaki_weights` and `g_sasaki_logits`.
  - Updated `geomind_streams_manifold_forward_routed` ([`test/geomind/streams.cl`](../../test/geomind/streams.cl)) to mutate manifold vector `x` in-place, eliminating per-step allocations.
- **Streaming Steady-State Trainer Memory Reclamation**:
  - Preallocated `cur_h` in `geomind_train_streaming_steady_state` ([`test/geomind/train.cl`](../../test/geomind/train.cl)) once outside the epoch loop and reset it in-place before each chunk.
  - Deallocated transient token vectors (`cartan_vec_free(tokens)`) and text substrings (`free(sample_text)`) after each chunk step.
  - Added clean deallocation for `file_content` per dataset and `cur_h` upon completion or abort.

## Verification Results
1. **Self-Hosted Compiler & Binary Compilation**:
   - `cartanc.exe build src/cartanc/main.car -o bin/cartanc.exe` succeeded with exit code 0.
   - `cartanc.exe build test/geomind/main.car -o bin/geomind.exe` succeeded with exit code 0.
   - Synchronized across `bin/`, `build/`, and root.
2. **Empirical Memory Telemetry During Active Cloze Training**:
   - Polled process memory under active cloze training:
     - `T+0s: WorkingSet = 111.56 MB | PrivateMemory = 113.16 MB`
     - `T+5s: WorkingSet = 111.56 MB | PrivateMemory = 113.16 MB`
     - `T+9s: WorkingSet = 111.56 MB | PrivateMemory = 113.16 MB`
   - Zero memory growth observed across continuous token processing.
3. **Compiler Regression Test Suite**:
   - Ran `bin/run_tests.exe`: **47/47 PASS** with exit code 0.
