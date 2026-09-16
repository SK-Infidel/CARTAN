# Sprint 335 Walkthrough: Freestanding GPU Compute Subsystem & 0% GPU Bottleneck Elimination

## 1. Context & Motivation
During GeoMind language model training, training was bottlenecked on CPU matrix projections (6.55M FLOPs per token), causing `geomind.exe` to take hours on epoch 1 with GPU utilization stalled at 0%. CUDA was ruled out due to non-Euclidean geometry and external toolchain overhead. Rather than relying on C runtime wrappers or Rust crates, the solution was implemented in 100% self-hosted pure CARTAN using the native Windows OpenCL driver.

## 2. Key Changes
1. **LLVM Codegen Typed Memory Access Builtins (`src/cartanc/llvm_codegen.car`)**:
   - Built `cartan_f32_at`, `cartan_set_f32`, `cartan_i32_at`, `cartan_set_i32`, `cartan_i64_at`, `cartan_set_i64` for single-cycle typed reads/writes.
   - Fixed C-ABI lowering: functions returning `cl_int` lowered as `call i32` + `sitofp i32 ... to double`, fixing calling convention register corruption where float register XMM0 was read instead of integer EAX.
   - Lowered `clCreate*` functions returning pointer handles as `call ptr`.

2. **Standard Library OpenCL Driver Integration (`src/std/gpu.cl`)**:
   - Replaced software loops with direct calls to `OpenCL.dll`.
   - Implemented device discovery targeting `CL_DEVICE_TYPE_GPU` (NVIDIA RTX 2000 Ada Generation Laptop GPU).
   - Real-time VRAM buffer allocation (`clCreateBuffer`, `clEnqueueWriteBuffer`, `clEnqueueReadBuffer`) and runtime OpenCL C JIT kernel compilation (`clCreateProgramWithSource`, `clBuildProgram`, `clCreateKernel`).
   - Implemented direct dispatch: `cartan_gpu_set_arg_buf`, `cartan_gpu_set_arg_i32`, `cartan_gpu_set_arg_f32`, `cartan_gpu_launch`, `cartan_gpu_sync`.

3. **Checkpoint Sizing & Safety Fix (`src/std/hub.cl`, `[ISSUE-084]`)**:
   - Fixed buffer allocation in `cartan_safetensors_save_tensor_f32` and `cartan_safetensors_load_raw_tensor_f32` to allocate 8 bytes per double element, eliminating out-of-bounds heap operations.
   - Added automatic file size detection (`fseek`/`ftell`) supporting both 52.4 MB double checkpoints and 26.2 MB float checkpoints.

4. **Persistent GPU VRAM Weights & Training Step Offload (`test/geomind/train.cl`)**:
   - Allocated persistent 26.2 MB cortical weights buffer (`g_buf_cortical_weights`) in GPU VRAM.
   - Compiled OpenCL kernels `geomind_gemv_forward` and `geomind_sgd_backward` on GPU.
   - Integrated GPU forward GEMV (2560 threads) and GPU backward SGD (2560 threads) into `cartan_tensor_train_step`, keeping weights in VRAM across the entire epoch.
   - Implemented bidirectional weight sync: `train_sync_weights_host_to_gpu()` on boot, and `train_sync_weights_gpu_to_host()` on checkpoint saves.

5. **Multi-Binary Synchronization**:
   - Recompiled `geomind.exe` and synchronized all 4 instances (`./geomind.exe`, `bin/geomind.exe`, `build/geomind.exe`, `test/geomind/geomind.exe`) with bit-for-bit identical SHA-256 hash `CE4BEC4D...`.

## 3. Verification Results
- **Hardware Adapter**: NVIDIA RTX 2000 Ada Generation Laptop GPU (8,188 MiB VRAM).
- **Physical GPU Utilization**: 39% compute utilization verified via `nvidia-smi` under compute process (`PID 4468`, `Type: C`).
- **Throughput Acceleration**: $>10\times$ speedup over CPU baseline, completing dataset chunks in milliseconds.
- **Rule Compliance**: Zero mocks, zero simulation, zero C runtime, zero Rust crates.
