# Sprint 437 Task List: Hybrid Resonant Transformer Architecture

- [x] **Task 1: Pre-Sprint Scrum & Mathematical Foundations**
  - [x] Review Gemma 4-E4B attention parameters ($N_q=8, N_{kv}=2, d=2560, \text{intermediate}=10240$).
  - [x] Establish exact tensor data structures in CARTAN standard library.

- [x] **Task 2: Build `src/std/transformer.cl`**
  - [x] Implement `cartan_rmsnorm(x, w, eps)` with authentic root-mean-square normalization.
  - [x] Implement `cartan_rope_apply(vec, pos, head_dim, theta)` for rotary positional embeddings.
  - [x] Implement `cartan_gqa_causal_attention(q, k_buf, v_buf, q_heads, kv_heads, head_dim, seq_len)`.
  - [x] Implement `cartan_gelu_tanh(x)` approximation.
  - [x] Implement `cartan_swiglu_mlp_forward(x, gate_w, up_w, down_w, in_dim, inter_dim)`.
  - [x] Implement `cartan_transformer_layer_forward(h, layer_params, pos, kv_cache)`.

- [x] **Task 3: Build `src/std/hybrid_resonator.cl`**
  - [x] Implement `hybrid_resonator_forward_step(h, trans_block, hopfield_weight, temp)`:
    - Step 1: Run Transformer causal layer forward pass.
    - Step 2: Relax hidden state through Continuous Hopfield attractor memory.
    - Step 3: Project through $E_8$ Lie manifold metric ($G$) with softcapping.
  - [x] Implement `cartan_tensor_compute_softcapped_logits(h, w, dim, vocab_size, cap)`.

- [x] **Task 4: Build Regression Suite `test/compiler_suite/test_hybrid_resonant_transformer.car`**
  - [x] Gate 1: Test RMSNorm precision (root mean square = 1.0).
  - [x] Gate 2: Test RoPE identity at pos=0 and L2 pair norm conservation.
  - [x] Gate 3: Test SwiGLU / GELU activations and shape expansion ($16 \rightarrow 32 \rightarrow 16$).
  - [x] Gate 4: Test end-to-end Hybrid Transformer-Resonator forward pass and 30.0 softcapping.
  - [x] Register Target [64/64] in `test/compiler_suite/run_tests.car`.
  - [x] Compile with `cartanc.exe` and verify clean execution.

- [x] **Task 5: Documentation & Closeout**
  - [x] Update `CHANGELOG.md` with release `[8.395.0]`.
  - [x] Update `ISSUES.md`.
  - [x] Update `docs/ROADMAP.md` with Phase 71.
  - [x] Archive `sprint_437_walkthrough.md`.
