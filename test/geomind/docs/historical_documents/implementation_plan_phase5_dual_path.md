# OpenCL Multi-Stream Pipeline Optimization

Following an investigation into the multi-stream execution pipeline in `csrc/engine.cpp` and `csrc/modules.cpp`, several severe efficiency flaws and memory management issues were identified.

## User Review Required

> [!IMPORTANT]
> **Asynchronous Multi-Threading**: To solve the synchronous stream blocking, I plan to introduce C++ `std::thread` to execute the 7 streams simultaneously. To ensure OpenCL safely routes these concurrently to the GPU, I will modify `OCLBackend` to use a `thread_local` CommandQueue. This is a significant architectural change to the GPU backend but will massively increase GPU utilization.

## Proposed Changes

### 1. Synchronous Stream Blocking
Currently, `GeoMindHybridEngine::forward` processes the 7 geometry streams inside a blocking `for` loop. Stream 0 executes on the GPU and blocks the CPU until finished, completely starving Streams 1-6. This drastically underutilizes the GPU's parallel compute cores.

#### [MODIFY] csrc/ocl_backend.h & csrc/ocl_backend.cpp
- Convert the global `cl::CommandQueue` into a `thread_local cl::CommandQueue`. This will allow any new C++ thread to automatically receive its own independent OpenCL command queue, allowing the GPU driver to natively schedule kernels concurrently.

#### [MODIFY] csrc/engine.cpp
- Wrap the 7-stream loop in `GeoMindHybridEngine::forward` and `GeoMindHybridEngine::backward` with `std::thread`s (or `std::async`).
- Join the threads at the end of the loop.
- **Effect**: Streams will execute strictly in parallel.

### 2. Redundant `tensor_add` Heap Allocations
Inside the accumulation loops in `engine.cpp`, `tensor_add` is used to sum the stream outputs. Under the hood, `tensor_add` invokes `std::make_unique<Tensor>`, triggering a CPU heap allocation for the tensor struct on every addition.

#### [MODIFY] csrc/engine.cpp
- Implement an optimized `tensor_add_inplace(Tensor& a, const Tensor& b)` which explicitly executes `a += b` via OpenCL without creating or returning a new `std::unique_ptr<Tensor>`.
- Replace all accumulation steps to use `tensor_add_inplace`.

### 3. Intermediate Buffer Over-Allocation
In `GeoMindHybridEngine::forward`, `stream_outputs.push_back(...)` forces an extra 1.9MB allocation and memory copy for every stream, just to hold the result before aggregation.

#### [MODIFY] csrc/engine.cpp
- Delete the `tensor_copy` into `stream_outputs`.
- Directly accumulate `stream->cache_->moe_out` into `final_agg` using the new `tensor_add_inplace`.

### 4. Sparse "Ghost" Streams (Conditional Execution)
Per your request, there is no need to fully allocate and compute streams that are not actively resonating with the current data domain. We will implement "Ghost Streams":

#### [MODIFY] csrc/engine.cpp & csrc/engine.h
- Update the `forward` and `backward` signatures to accept an `uint32_t active_stream_mask`.
- Inside the execution loop:
  ```cpp
  if ((active_stream_mask & (1 << s)) == 0) {
      // GHOST STREAM: Do zero work, allocate zero VRAM. 
      // Feed generic stub data (the residual Identity Map `x_base`) directly into the aggregator.
      tensor_add_inplace(*final_agg, *x_base);
      continue;
  }
  ```
- **Effect**: If a stream is gated out by the mask, it skips the `E8Attention`, `Norms`, and `MoE` layers entirely. It allocates **zero intermediate memory** and consumes **zero GPU compute**, radically reducing the overall pipeline VRAM overhead. 

#### [MODIFY] csrc/bindings.cpp & core/training_engine.py
- Expose the `active_stream_mask` to Python so the `NumpyContextRouter` can pre-determine the active streams and pass the sparse mask into the C++ engine.

## Verification Plan

### Automated Tests
- Run `python setup.py build_ext --inplace` to compile the new C++ backend.
- Execute `scratch/dynamic_routing_experiment.py` to ensure the mathematical outputs are identical and no race conditions occur in the OpenCL queues.

### Manual Verification
- Observe the step execution time before and after. The parallelization should yield a significant speedup in `tok/s` during the multi-stream pipeline execution.
