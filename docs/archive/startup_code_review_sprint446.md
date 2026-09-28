# Comprehensive Pre-Sprint Code Review & Dependency Graph: Sprint 446

**Reviewer:** CARTAN Architecture & Engineering Squad  
**Date:** 2026-09-26  
**Archive:** `docs/archive/startup_code_review_sprint446.md`

---

## 1. Executive Codebase Audit Findings

Following the successful purge of rigged token remappings and silenced Lie submanifolds in Sprint 445, a deep systemic scan of the remaining code revealed several remaining technical debts, legacy hardcoded Euclidean strides, and synthetic drift placeholders:

### Finding 1: Synthetic Sine Drift Vector in Training Pipeline (`test/geomind/train.cl`)
- **Location**: `test/geomind/train.cl` lines 466–474 and 935–938.
- **Defect**: The anisotropic drift vector $\mathbf{b}$ utilized by the Finsler-Randers Sherman-Morrison projection ($g_{\text{randers}} = g - \frac{g \cdot b}{1 + \|b\|^2} b$) is populated with toy synthetic sine harmonics:
  `let b_val = 0.05 * sin((zh + 1.0) * 0.01) * kw;` (GPU buffer setup)
  `let b = 0.05 * sin((c + 1.0) * 0.01) * kw;` (CPU fallback path)
- **Mathematical Reality**: In Finsler-Randers geometry ($\mathcal{F}(x, v) = \sqrt{a_{ij} v^i v^j} + b_i(x) v^i$), the drift 1-form $\mathbf{b}$ represents genuine anisotropic gauge flow (such as Sasaki phase-space momentum $\dot{h}_t = h_t - h_{t-1}$ or the Cartan connection 1-form), strictly satisfying the convexity bound $\|\mathbf{b}\|_a < 1$. Synthetic sinusoidal noise produces arbitrary directional distortion.

### Finding 2: Hardcoded 320 Euclidean Strides in Standard Geometry (`src/std/geom.cl` & `test/geomind/geom.cl`)
- **Location**: `src/std/geom.cl` line 82 and `test/geomind/geom.cl` line 82.
- **Defect**: `geomind_inverse_randers_backward_project` hardcodes:
  `let sub_idx = math_mod_val(floor(i / 320.0), 8.0);`
  For single $248\text{D}$ vectors, `i / 320.0` is always $0$, completely silencing the Dynkin weights of subgroups 1 through 7.
- **Fix**: Endow `geomind_inverse_randers_backward_project` with dynamic submanifold strides based on vector length:
  `let stride = (dim >= 2560.0) ? 320.0 : ((dim >= 1984.0) ? 248.0 : 31.0);`

### Finding 3: Hardcoded 2560D and 320D Constants in WebGPU WGSL Shaders (`test/geomind/train.cl`)
- **Location**: `test/geomind/train.cl` lines 145–215.
- **Defect**: `webgpu_get_causal_attn_shader` hardcodes `D = 2560u; h_base = h * 320u;` and `webgpu_get_lie_streams_shader` hardcodes 8 static 320 slices (`for (var i: u32 = 0u; i < 320u; ...)`, `for (var i: u32 = 320u; i < 640u; ...)`).
- **Fix**: Parametrize shader generation dynamically or supply dimension uniforms so WebGPU compute operates cleanly on $248\text{D}$, $1984\text{D}$, and $2560\text{D}$ manifolds.

### Finding 4: Incomplete Finsler Cotangent Gradient Transform (`src/std/geom.cl`)
- **Location**: `src/std/geom.cl` line 72.
- **Defect**: `geomind_inverse_randers_backward_project` returns a scalar norm $\alpha - \lambda (\mathbf{b} \cdot \mathbf{v})$ instead of returning the transformed cotangent gradient vector $\mathbf{g}_{\text{randers}} \in T^* M$.
- **Fix**: Expose `geomind_inverse_randers_transform_grad(grad_ptr, drift_ptr, metric_ptr, out_grad_ptr)` implementing the true Sherman-Morrison dual inverse metric projection.

---

## 2. Logical Dependency Tree

```
┌────────────────────────────────────────────────────────┐
│                   Cartan Compiler Core                 │
│  src/cartanc/lexer.car -> parser.car -> codegen.car    │
│  src/cartanc/core_runtime.car (C ABI / Memory Safety)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                  Cartan Standard Library               │
│  src/std/math.cl (Elementary transcendentals & modulo) │
│  src/std/collections.cl (Lists, Stacks, Trees)         │
│  src/std/fs.cl & gpu.cl (Binary buffers, WebGPU/OpenCL)│
│  src/std/geom.cl (Differential geometry, Killing metric)│
│  src/std/tokenizer.cl (Genuine SentencePiece BPE)      │
│  src/std/resonator.cl (Continuous Hopfield memory)     │
│  src/std/transformer.cl (RMSNorm, RoPE, SwiGLU, GQA)   │
│  src/std/hybrid_resonator.cl (Dual-Process Coupling)   │
│  src/std/sleep.cl (NSES Metacognitive Consolidation)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                   GeoMind Model Stack                  │
│  test/geomind/geometry.cl (E8 Manifold & Weyl Group)   │
│  test/geomind/streams.cl (8 Lie Subgroup Decomp 1984D) │
│  test/geomind/moe.cl (Sasaki Tangent Router & MoE)     │
│  test/geomind/chat.cl (262k Cosine Projection on S^247)│
│  test/geomind/train.cl (Steady-State Training Engine)  │
│  test/geomind/main.car (Production CLI & Verified Test)│
└────────────────────────────────────────────────────────┘
```

### Direct Downstream Dependents:
1. `src/std/geom.cl` affects:
   - `test/geomind/train.cl` (Finsler-Randers backward projection)
   - `test/compiler_suite/test_lie_streams.car` (Killing form metrics)
   - `test/geomind/geometry.cl`
2. `test/geomind/train.cl` affects:
   - `test/geomind/main.car` (Training CLI commands: `--train-pre`, `--train-cloze`, `--train-ce`, `--train-sft`)
   - GPU VRAM buffers and execution pipelines.

---

## 3. Risk Assessment & Read-Ahead Mitigations

1. **Risk: Buffer Size Mismatch during Dynamic Stride Updates**:
   - *Mitigation*: Ensure `dim` parameter passed to OpenCL kernels and host loops is validated. For 248D single vectors, `stride = 31`. For 1984D multi-decompositions, `stride = 248`. For 2560D full blocks, `stride = 320`.
2. **Risk: Randers Metric Violation ($\|\mathbf{b}\| \ge 1$)**:
   - *Mitigation*: Enforce strict Lorentzian norm check: if $\|\mathbf{b}\|_g \ge 0.95$, scale $\mathbf{b} \leftarrow \mathbf{b} \times \frac{0.90}{\|\mathbf{b}\|_g}$ to ensure strict convexity of the Finsler metric.
3. **Risk: Compilation Regressions**:
   - *Mitigation*: Run `run_tests.exe` and verify all 64 compiler targets and `geomind.exe` subcommands after every edit.
