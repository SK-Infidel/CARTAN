# Sprint 78 Implementation Plan: AI Scientist 5-Step Overhaul Engine

## 1. Executive Summary
This sprint executes the AI Scientist's 5-step master overhaul plan to transform GeoMind into a fully native $V$-dimensional matrix language engine:
1. **Spherical SLERP & Sign-Elected TIES (`src/std/fusion.car`)**: Implement true vector-norm angle spherical linear interpolation and sign-elected TIES parameter delta merging.
2. **Continuous Hopfield Vector Basin Filter (`test/geomind/chat.car`)**: Filter full 32-layer hidden vector $\mathbf{h}_{32} \in \mathbb{R}^{d_{model}}$ through Continuous Hopfield attractor memory patterns $\mathbf{\Xi}$ before LM-Head projection.
3. **True $V$-Dimensional Checkpoint GEMM Unembedding (`test/geomind/chat.car`)**: Replace scalar text-window modulo math with full vocabulary matrix projection ($\mathbf{z}_v = \sum_{d} W_{lm\_head}[v, d] \cdot h_{relaxed}[d]$) across all 49,152 tokens.
4. **Real Autograd SFT Backpropagation (`test/geomind/sft_train.car`)**: Replace simulated loss loops with genuine forward-backward tensor autograd passes over model parameter checkpoints.
5. **Documentation Alignment (`CHANGELOG.md` & `docs/ROADMAP.md`)**: Synchronize all development docs with the full vector GEMM architecture.

---

## 2. Dependency Tree
- `src/std/fusion.car` (True SLERP & Sign-Elected TIES)
  └── `test/geomind/chat.car` (SLERP checkpoint loading)
      ├── Continuous Hopfield Vector Basin Filter (`geomind_hopfield_relax_state`)
      ├── Full 2D $V$-dimensional LM-Head GEMM (`geomind_lm_head_gemm_forward`)
      └── Top-$P$ / Top-$K$ Softmax nucleus sampler
- `test/geomind/sft_train.car` (Real Autograd Tensor Backprop over SFT checkpoints)

---

## 3. Step-by-Step Execution Plan
1. Update `src/std/fusion.car`: Implement true vector norm SLERP & sign-elected TIES merging.
2. Update `test/geomind/chat.car`: Implement vector Hopfield relaxation, $V$-dimensional LM-Head matrix GEMM projection, and Softmax Top-$P$ nucleus sampler.
3. Update `test/geomind/sft_train.car`: Implement real autograd tensor forward-backward backprop pass.
4. Rebuild `geomind.exe` with `cartanc.exe` and sync to root and `bin/`.
5. Run SFT training pass (`geomind.exe --train-sft`).
6. Launch 1,000-question RLAIF benchmark pass in the background.
7. Update `CHANGELOG.md` and `docs/ROADMAP.md`.
