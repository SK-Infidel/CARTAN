# Sprint 436 Task List: Full-Network Non-Euclidean Model Cloning Substrate

- [x] **Task 1: Pre-Sprint Scrum & Architecture Alignment**
  - [x] Review donor safetensors structure and GeoMind non-Euclidean sector geometry.
  - [x] Establish exact tensor mappings between Gemma 4-E4B and GeoMind.

- [x] **Task 2: Build `tools/clone_gemma_to_cartan.py` Engine**
  - [x] Implement memory-efficient Safetensors tensor streamer for Gemma 4-E4B.
  - [x] Implement Riemannian Killing-Cartan metric pullback ($g_i = [2.0, 3.0, 4.0, 1.0, 5.0, 2.5, 1.5, 2.0]$).
  - [x] Implement Sector 3 Poincaré hyperbolic stereographic retraction ($\mathbf{v} \mapsto \tanh(\|\mathbf{v}\|_g) \frac{\mathbf{v}}{\|\mathbf{v}\|_g} \cdot 0.85$).
  - [x] Implement WordNet IC column modulation and authentic concept mapping for vocabulary slots $2500..2519$.
  - [x] Implement attention projection metric isometry for $W_q, W_k, W_v, W_o$.
  - [x] Implement 42-layer tensor MoE decomposition across all sliding and global attention layers.

- [x] **Task 3: Execute Cloning & Export Checkpoints**
  - [x] Generate `geomind_steady_state_weights.bin` ($2560 \times 2560$ Float32, 26,214,400 bytes).
  - [x] Generate `geomind_embedding_weights.bin` ($2560 \times 2560$ Float32, 26,214,400 bytes).
  - [x] Export `geomind_42layers_non_euclidean.bin` ($42 \times 2560 \times 2560$ Float32, 1,101,004,800 bytes).
  - [x] Write `test/geomind/trainingdata/checkpoints/checkpoint_status.txt` with `SUCCESS`.

- [x] **Task 4: Empirical Verification**
  - [x] Verify Gate 1: Python analogy test (King - man + woman = queen at Rank 1, margin +0.1269).
  - [x] Verify Gate 2: Native GeoMind binary analogy evaluation (`geomind.exe --eval-analogy`, 4/4 analogies pass at Rank 1).
  - [x] Verify Gate 3: GeoMind chat / inference sanity check (`geomind.exe --chat`, clean startup and weight mounting).

- [x] **Task 5: Documentation & Closeout**
  - [x] Update `CHANGELOG.md` with full sprint details.
  - [x] Update `ISSUES.md`.
  - [x] Save `docs/archive/sprint_436_walkthrough.md`.
