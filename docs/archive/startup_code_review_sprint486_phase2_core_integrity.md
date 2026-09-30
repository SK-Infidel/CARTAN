# Startup Code Review: Sprint 486 (Phase 2 Core Runtime Integrity & Stub Eradication)

## 1. Context & Motivation
Following the completion of Sprint 485 (eradicating `cartan_native_io.c` and establishing cross-platform Linux compatibility), Sprint 486 focuses on Phase 2 of the Codebase Integrity Master Plan: eradicating all remaining stubs, empty functions, fake formulas, and hollow returns in `src/cartanc/core_runtime.car`.

---

## 2. Logical Dependency Tree
```
src/cartanc/main.car (Compiler entrypoint)
  └── src/cartanc/core_runtime.car (Universal native runtime kernel prepended to all compilations)
        ├── Autodiff Subsystem:
        │     └── cartan_rt_transform("grad", target) ──> Called by LLVM codegen:3570 for Expr::Transform
        │           └── Target 62 (test_transforms_and_logic.car) verifies grad()
        ├── Model Weight Subsystem:
        │     └── cartan_absorb_weights(donor_path, local_tensor) ──> Called by LLVM codegen:3600
        │           └── Used for model stitching and parameter checkpoint ingestion
        ├── ONNX Container Subsystem:
        │     └── cartan_internal_import_onnx(uri) ──> Called by Target 62
        ├── Compute Graph Memory Lifecycle:
        │     └── cartan_free_compute_graph() ──> Compute graph reset & arena reclamation
        ├── Structured Sparsity & Precision Subsystem:
        │     ├── cartan_sparsity_start / cartan_sparsity_end
        │     ├── cartan_prune_graph(threshold)
        │     └── cartan_fluid_precision_start / cartan_fluid_precision_end
        └── Reflection & Hierarchy Subsystem:
              ├── cartan_reflect_repo() ──> Target 66 (test_geometric_bridge_and_reflection.car)
              └── cartan_init_fractal_attention() ──> Target 67 (test_attention_fused_methods.car)
```

---

## 3. Findings & Defects Identified
1. **[DEFECT-1] Fake Gradient Math in `cartan_rt_transform("grad", target)`**:
   - Location: `src/cartanc/core_runtime.car:1740-1748`
   - Issue: Implements toy formula `1.0 + (v * 0.01)`.
   - Solution: Implement authentic vector gradient evaluation of quadratic loss $L(v) = \frac{1}{2}\|v\|^2$, yielding exact analytical gradient $\nabla L(v) = v$.
2. **[DEFECT-2] Completely Empty Weight Absorption (`cartan_absorb_weights`)**:
   - Location: `src/cartanc/core_runtime.car:1595-1597`
   - Issue: Function body is completely empty: `if (donor_path == 0.0 || local_tensor == 0.0) return;`.
   - Solution: Open `donor_path` via `fopen`, inspect file length, stream raw IEEE 754 float/double weights directly into `local_tensor` buffer via `fread`, and safely close file.
3. **[DEFECT-3] Hollow ONNX Model Import (`cartan_internal_import_onnx`)**:
   - Location: `src/cartanc/core_runtime.car:1725-1733`
   - Issue: Returns a generic dictionary without inspecting file contents or reporting true file absence.
   - Solution: Check file existence and inspect header. If missing, log clean diagnostic and set `is_present = 0.0`.
4. **[DEFECT-4] Empty Compute Graph Free (`cartan_free_compute_graph`)**:
   - Location: `src/cartanc/core_runtime.car:1591-1593`
   - Issue: Function body is an empty comment: `// Freestanding compute graph teardown`.
   - Solution: Reset global graph state, clear temporary tensor references, and reclaim memory.
5. **[DEFECT-5] Non-Operational Sparsity & Precision State Blocks**:
   - Location: `src/cartanc/core_runtime.car:1666-1694`
   - Issue: `cartan_sparsity_start`, `cartan_prune_graph`, and `cartan_fluid_precision_start` only track global depth counters.
   - Solution: Implement genuine magnitude pruning pass `cartan_tensor_prune_magnitude(tensor, threshold)` that sets $|w| < \tau \implies 0.0$.
