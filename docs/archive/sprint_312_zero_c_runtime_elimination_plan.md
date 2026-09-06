# Sprint 312: 100% Zero-C Model Runtime Migration & WebGPU Purification

## Objective
Eliminate the last remaining C code in the repository (`src/cartanc/geomind_runtime.c`, 6,172 lines) and remove all OpenCL driver dependencies (`-lOpenCL`), completing CARTAN's evolution into a 100% pure self-hosting language and aligning GeoMind with pure WebGPU compute.

---

## Architectural Dependency Tree & Deconstruction

```
Pre-Sprint State:
  test/geomind/*.car ──> extern fn (...) ──> src/cartanc/geomind_runtime.c (6,172 lines C)
                                               ├── OpenCL 3.0 Driver Wrappers & Kernels (-lOpenCL)
                                               ├── Winsock2 Sockets
                                               ├── 64-bit Safetensors File I/O
                                               ├── Continuous Hopfield Memory Arrays
                                               ├── Sasaki Metric Brainstem & 8 Lie Streams
                                               ├── Three-Factor Hebbian & Sleep Replay
                                               ├── WordNet / SlangNet Taxonomic DAG
                                               ├── Reflective Doubt & Shannon Entropy
                                               └── Eager 2.68 GB Token Embedding Loader

Target Zero-C State:
  test/geomind/*.car ──> src/std/*.cl & test/geomind/*.cl (100% Pure Cartan)
                                ├── Direct System ABI: -lshell32 -lws2_32 -luser32 -lgdi32 -lwinmm -ladvapi32 (MSVCRT)
                                ├── src/std/gpu.cl (Pure WebGPU Buffer Manager & Compute Executor)
                                ├── src/std/net.cl (Native WinSock2 externs)
                                ├── src/std/fs.cl & hub.cl (64-bit stdio & Safetensors I/O)
                                ├── src/std/resonator.cl (Pure Cartan Hopfield KV Memory)
                                ├── src/std/hebbian.cl (Pure Cartan Three-Factor Synaptic Plasticity)
                                ├── src/std/sleep.cl (Pure Cartan Attractor Consolidation)
                                ├── src/std/semantics.cl (Pure Cartan WordNet / SlangNet DAG)
                                ├── src/std/reasoning.cl (Pure Cartan Doubt & Shannon Entropy)
                                ├── test/geomind/streams.cl (Pure Cartan 8 Lie Submanifolds)
                                ├── test/geomind/moe.cl (Pure Cartan Sasaki Brainstem Router)
                                └── test/geomind/trainer.cl (Pure Cartan Streaming SFT Trainer)
                                [ZERO C FILES LINKED]
```

---

## User Stories & Phased Execution

1. **User Story 1 (WebGPU & System ABI)**: As a language developer, I want all GPU compute buffer management and OS networking/file I/O to run via direct system ABI and pure Cartan, without OpenCL or intermediate C wrappers.
2. **User Story 2 (Pure Cartan Cognitive Kernels)**: As a model architect, I want Hopfield KV memory, Sasaki brainstem routing, 8 Lie streams, Hebbian plasticity, sleep consolidation, WordNet DAG, and Reflective Doubt to run in pure Cartan standard libraries with zero C code.
3. **User Story 3 (Zero-C Decoupling & Empirical Proof)**: As a compiler engineer, I want `tools/zig_wrapper.py` to link zero C files, retire `geomind_runtime.c`, and verify that all 62 compiler tests in `test/compiler_suite/run_tests.car` and `build/geomind.exe` pass cleanly.

---

## Definition of Done (DoD)
- [ ] `geomind_runtime.c` removed from `tools/zig_wrapper.py`.
- [ ] `-lOpenCL` removed from `tools/zig_wrapper.py`.
- [ ] All ~50 runtime symbols implemented in pure Cartan standard libraries.
- [ ] `src/cartanc/geomind_runtime.c` retired.
- [ ] All 62 compiler snapshot tests in `test/compiler_suite/run_tests.car` pass with ZERO C files.
- [ ] `build/geomind.exe` compiles and runs cleanly with ZERO C files.
- [ ] `CHANGELOG.md` updated.
- [ ] `ISSUES.md` updated.
