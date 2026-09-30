# Sprint 486 Plan: Phase 2 Core Runtime Integrity & Stub Eradication

## 1. Context & Motivation
Following the completion of Sprint 485, Sprint 486 systematically eradicates the remaining stubs, empty functions, and fake formulas in `src/cartanc/core_runtime.car` as specified in Phase 2 of the Codebase Integrity Master Plan.

---

## 2. Sprint 486 Deliverables by Gate

### Gate 1: Authentic Vector Autodiff & Vectorized Mapping (`cartan_rt_transform`)
- **Autodiff Sensitivity**:
  - Purge the toy formula `1.0 + (v * 0.01)` in `cartan_rt_transform("grad", target)`.
  - Implement authentic analytical gradient computation for standard quadratic loss potential $L(v) = \frac{1}{2}\|v\|^2 \implies \nabla L(v) = v$.
  - For each element $v_i$, compute genuine sensitivity $\nabla_i = v_i$.
  - Ensure compliance with Target 62 assertions (`g_len == 2.0`, `g_val0 > 0.0`).
- **Vectorized Mapping**:
  - Implement true batch-wise transformation mapping across multi-dimensional slices in `cartan_rt_transform("vmap", target)`.

### Gate 2: Authentic Binary Checkpoint Weight Absorption (`cartan_absorb_weights`)
- **Real File Ingestion**:
  - Replace the empty function body with real binary weight reading.
  - Open `donor_path` using `fopen(donor_path, "rb")`.
  - Inspect file size using `fseek` and `ftell`.
  - Stream raw binary floats directly into the payload array of `local_tensor` via `fread`.
  - Gracefully handle missing or corrupted files with clear diagnostics and safe cleanup.

### Gate 3: Fail-Fast ONNX Ingestion & Compute Graph Teardown
- **ONNX Ingestion Validation**:
  - In `cartan_internal_import_onnx(uri)`, check file existence via `cartan_file_exists(uri)`.
  - If file is missing, log an explicit diagnostic (`[cartan_import_onnx] Notice: File '<uri>' not found on disk`) and mark `is_present = 0.0`.
  - If file exists, read magic bytes/header and populate container tensor bank.
- **Compute Graph Teardown**:
  - In `cartan_free_compute_graph()`, reset active graph pointers, clear temporary allocators, and release transient buffers.

### Gate 4: Authentic Tensor Magnitude Pruning & Fluid Precision
- **Magnitude Pruning**:
  - Implement `cartan_tensor_prune_magnitude(t: ptr, threshold: float) -> ptr` in `core_runtime.car`.
  - For each element $w_i$, if $|w_i| < \text{threshold}$, set $w_i = 0.0$.
  - Wire `cartan_prune_graph(threshold)` to update `g_prune_threshold` and apply pruning across active tensors.
- **Fluid Precision**:
  - Implement genuine floating-point mantissa truncation simulating FP16 / BF16 dynamic range reduction.

### Gate 5: 3-Stage Bootstrap Fixpoint & Full Regression Clearance
- Recompile `cartanc.exe` through 3-stage bootstrap fixpoint convergence (`SHA256` matching).
- Verify Target 62 (`test_transforms_and_logic.car`).
- Verify Target 66 (`test_geometric_bridge_and_reflection.car`).
- Run the full 87-target compiler regression suite (`tools/run_affected_tests.ps1 -All`).
- Re-verify empirical chat inference on `geomind.exe`.
