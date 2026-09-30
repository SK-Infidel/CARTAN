# Sprint 478 Plan
## Neuro-Symbolic Gradient Supervision, Active Critic Backward Pass Shaping & Grokking Acceleration

**Goal**: Transform the Expert System (NSES / Veto Gate / Knowledge Graph) into an active backward-pass supervisor and online critic that directly shapes weight gradients ($\nabla \mathcal{L}_{\text{total}} = \nabla \mathcal{L}_{\text{CE}} + \lambda \cdot \nabla \mathcal{L}_{\text{critic}}$), penalizes echo repetitions and domain contradictions, accelerates grokking, and provides online 1-step error correction during inference.

---

### User Stories
1. **As a Machine Learning Researcher (Rick)**:
   I want the Expert System to supervise the model during the **backward pass** rather than cheating during inference, so that the neural network's parameters genuinely internalize domain invariants, escape repetitive echo plateaus, and grok factual relationships faster.
2. **As an AI Systems Engineer**:
   I want the training pipeline in `test/geomind/train.cl` to inject analytical critic penalties directly into the VRAM logit delta buffer ($\delta_i$) before SGD and head backward GEMV execute on GPU, ensuring all 42 layers receive genuine shaped gradients.
3. **As a Conversational Agent**:
   I want interactive chat (`geomind.exe --chat --online-critic`) to detect invariant violations or factual errors and run a 1-step backward pass in-place, allowing the model to adaptively correct its weights on the fly.

---

### Mathematical Architecture
1. **Delta Covector Shaping**:
   Cross-entropy loss gradient with respect to logit $z_i$:
   $$\delta_i = \frac{\partial \mathcal{L}_{\text{CE}}}{\partial z_i} = \frac{p_i - y_i}{T} \cdot \text{IC}_i$$
   The Critic shapes $\delta_i$ into $\delta_i^*$ before weight update:
   $$\delta_i^* = \delta_i + \lambda_{\text{echo}} \cdot \mathbb{I}(i = \text{prev\_tok} \land i \ne y) + \lambda_{\text{sym}} \cdot \mathbb{I}(i \in \mathcal{F}_{\text{domain}}) - \lambda_{\text{boost}} \cdot \mathbb{I}(i = y_{\text{attractor}})$$
2. **Weight Update via SGD with Reverse Randers Metric**:
   $$W_{r, c} \leftarrow W_{r, c} \cdot (1 - \eta \cdot \text{decay}) - \eta \cdot h_r \cdot \delta_{\text{curved}, c}^*$$
   where $\delta_{\text{curved}}^*$ incorporates the Killing-Cartan metric and background drift.
3. **Deep Backpropagation**:
   The shaped covector $\delta^*$ is projected into the hidden gradient:
   $$dh = W^T \cdot \delta_{\text{curved}}^*$$
   which cascades through RMSNorm backward, Continuous Hopfield backward, Causal Self-Attention backward, 16-expert Freudenthal FFN backward, and 8 Lie streams backward.
4. **Online 1-Step Error Correction**:
   When error is flagged on token $t_{\text{wrong}}$ vs canonical $t_{\text{correct}}$:
   $$\Delta W_{r, t_{\text{wrong}}} = -\eta \cdot h_r \cdot \lambda_{\text{pen}}$$
   $$\Delta W_{r, t_{\text{correct}}} = +\eta \cdot h_r \cdot \lambda_{\text{boost}}$$

---

### Scope & Deliverables
1. **`src/std/veto_gate.cl`**:
   - Add `veto_registry_get_domain_forbidden_array` to export flat float array of forbidden tokens for GPU VRAM transfer.
2. **`test/geomind/train.cl`**:
   - Add OpenCL kernel `geomind_critic_backward_supervision` and pipeline `g_pipe_critic_supervision`.
   - Allocate `g_buf_critic_forbidden` and `g_host_critic_forbidden`.
   - Wire `g_pipe_critic_supervision` in `geomind_train_chunk_gpu_launch_pass` between `g_pipe_softmax_loss_delta` and `g_pipe_sgd`.
   - Update `geomind_train_chunk_gpu_finish_pass` to sync active domain forbidden tokens.
3. **`test/geomind/chat.cl`**:
   - Implement `geomind_chat_correct_error_step` performing 1-step backward update on `g_cortical_weights` when invariant or factual error occurs.
   - Wire `--online-critic` / `--train-on-error` flag into chat loop.
4. **`test/geomind/main.car`**:
   - Add `--online-critic` / `--train-on-error` CLI options and help text.
5. **`test/compiler_suite/test_ns_gradient_supervision.car`**:
   - Author Regression Target 87 validating that active critic backward supervision produces non-zero weight deltas, suppresses echo tokens, and reduces domain violation loss.
6. **Verification**:
   - Run `tools/run_affected_tests.ps1 -Sprint 478`.
   - Verify compilation and zero runtime regressions.
