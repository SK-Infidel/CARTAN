# Sprint 437 Plan: Hybrid Resonant Transformer Architecture

## Core Mission
Implement a native Causal Transformer Decoder stack in pure CARTAN (`src/std/transformer.cl`) and couple it with GeoMind's Continuous Hopfield Resonator and $E_8$ Lie Manifold (`src/std/hybrid_resonator.cl`). This unifies Gemma's causal syntactic fluency with GeoMind's deep associative energy-based memory grounding into a single dual-process architecture.

## Mathematical Architecture & Component Specifications

1. **Root Mean Square Layer Normalization (`cartan_rmsnorm`)**:
   $$\text{RMSNorm}(\mathbf{x}) = \frac{\mathbf{x}}{\sqrt{\frac{1}{D}\sum_{i=1}^D x_i^2 + \epsilon}} \odot \mathbf{w}_{\text{norm}}$$
   - Target Dimension: $D = 2560$.
   - $\epsilon = 10^{-6}$.

2. **Rotary Position Embedding (`cartan_rope_apply`)**:
   - Rotates pairs of coordinate dimensions $(x_{2k}, x_{2k+1})$ by angle $\theta_k = \text{pos} \cdot b^{-2k / d}$:
     $$\begin{pmatrix} x'_{2k} \\ x'_{2k+1} \end{pmatrix} = \begin{pmatrix} \cos \theta_k & -\sin \theta_k \\ \sin \theta_k & \cos \theta_k \end{pmatrix} \begin{pmatrix} x_{2k} \\ x_{2k+1} \end{pmatrix}$$
   - Partial rotary factor: $0.25$ / $1.0$, $\text{head\_dim} = 256$.

3. **Grouped-Query Attention (`cartan_gqa_attention`)**:
   - $N_q = 8$ query heads, $N_{kv} = 2$ key-value heads ($4:1$ query-to-KV head sharing).
   - Head dimension: $d_k = 256$.
   - Causal attention mask with query-key inner product scaling by $1 / \sqrt{d_k}$.

4. **SwiGLU / GELU Feedforward MLP (`cartan_swiglu_mlp`)**:
   - Hidden expansion: $2560 \rightarrow 10240 \rightarrow 2560$.
   - $\text{FFN}(\mathbf{x}) = (\text{GELU}(\mathbf{x} W_{\text{gate}}) \odot (\mathbf{x} W_{\text{up}})) W_{\text{down}}$.

5. **Dual-Process Resonant Coupling (`hybrid_resonator_forward_step`)**:
   - **System 1 (Transformer)**: Computes contextual syntactic hidden state $\mathbf{h}_{\text{trans}} \in \mathbb{R}^{2560}$.
   - **System 2 (Resonator)**: Relaxes $\mathbf{h}_{\text{trans}}$ through Continuous Hopfield memory basins and $E_8$ Lie metric curvature ($G$).
   - **Logit Softcapping**: $\text{logits} = 30 \cdot \tanh(\mathbf{h}_{\text{relaxed}} \mathbf{W}_{\text{cortical}} / 30)$.

## Verification Gates
- **Gate 1**: Precision verification of RMSNorm and RoPE rotational invariants.
- **Gate 2**: Grouped-Query Attention (GQA) causal mask & multi-head routing verification.
- **Gate 3**: Dual-process Transformer-to-Hopfield coupling step verification.
- **Gate 4**: Full regression suite pass in `test/compiler_suite/test_hybrid_resonant_transformer.car`.
