# Sprint 473 Task List: Gemma 4 Layer Alignment & Zero-Mock Transformer Execution

- [ ] **Phase 1: Architecture Alignment & Primitives Upgrade (`src/std/transformer.cl`)**
  - [ ] Implement `cartan_rmsnorm_head(vec: ptr, w: ptr, num_heads: float, head_dim: float, eps: float) -> ptr` for per-head Q-Norm and K-Norm.
  - [ ] Implement `cartan_ple_gate_forward(h: ptr, ple_vec: ptr, gate_w: ptr, proj_w: ptr, norm_w: ptr, dim: float, ple_dim: float) -> ptr`.
  - [ ] Implement `cartan_logit_softcap(logits: ptr, cap: float) -> ptr`.
  - [ ] Upgrade `cartan_transformer_layer_forward` to accept QK-Norm weights, PLE weights, layer scalar, head dimension, and RoPE theta parameters.
  
- [ ] **Phase 2: High-Performance Full-Vocabulary Ingestion Substrate**
  - [ ] Update `tools/clone_gemma_to_cartan.py` to ingest full $262,144 \times 2,560$ token embeddings and $[262144, 256]$ PLE embeddings without truncation or artificial modulation.
  - [ ] Eliminate 12-byte phantom checkpoint creation and stubbed loaders in `src/std/hub.cl`.

- [ ] **Phase 3: QA Verification & Target 83 Integration**
  - [ ] Author `test/compiler_suite/test_gemma4_layer_alignment.car` (Target 83) validating:
    - Gate 1: Per-Head QK-Norm precision and shape preservation.
    - Gate 2: Sliding layer ($d_{\text{head}}=256$) vs Global layer ($d_{\text{head}}=512$) forward alignment.
    - Gate 3: PLE gating and layer scalar scaling.
    - Gate 4: Logit soft-capping boundary verification ($[-30.0, 30.0]$).
  - [ ] Whitelist `test/compiler_suite/test_gemma4_layer_alignment.car` and `build/test_gemma4_layer_alignment.exe` in `.gitignore`.
  - [ ] Register Target 83 in `test/compiler_suite/run_tests.car`.
  - [ ] Rebuild `run_tests.exe` and execute all 83 test targets to guarantee zero regressions.

- [ ] **Phase 4: Sprint Review & Documentation**
  - [ ] Document findings and performance metrics in `docs/archive/sprint_473_walkthrough.md`.
  - [ ] Update `CHANGELOG.md` with concise sprint entries.
  - [ ] Update `ISSUES.md` with resolved status for addressed debt.
