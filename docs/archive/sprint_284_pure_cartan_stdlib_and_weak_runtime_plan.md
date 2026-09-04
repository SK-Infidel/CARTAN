# Sprint 284 Implementation Plan: Porting Remaining 14 C Runtime Functions to Pure CARTAN Standard Library

## Objectives
1. **Port Async/Await Coroutine Stubs to Pure CARTAN (`src/std/async.cl`)**:
   - Implement `cartan_async_spawn`, `cartan_async_yield`, `cartan_async_await` in pure CARTAN.
   - Satisfies `test_async_coroutines.car`.

2. **Port SWMR & VRAM Capability Locks to Pure CARTAN (`src/std/security.cl`)**:
   - Implement `cartan_rt_vram_lock_parameters`, `cartan_rt_vram_unlock_parameters`, `cartan_rt_check_vram_access`, `cartan_rt_lock_swmr`, `cartan_rt_unlock_swmr` in pure CARTAN.
   - Satisfies `test_security_sandboxing.car`.

3. **Port Slicing & DLPack Interop to Pure CARTAN (`src/std/collections.cl`, `src/std/tensor.cl`)**:
   - Implement `cartan_slice_tree` and `cartan_slice_nd` in `src/std/collections.cl`.
   - Implement `cartan_tensor_to_dlpack` and `cartan_tensor_from_dlpack` in `src/std/tensor.cl`.
   - Satisfies `test_slices_tuples.car` and `test_dlpack_slicing.car`.

4. **Port Autograd & C Header Exporter to Pure CARTAN (`src/std/calculus.cl`, `src/std/fs.cl`)**:
   - Implement `cartan_rt_autograd_forward_grad` in `src/std/calculus.cl`.
   - Implement `cartan_export_c_headers` in `src/std/fs.cl`.
   - Satisfies `test_comptime_autograd.car` and `test_static_assert.car`.

5. **Mark All 14 C Runtime Functions as `CARTAN_WEAK` in `core_runtime.c`**:
   - Prevent symbol collisions and allow complete substitution by pure CARTAN stdlib.

6. **Regression Verification**:
   - Compile and execute all 47 test targets with `cartanc.exe`.
