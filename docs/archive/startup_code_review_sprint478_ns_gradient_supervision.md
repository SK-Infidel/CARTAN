# Startup Code Review: Sprint 478
## Neuro-Symbolic Gradient Supervision, Active Critic Backward Pass Shaping & Grokking Acceleration

**Date**: 2026-09-29  
**Author**: Antigravity  
**Reviewer**: Rick  
**Branch**: `master`

---

### 1. Executive Summary & Context
In Sprint 477, we isolated raw neural inference from expert system prompting via `--no-expert-priming` / `--raw-neural` and verified that unprimed neural weights require training gradients to escape echo attractors (such as repeating prompt tokens) and internalize domain associations.

Rick identified the optimal neuro-symbolic cognitive division of labor:
1. Keep inference clean and unpolluted by artificial token forcing.
2. Utilize the expert system as an **Active Training Supervisor / Critic** in the **backward pass**:
   - Shape the loss gradient covector ($\nabla \mathcal{L}_{\text{total}} = \nabla \mathcal{L}_{\text{CE}} + \lambda \cdot \nabla \mathcal{L}_{\text{critic}}$) before backpropagation.
   - Penalize domain contradictions and immediate prompt/history token echoes.
   - Boost ground-truth domain attractors from knowledge bases and invariants.
   - Accelerate grokking by eliminating random-walk exploration on repetitive attractors.
   - Implement online 1-step error correction during inference when domain invariants or known facts are violated.

---

### 2. Code Review & Discovery of Architectural Gaps

#### Gap 1: Disconnected Host-Side Symbolic Loss Penalty
- **Location**: `test/geomind/train.cl` (lines 2723–2732)
- **Defect**:
  ```cartan
  let chunk_loss_raw = geomind_train_chunk_gpu_finish_pass(step_lr, active_tokens[0]);
  g_is_training_pass = 0.0;
  var chunk_loss = chunk_loss_raw;
  if (nses_active == 1.0 && step_lr > 0.0) {
      var null_tokens: ptr = 0.0;
      let sym_penalty = nses_pipeline_shape_loss(nses_pipe, active_d, g_host_train_logits, null_tokens, 0.15);
      if (sym_penalty > 0.0) {
          chunk_loss = chunk_loss + sym_penalty;
      }
  }
  ```
  `geomind_train_chunk_gpu_finish_pass` synchronizes the GPU *after* `g_pipe_sgd` and `g_pipe_head_backward_gemv` have already completed! The `sym_penalty` was only calculated on CPU and added to the printed loss metric; no gradients were ever passed to the GPU cortical weights or backpropagated through the network.

#### Gap 2: Absence of Gradient Shaping in GPU Backprop Chain
- **Location**: `test/geomind/train.cl` (lines 1103–1127)
- **Defect**: In `geomind_train_chunk_gpu_launch_pass`, `g_pipe_softmax_loss_delta` writes cross-entropy delta directly into `g_buf_train_delta`. `g_pipe_sgd` and `g_pipe_head_backward_gemv` immediately consume `g_buf_train_delta`. No kernel existed to inject critic penalties into `g_buf_train_delta` prior to SGD and head backward GEMV.

#### Gap 3: Echo Attractor Vulnerability
- **Location**: `test/geomind/train.cl` and `test/geomind/chat.cl`
- **Defect**: Autoregressive neural sequence models suffer from prompt token repetition ("echo attractors"). Without an active gradient penalty for predicting $t_{k} = t_{k-1}$ when $t_{k-1} \ne y_k$, the model gets trapped in echo minima, vastly prolonging grokking latency.

#### Gap 4: Missing Online 1-Step Error-Correction Hook
- **Location**: `test/geomind/chat.cl`
- **Defect**: In `--chat` and interactive evaluation, when the model makes a factual mistake or violates a domain invariant, it currently had no path to backpropagate corrective gradients into active weights on the fly.

---

### 3. Logical Dependency Tree

```
src/std/veto_gate.cl (VetoRegistry, domain_forbidden_tokens, veto_compute_symbolic_loss_penalty)
       │
       ▼
src/std/nses_pipeline.cl (nses_pipeline_shape_loss, NSES_Pipeline)
       │
       ├────────────────────────────────────────┐
       ▼                                        ▼
test/geomind/train.cl                   test/geomind/chat.cl
  - OpenCL critic supervision kernel       - Online 1-step backward pass
    (geomind_critic_backward_supervision)    (geomind_chat_correct_error_step)
  - VRAM delta buffer shaping              - Invariant violation detection
  - Echo suppression & domain penalty      - Weight delta sync to GPU
  - Backprop through SGD & RMSNorm/FFN          │
       │                                        │
       └───────────────────┬────────────────────┘
                           ▼
                 test/geomind/main.car
                   - CLI flag: --online-critic / --train-on-error
                   - Telemetry and grokking stats
                           ▼
           test/compiler_suite/run_tests.car
             - Target 87: test_ns_gradient_supervision.car
```

---

### 4. Technical Debt & Git Issues Filed
- **[ISSUE-281]**: Neuro-Symbolic Backward Pass Gradient Disconnect in GPU Training Pipeline (`test/geomind/train.cl`).
- **[ISSUE-282]**: Absence of Echo Repetition Suppression in Training Delta Kernel (`test/geomind/train.cl`).
- **[ISSUE-283]**: Online 1-Step Error Correction Missing in Chat & Invariant Evaluation (`test/geomind/chat.cl`).

---

### 5. Sign-Off Assessment
The mathematical foundation for backward-pass covector injection ($\delta_i \leftarrow \delta_i + \Delta_{\text{critic}}$) is exact, strictly adheres to the zero-mock rule, and guarantees that every weight update reflects authentic analytical gradients.
