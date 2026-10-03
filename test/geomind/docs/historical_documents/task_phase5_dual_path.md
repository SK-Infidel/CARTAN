# Multi-Stream Engine Optimization

- `[/]` **Implement Asynchronous Multi-Threading**
  - `[ ]` Update `csrc/ocl_backend.h` to use `thread_local cl::CommandQueue`.
  - `[ ]` Wrap `GeoMindHybridEngine::forward` stream processing with `std::thread`.
  - `[ ]` Wrap `GeoMindHybridEngine::backward` stream processing with `std::thread`.

- `[ ]` **Eliminate Intermediate Buffer Thrashing**
  - `[ ]` Implement `tensor_add_inplace` kernel and C++ function in `engine.cpp`.
  - `[ ]` Remove `tensor_add`'s heap allocation of `std::unique_ptr<Tensor>`.
  - `[ ]` Delete unnecessary `stream_outputs` caching loop in `forward`.

- `[ ]` **Implement Sparse "Ghost" Streams**
  - `[ ]` Add `active_stream_mask` argument to `forward` and `backward` signatures in `engine.h` and `engine.cpp`.
  - `[ ]` Update Python bindings in `bindings.cpp` to expose `active_stream_mask`.
  - `[ ]` Add gating logic to skip computing and allocating memory for inactive streams (`mask & (1 << s) == 0`).
  - `[ ]` Update `core/training_engine.py` to calculate the `active_stream_mask` dynamically using `ContextRouter` prior to the forward pass.

- `[ ]` **Verification**
  - `[ ]` Recompile C++ extensions.
  - `[ ]` Run test to verify async streams don't deadlock and memory drops.
