# Sprint 478 Task List
## Neuro-Symbolic Gradient Supervision, Active Critic Backward Pass Shaping & Grokking Acceleration

- [x] **Task 1: Pre-Sprint Scrum & Squad Alignment**
  - [x] Spawn Compiler Core Squad (`cartan_compiler_engineer`) to review AST/codegen implications.
  - [x] Spawn Architecture Squad (`cartan_architect`) to review mathematical gradient shaping and Randers backprop.
  - [x] Spawn QA Squad (`cartan_qa_tester`) to establish empirical verification criteria for Target 87.

- [x] **Task 2: Standard Library Veto Registry Expansion (`src/std/veto_gate.cl`)**
  - [x] Implement `veto_registry_get_domain_forbidden_mask(reg, domain_id, out_mask, max_count)` for dense GPU buffers.
  - [x] Implement `veto_registry_get_domain_forbidden_array(reg, domain_id, out_buf, max_count)` for flat CPU lists.
  - [x] Add brief comments explaining intent.

- [x] **Task 3: GPU Training Pipeline Critic Gradient Supervision (`test/geomind/train.cl`)**
  - [x] Author OpenCL kernel `geomind_critic_backward_supervision`.
  - [x] Build pipeline `g_pipe_critic_supervision` and allocate VRAM buffers `g_buf_critic_forbidden` / `g_host_critic_forbidden`.
  - [x] Wire critic supervision kernel into `geomind_train_chunk_gpu_launch_pass` between `g_pipe_softmax_loss_delta` and `g_pipe_sgd`.
  - [x] Dynamically sync active domain forbidden tokens into `g_buf_critic_forbidden`.
  - [x] Connect echo suppression penalty (`lambda_echo = 0.25`) when `prev_tok == t` and `prev_tok != next_tok`.

- [x] **Task 4: Online 1-Step Error Correction in Inference (`test/geomind/chat.cl`)**
  - [x] Implement `geomind_chat_correct_error_step(cur_h: ptr, wrong_tok: float, correct_tok: float, lr: float)`.
  - [x] Connect error trigger when veto gate trips or known factual relation is violated in chat.
  - [x] Gate under `g_online_critic_enabled == 1.0`.
  - [x] Implement Hopfield memory quarantine preventing uncorrected contradictory attractors from persisting into associative basins.

- [x] **Task 5: CLI Flag Wiring & Main Harness (`test/geomind/main.car`)**
  - [x] Add `--online-critic`, `--train-on-error`, and `-critic` CLI options to `test/geomind/main.car`.
  - [x] Update `--help` documentation.

- [x] **Task 6: Regression Test Suite Expansion (Target 87)**
  - [x] Author `test/compiler_suite/test_ns_gradient_supervision.car`.
  - [x] Verify 4 validation gates:
    - Gate 1: Cross-entropy base loss and delta calculation.
    - Gate 2: Critic echo suppression and domain contradiction gradient shaping.
    - Gate 3: 1-step analytical SGD weight update verification.
    - Gate 4: Zero-mock genuine parameter delta assertion.
  - [x] Register Target 87 in `test/compiler_suite/run_tests.car` and `tools/run_affected_tests.ps1`.

- [x] **Task 7: Empirical QA Verification**
  - [x] Compile and run Target 87 with `cartanc.exe`.
  - [x] Run `tools/run_affected_tests.ps1 -Sprint 478` (5/5 targets passed).
  - [x] Run `geomind.exe --chat "The capital of france is," --no-expert-priming --online-critic` to verify clean execution.

- [x] **Task 8: Retrospective, Documentation & Archive**
  - [x] Update `CHANGELOG.md` with version `[8.436.0]`.
  - [x] Update `ISSUES.md` with Issues 281, 282, 283.
  - [x] Save Sprint 478 Walkthrough to `docs/archive/sprint_478_walkthrough.md`.
