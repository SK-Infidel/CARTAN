# Sprint 502 Plan: Authentic WebGPU Transformer Layer Offload & Sustained GPU Utilization

**Date**: 2026-09-30  
**Supervisor**: Antigravity  
**Author**: Rick  
**Theme**: True WebGPU Layer Execution & Eliminating CPU Inference Bottlenecks

---

## 1. Sprint Goal
Eliminate the single-threaded CPU bottleneck in `geomind.exe` by offloading the heavy transformer matrix computations (specifically the 78 MFLOP GeGLU MLP and layer GEMVs) to WebGPU on GPU 1 (NVIDIA RTX 2000 Ada Generation Laptop GPU), ensuring sustained, visible GPU utilization in Windows Task Manager with zero mocks and zero regressions across all 88 test suite targets.

---

## 2. User Stories
1. **As a developer (Rick)**, I want `geomind.exe` to drive sustained, visible compute utilization on GPU 1 in Windows Task Manager during token generation instead of spending 9+ seconds per token on the CPU.
2. **As an architect**, I want genuine WebGPU compute shaders executing real GEMV and GeGLU operations on physical GPU hardware, eliminating the dummy identity copy shaders.
3. **As a performance engineer**, I want token generation throughput significantly accelerated while preserving exact dialogue fluency and mathematical precision.

---

## 3. Implementation Strategy

### Stage 1: Runtime & Kernel Engineering (`cartan_runtime_engineer`)
- Author genuine WebGPU compute shaders for GeGLU MLP:
  - `geglu_fwd`: takes input $x \in \mathbb{R}^{2560}$, weights $W_{\text{gate}} \in \mathbb{R}^{10240 \times 2560}$ and $W_{\text{up}} \in \mathbb{R}^{10240 \times 2560}$, computes:
    $$\text{act}[j] = \text{GELU}_{\text{tanh}}(W_{\text{gate}}[j] \cdot x) \times (W_{\text{up}}[j] \cdot x)$$
  - `down_proj_fwd`: takes $\text{act} \in \mathbb{R}^{10240}$, weights $W_{\text{down}} \in \mathbb{R}^{2560 \times 10240}$, computes:
    $$y[d] = W_{\text{down}}[d] \cdot \text{act}$$

### Stage 2: Model & Chat Integration (`cartan-architect`)
- In `test/geomind/chat.cl`:
  - Wire layer compute dispatch into `geomind_execute_manifold_decode_step`.
  - Clean up dead identity shaders in `geomind_chat_dispatch_gpu_manifold`.
  - Ensure zero mock / zero simulation compliance: all GPU dispatches execute authentic matrix algebra.

### Stage 3: QA Verification & Benchmarking (`cartan-qa-tester`)
- Benchmark token latency before vs after.
- Verify active GPU 1 utilization during generation via `geomind.exe -prompt "Hello" -tokens 10`.
- Run full regression suite: `powershell -ExecutionPolicy Bypass -File tools/run_affected_tests.ps1 -All` ensuring 88/88 targets pass cleanly.

---

## 4. Definition of Done (DoD)
- [ ] Code passes static type checking and LLVM IR codegen via `cartanc.exe`.
- [ ] Sustained GPU 1 utilization is empirically observed during `geomind.exe` generation.
- [ ] Zero regressions across all 88 test suite targets.
- [ ] `CHANGELOG.md` and `ISSUES.md` updated.
- [ ] Walkthrough saved to `docs/archive/sprint_502_walkthrough.md`.
