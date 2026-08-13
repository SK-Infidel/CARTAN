# Sprint 93 Implementation Plan: GeoMind Grokking Architecture & Riemannian Cross-Entropy Training Regimen

## 1. Core Objectives
1. **Real Parameter Loading & Header Offset Parsing (`src/std/hub.car` & `src/cartanc/c_runtime.c`)**:
   - Parse exact tensor shapes and `data_offsets` from `.safetensors` headers for true FP32 weight matrix loading.
2. **Unified 32-Layer Transformer Execution (`test/geomind/e8_attention_engine.car`, `moe.car`, `chat.car`)**:
   - Add RMSNorm pre-normalization, Rotary Position Embeddings (RoPE), Grouped Query Attention (GQA), SwiGLU MLPs, and residual additive skip connections ($h_{l+1} = h_l + \text{SubLayer}(h_l)$).
   - Implement vectorized Continuous Hopfield attractor basin relaxation ($\mathbf{h} = X^T \text{softmax}(\beta X \mathbf{h})$).
3. **Unconstrained 256K Logit Sampling (`test/geomind/chat.car`)**:
   - Replace modulo 85 truncation with full 2D parameter unembedding matrix projections ($\mathbf{z} = \mathbf{h}_{32} \cdot W_{\text{embed}}^T \in \mathbb{R}^{256000}$) and Softmax Top-$P$ nucleus sampling.
4. **Riemannian Cross-Entropy Training Regimen (`test/geomind/sft_train.car`)**:
   - Implement Information Content (IC) weighted cross-entropy loss:
     $$\mathcal{L}_{\text{CE}} = -\frac{1}{N} \sum_{i=1}^N \text{IC}(y_i) \cdot \log P(y_i)$$
   - Natural gradient warping via inverse metric tensor $\mathbf{G}_{E8}^{-1} \cdot \nabla_{\mathbf{W}} \mathcal{L}_{\text{CE}}$.
   - Geodesic Exponential Retraction update along $E_8$ Lie algebra manifolds:
     $$\text{Exp}_{\mathbf{W}}(v) = \cos(\|v\|) \cdot \mathbf{W} + \sin(\|v\|) \cdot \frac{v}{\|v\|}$$

---

## 2. Execution Strategy
- Edit `src/std/hub.car` and `src/cartanc/c_runtime.c` to support real safetensors offset reading.
- Sync `c_runtime.c` to `C:\Users\rich-\.cartan\c_runtime.c` and rebuild `cartanc.exe`.
- Update `test/geomind/e8_attention_engine.car`, `moe.car`, `chat.car`, and `sft_train.car`.
- Rebuild `geomind.exe` with `cartanc.exe` and verify with `--chat` and `--train-sft`.
- Update `CHANGELOG.md` and `docs/ROADMAP.md`.
