# Sprint 464 Plan: Chat & Training Integration with NSES Forward Pass

## Sprint Objective
Resolve `[ISSUE-255]` by integrating the Neuro-Symbolic Expert System (NSES) directly into the forward pass of both interactive chat (`test/geomind/chat.cl`) and model training (`test/geomind/train.cl`).
Specifically:
1. Upgrade `src/std/veto_gate.cl` so `veto_compute_symbolic_loss_penalty` automatically penalizes active domain contradiction tokens when explicit `forbidden_token_ids` are omitted.
2. In `test/geomind/chat.cl`:
   - Prime Continuous Hopfield Memory with active domain salient rule attractors from `nses_pipe.graph_file`.
   - Modulate token-level forward pass logits with `nses_pipeline_shape_loss` in real time during autoregressive sampling.
   - Resolve `atomic_discourse.car_graph` when available.
3. In `test/geomind/train.cl`:
   - Route language, dialogue, and discourse datasets to Domain 6 (`LANGUAGE_DISCOURSE`).
   - Enable genuine symbolic loss penalties during backpropagation.
4. Author Target 74 regression test (`test/compiler_suite/test_chat_train_nses_forward_integration.car`) and verify across all 74 compiler test targets.

---

## Technical Specifications

### Phase 1: Veto Registry Auto-Forbidden Token Extraction (`src/std/veto_gate.cl`)
1. Extend `VetoRegistry` with `domain_forbidden_tokens: ptr` (a `cartan_tree` of 8 collections lists for domains 0..7).
2. Implement `veto_registry_add_forbidden_token(reg: VetoRegistry, domain: float, token_id: float)`.
3. In `veto_registry_populate_defaults(reg)`:
   - Domain 0 (System Core): Register tokens for "destroy", "perpetual", "violated".
   - Domain 6 (Language & Discourse): Register tokens for "meaningless", "nonsense", "contradiction", "noise".
4. In `veto_compute_symbolic_loss_penalty(reg, active_domain, logits_vec, forbidden_token_ids, lambda_sym)`:
   - If `forbidden_token_ids == 0.0`, query `reg.domain_forbidden_tokens` for `active_domain` (and universal domain 0.0) and penalize their logits.

### Phase 2: Chat Forward Pass & Memory Integration (`test/geomind/chat.cl`)
1. Resolve `atomic_discourse.car_graph` with fallback to `nses_knowledge.car_graph`.
2. Prior to `cartan_hopfield_relax(hidden_state, 3.5, 2.0)`:
   - Select salient domain attractor embeddings from `nses_pipe.graph_file` and stage into Hopfield memory via `cartan_hopfield_store_vector`.
3. In autoregressive token generation loop (`while (step < max_t)`):
   - Apply `nses_pipeline_shape_loss(nses_pipe, nses_turn.active_domain, logits_vec, 0.0, 0.25)` directly on `logits_vec` before sampling.

### Phase 3: Training Forward Pass & Dataset Routing (`test/geomind/train.cl`)
1. In dataset routing:
   - Add Domain 6 routing if dataset name contains `"discourse"`, `"dialogue"`, `"chat"`, `"language"`, `"conversation"`, `"atomic"`, or `"conceptnet"`.
2. When active domain is 6.0:
   - `train_sync_salient_attractors_to_gpu(6.0, nses_pipe.graph_file)` stages discourse invariants to GPU VRAM.
   - `nses_pipeline_shape_loss` shapes logits against linguistic contradiction tokens.

### Phase 4: Target 74 Regression Verification
1. Author Target 74 (`test/compiler_suite/test_chat_train_nses_forward_integration.car`):
   - Verify automated forbidden token extraction when `forbidden_tokens == 0.0`.
   - Verify logit suppression and positive penalty calculation.
   - Verify Domain 6 dataset routing logic.
   - Verify Hopfield attractor staging from `.car_graph`.
2. Register Target 74 in `test/compiler_suite/run_tests.car` and `.gitignore`.
3. Rebuild test runner and execute all 74 compiler targets (74/74 passing).
4. Update `ISSUES.md`, `CHANGELOG.md`, `docs/ROADMAP.md`, and save `docs/archive/sprint_464_walkthrough.md`.
