# Sprint 260 Implementation Plan: Pure CARTAN Runtime Migration

## Sprint Goal
Port high-level runtime subsystems from `src/cartanc/c_runtime.c` into pure CARTAN modules in `src/std/`, transitioning `c_runtime.c` from a monolithic ~4,400-line runtime to a thin, zero-overhead OS/GPU FFI shim.

---

## Architecture & Subsystem Mapping

```
┌────────────────────────────────────────────────────────┐
│               Native CARTAN Application                │
│             (test/geomind/main.car, etc.)              │
└──────────────────────────┬─────────────────────────────┘
                           │
       ┌───────────────────┴───────────────────┐
       ▼                                       ▼
┌──────────────────────────────┐     ┌──────────────────────────────┐
│  src/std/ Collections & Mem  │     │   src/std/ File System (FS)  │
│  - Dynamic Vector / Tensor   │     │  - fopen / fread / fwrite    │
│  - Contiguous float buffers  │     │  - File exist / string IO    │
└──────────────┬───────────────┘     └──────────────┬───────────────┘
               │                                    │
               ▼                                    ▼
┌──────────────────────────────┐     ┌──────────────────────────────┐
│    src/std/ String & Token   │     │   src/std/ Neural / Safeten  │
│  - Concat / Substring / Len  │     │  - Binary Safetensors parser │
│  - BPE Trie & Top-P / Top-K  │     │  - Geodesic SLERP & Distill  │
└──────────────┬───────────────┘     └──────────────┬───────────────┘
               │                                    │
               └───────────────────┬────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────┐
│     Thin C-ABI FFI Layer (malloc/free, OpenCL/CUDA)     │
└────────────────────────────────────────────────────────┘
```

---

## User Stories & Phased Tasks

### Story 1: File System & Binary Buffer Migration (`src/std/fs.cl`, `src/std/io.cl`)
- Implement `cartan_file_exists`, `cartan_read_file`, `cartan_write_file`, and `cartan_copy_file` in pure CARTAN using standard C-ABI libc calls (`fopen`, `fclose`, `fseek`, `ftell`, `fread`, `fwrite`).
- Implement dynamic string buffer allocation in CARTAN.

### Story 2: Contiguous Dynamic Vector Engine (`src/std/collections.cl`)
- Implement native `cartan_vec_create`, `cartan_vec_push_f32`, `cartan_vec_get_f32`, `cartan_vec_set_f32`, `cartan_vec_len`, `cartan_vec_scale`, and `cartan_vec_destroy` in pure CARTAN syntax.
- Ensure zero-overhead memory allocation using typed pointer indexing.

### Story 3: String Operations & String Formatting (`src/std/string.cl`)
- Implement native string concatenation, substring slicing, character inspection, and prefix matching in pure CARTAN.

### Story 4: Neural Distillation & Model Fusion Migration (`src/std/distill.cl`, `src/std/fusion.cl`)
- Migrate KL divergence loss calculation (`distill_kl_divergence_loss`) and Tangent Space SLERP geodesic merging (`fusion_tangent_space_slerp`) to pure CARTAN standard library modules.

### Story 5: Empirical Verification & Regression Suite
- Build `bin/geomind.exe` with `cartanc.exe`.
- Verify all CLI modes (`--chat`, `--train-distill`, `--azr-selfplay`, `--ingest`, `--help`).
- Execute official compiler regression suite.
