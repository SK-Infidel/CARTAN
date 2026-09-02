# Sprint 251: Native CARTAN WebGPU / WGSL Compute Architecture

## Sprint Goal
Eliminate the two-language problem for GPU compute by implementing native `@gpu` kernel syntax in CARTAN, an AST-to-WGSL code generation pass in the self-hosted compiler (`cartanc`), and a robust WebGPU compute runtime backend with zero stubbed or placeholder functionality.

---

## Architectural Components

### 1. Frontend AST & Parser (`src/cartanc/ast.ch`, `src/cartanc/lexer.car`, `src/cartanc/parser.car`)
- Add `@gpu` decorator parsing for function declarations.
- AST representation: `Stmt::GpuKernelDecl(name, params, body, workgroup_size_x, workgroup_size_y, workgroup_size_z)`.
- Support GPU-specific builtins (`gid.x`, `gid.y`, `gid.z`, `lid.x`, `lid.y`, `lid.z`, `workgroup_barrier()`).

### 2. WGSL Code Generator (`src/cartanc/wgsl_codegen.car`)
- Pure CARTAN single-pass AST visitor converting CARTAN expressions and statements to standard WebGPU Shading Language (WGSL).
- Emits `@compute @workgroup_size(...)`, `@group(0) @binding(i) var<storage, read_write> ...`, typed math intrinsics, and control flow.

### 3. LLVM IR Code Generation Integration (`src/cartanc/llvm_codegen.car`)
- Automatically generates static WGSL shader string globals in `.ll` output.
- Emits host launcher functions that bind buffers and dispatch GPU workgroups via the runtime.

### 4. WebGPU Host Runtime Bridge (`src/cartanc/c_runtime.c`)
- Direct C FFI interface:
  - `cartan_gpu_init()`: Initializes GPU adapter, device, and command queue.
  - `cartan_gpu_create_buffer(size_bytes, usage_flags)`: Allocates storage buffer in VRAM.
  - `cartan_gpu_write_buffer(buf, offset, src_ptr, size)`: Uploads CPU data to VRAM.
  - `cartan_gpu_read_buffer(buf, offset, dst_ptr, size)`: Reads VRAM back to CPU host.
  - `cartan_gpu_create_pipeline(wgsl_src, entry_point)`: Compiles WGSL and builds pipeline.
  - `cartan_gpu_dispatch(pipeline, buffers, num_buffers, gx, gy, gz)`: Encodes compute pass and executes.

### 5. Standard Library GPU Module (`src/std/gpu.car`)
- High-level CARTAN API wrapping raw runtime handles with type safety.

---

## Strict Zero-Mock & Quality Directives
- Every single kernel must execute genuine math on physical hardware.
- Zero mock buffers, zero fake metrics, zero placeholder functions.
- Empirical verification on real GPU hardware with regression tests.
