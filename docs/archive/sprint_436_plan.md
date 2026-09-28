# Sprint 436 Plan: Full-Network Non-Euclidean Model Cloning Substrate

## Core Mission
Implement an end-to-end, full-network non-Euclidean model cloning engine (`tools/clone_gemma_to_cartan.py`) that transforms all layers of `cache_google_gemma-4-E4B-it_model.safetensors`—not just token embeddings, but attention projections ($W_q, W_k, W_v, W_o$), feedforward layers, layernorms, and cortical heads—into GeoMind's Lie group $E_8$ Riemannian manifold space.

## Mathematical Architecture & Transformation Pipeline
1. **Killing-Cartan Metric Pullback ($G$)**:
   - The 2560 latent dimensions are partitioned into eight 320-dimensional sectors.
   - Dynkin weights $g = [2.0, 3.0, 4.0, 1.0, 5.0, 2.5, 1.5, 2.0]$.
   - Invariant Riemannian inner product: $\langle \mathbf{u}, \mathbf{v} \rangle_g = \sum_{i=0}^{2559} u_i v_i \cdot g_{\lfloor i/320 \rfloor}$.

2. **Sector 3 Poincaré Hyperbolic Stereographic Retraction (Dims 960–1279)**:
   - For any vector $\mathbf{v} \in \mathbb{R}^{320}$, enforce strict boundedness within the Poincaré disk radius ($r < 1.0$) to prevent hyperbolic metric divergence:
     $$\mathbf{v}_{\text{hyp}} = \tanh\left(\|\mathbf{v}\|_g\right) \frac{\mathbf{v}}{\|\mathbf{v}\|_g + \epsilon} \cdot 0.85$$

3. **Attention & Cortical Metric Isometry ($W_q, W_o, W_{\text{cortical}}$)**:
   - Transform projection operators by metric scaling factors so that Euclidean matrix-vector products preserve the Riemannian energy $\mathbf{q}^T G \mathbf{k}$.
   - Apply WordNet Information Content (IC) modulation on concept vocabularies and stop words.

4. **42-Layer Full Manifold MoE Checkpoint**:
   - Extract all 42 transformer layers (35 sliding attention + 7 global attention).
   - Decompose MLP gate projections into 4-expert Lie router representations.
   - Export full 42-layer tensor binary `geomind_42layers_non_euclidean.bin`.

5. **Decoupled Baseline Serialization**:
   - `test/geomind/trainingdata/checkpoints/geomind_steady_state_weights.bin` ($2560 \times 2560$ Float32, 26,214,400 bytes).
   - `test/geomind/trainingdata/checkpoints/geomind_embedding_weights.bin` ($2560 \times 2560$ Float32, 26,214,400 bytes).
   - `test/geomind/trainingdata/checkpoints/checkpoint_status.txt` marked `SUCCESS`.

## Verification Gates
- **Gate 1**: Python empirical analogy verification (King - man + woman = queen at Rank 1).
- **Gate 2**: GeoMind native binary analogy test (`geomind.exe --eval-analogy`) passing 4/4 semantic vector analogies.
- **Gate 3**: GeoMind interactive chat sanity check (`geomind.exe --chat`) ensuring no NaN/Inf or coordinate divergence.
