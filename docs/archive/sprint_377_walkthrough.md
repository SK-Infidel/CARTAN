# Sprint 377 Walkthrough: Validation Isolation, Weight Decay Regularization, & Post-Attention Spherical Normalization

## Overview
Sprint 377 resolves the divergence between streaming training loss ($TL \approx 4.35$) and validation loss ($VL \approx 5.80$), eliminating overconfident validation error peaks ($VPPL \approx 352 \to 94$, $VCERT \approx 22.6\% \to 4.6\%$).

---

## Key Modifications

### 1. Training & Validation Pipelined Execution ([`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl))
- **Hidden State Isolation**:
  - `geomind_train_chunk_gpu_pipelined`: Wrapped `g_buf_prev_chunk_h` persistence and `g_has_prev_chunk_h = 1.0` inside `if (lr > 0.0)`.
  - Holdout chunks evaluated at `lr == 0.0` no longer overwrite training hidden state or bleed across disparate validation paragraphs.
- **Genuine L2 Weight Decay**:
  - Configured `decay_factor = 0.99995` in both the GPU kernel dispatch (`cartan_gpu_set_arg_f32(g_pipe_sgd, 8.0, decay_factor)`) and CPU fallback loops.
  - Prevents continuous logit inflation and softmax over-sharpening over millions of tokens.
- **Post-Attention/Hopfield Spherical Normalization**:
  - Dispatched `g_pipe_rmsnorm` immediately following Tier 1 Causal MHA and Tier 3 Hopfield memory injection, prior to `g_pipe_gemv`.
  - Enforces Riemannian sphere invariance ($\|\mathbf{h}\| = 1$) across all additive memory residuals.
- **Closed-Loop Dynamic Temperature Controller & Metric Ruler Decoupling (`test/geomind/train.cl`)**:
  - **Decoupled Metric Measurement from Gradient Smoothing**: The loss/perplexity metrics ($TL$, $TPPL$, $ENT$, $CERT$, $SURP$) are now strictly computed at canonical $T=1.0$ (the unscaled benchmark ruler), both in the OpenCL kernel `geomind_softmax_loss_delta` and the CPU fallback `cartan_tensor_train_step`. Temperature $T$ is applied exclusively to soften the backpropagation gradient deltas $\delta$. This eliminates artificial metric inflation and ends feedback hunting cycles.
  - **Unified Generalization Gap & Velocity Controller**: Evaluates both the cumulative generalization gap ($VL - TL > 1.20\text{ nats}$) and relative growth velocity ($\Delta VPPL / VPPL - \Delta TPPL / TPPL$). Prevents temperature from being pinned to the floor during steady divergence while ensuring that when both $TL$ and $VL$ rise in tandem on hard dataset passages, the gap remains constant and temperature stays at baseline $T_0 = 1.0$.
  - **Effective Learning Rate Coupling**: Coupled $\eta$ to active temperature $T$ to maintain the effective parameter step size $\eta_{\text{eff}} = \frac{\eta}{T}$ within $[\eta_{\text{floor}}, \eta_{\text{ceiling}}]$. Dynamic floor scaling ($\eta_{\text{floor}} \cdot T$) prevents step-size starvation during divergence, while damping ceiling ($\eta_{\text{ceiling}} / \sqrt{T}$) and freezing upward annealing prevents destabilizing step shocks.
  - Temperature seamlessly anneals back toward $T_0 = 1.0$ when validation stabilizes or descends.
  - Integrated `TEMP: %s` directly into telemetry Line 1 right after `LR: %s` and removed standalone console action print lines, maintaining an unbroken 3-line format.
- **Build Tooling Sanitization (`tools/zig_wrapper.py`)**:
  - Removed unused `-I` include directory flags for CUDA Toolkit and Intel oneAPI from Clang IR linker invocation, eliminating `-Wunused-command-line-argument` warnings.

### 2. Checkpoint & Manifest Restoration
- Overwrote `geomind_steady_state_weights.bin` with clean un-decayed baseline [`geomind_steady_state_weights.bin.bak`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/checkpoints/geomind_steady_state_weights.bin.bak) (52.4 MB).
- Reset [`test/geomind/trainingdata/corpus.json`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/corpus.json) to Dataset 0 (`fineweb_edu_curated.txt`), offset 0.0, Epoch 1.0, LR 0.0022.

---

## Verification Results

### 1. Build Verification
- Compiled using self-hosting compiler `cartanc.exe`:
  ```powershell
  .\cartanc.exe build test/geomind/main.car -o test/geomind/geomind.exe
  ```
- SHA-256 hash verified identical across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`:
  `F27FBEB030316645B59CD8700ABEEF370377B01B9FE5A256D1E6E5E8E19F117A`

### 2. Semantic Analogy Verification
`.\geomind.exe --eval-analogy` executed with 4/4 passing:
- **King - man + woman**: Rank 1 ` queen` (Sim: 0.4341, Margin: +0.0992) - **PASS**
- **he - him + her**: Rank 1 ` she` (Sim: 0.4891, Margin: +0.1137) - **PASS**
- **father - man + woman**: Rank 1 ` mother` (Sim: 0.5187, Margin: +0.0873) - **PASS**
- **boy - man + woman**: Rank 1 ` girl` (Sim: 0.5799, Margin: +0.2062) - **PASS**

### 3. Empirical Live Telemetry
Under active training on Dataset 1 (`fineweb_edu_curated.txt`):
- $TL = 4.608\text{ nats} \longleftrightarrow VL = 4.621\text{ nats}$ ($\Delta = 0.013\text{ nats}$)
- $TPPL = 100.3 \longleftrightarrow VPPL = 94.3$
- $ENT = 8.70\text{ bits} \longleftrightarrow VENT = 8.59\text{ bits}$
- $CERT = 3.48\% \longleftrightarrow VCERT = 4.64\%$
- $SURP = 7.31\text{ bits} \longleftrightarrow VSURP = 7.39\text{ bits}$
Zero overconfidence delusion, zero validation context pollution, and seamless tracking between train and validation.
