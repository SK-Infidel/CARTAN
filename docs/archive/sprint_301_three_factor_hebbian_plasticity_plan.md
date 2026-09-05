# Sprint 301 Implementation Plan: Three-Factor Hebbian Plasticity for Real-Time Inference Learning

## 1. Context & Objectives
- **Target**: [Phase 59 Item 3](file:///C:/Users/rich-/source/repos/CARTAN/docs/ROADMAP.md#L177): "Three-Factor Hebbian Plasticity: Implement local neuromodulated synaptic update operator ($\Delta W = \eta \cdot \text{Pre} \cdot \text{Post} \cdot M$) for learning by reading/observing/listening directly during inference."
- **Defect Identified**: `[ISSUE-052]` in `ISSUES.md`: Online inference lacks local synaptic adaptation; model only updates episodic Hopfield attractors or calls backprop SGD, with no zero-backprop three-factor Hebbian synaptic plasticity.

## 2. Mathematical Formulation
1. **Three-Factor Synaptic Plasticity Operator**:
   $$\Delta W_{ij} = \eta \cdot M \cdot (\text{Pre}_i \cdot \text{Post}_j)$$
   where:
   - $\text{Pre}_i$: Pre-synaptic activation from hidden manifold representation $h \in \mathbb{R}^D$
   - $\text{Post}_j$: Post-synaptic target or activated token representation $y \in \mathbb{R}^D$
   - $M$: Neuromodulatory gating signal (dopamine/novelty/surprise, $M \in [-1.0, 1.0]$)
   - $\eta$: Synaptic learning rate
2. **Oja's Normalization & Bounding Condition**:
   $$\Delta W_{ij} = \eta \cdot M \cdot (\text{Pre}_i \cdot \text{Post}_j - \alpha \cdot \text{Post}_j^2 \cdot W_{ij})$$
   prevents weight divergence under repeated co-activation while preserving directional alignment.
3. **Eligibility Trace**:
   $$e_{ij}(t) = \lambda e_{ij}(t-1) + \text{Pre}_i(t) \cdot \text{Post}_j(t)$$
   $$\Delta W_{ij} = \eta \cdot M(t) \cdot e_{ij}(t)$$

## 3. Architecture & Code Changes
1. **Standard Library Module (`src/std/hebbian.cl`)**:
   - `hebbian_three_factor_update(W, pre, post, M, lr, decay)`
   - `hebbian_oja_update(W, pre, post, M, lr, alpha)`
   - `hebbian_trace_update(traces, W, pre, post, M, lr, lambda_decay)`
   - `hebbian_vector_outer_product(pre, post)`
2. **C Runtime Implementation (`src/cartanc/geomind_runtime.c`)**:
   - `cartan_hebbian_update_weights`: C kernel updating 2560x2560 synaptic weight matrix with SIMD/OpenMP.
   - `cartan_tensor_hebbian_update(void* pre_ptr, void* post_ptr, double neuromodulator, double lr)`
   - `cartan_hebbian_step_token(void* hidden_ptr, double tok_id, double neuromodulator, double lr)`
3. **Inference & Chat Integration (`test/geomind/chat.cl`)**:
   - Hook into `geomind_chat_generate_reply`: apply Hebbian update between prompt context state and generated tokens modulated by Hopfield surprise ($M = \tanh(E_{\text{hopfield}} - E_{\text{baseline}})$).
   - Hook into `geomind_chat_apply_human_feedback`: apply Hebbian update using human reward as explicit neuromodulator ($M = \text{reward}$).
   - Hook into `geomind_chat_apply_correction`: reinforce corrected token representations.
4. **Target 53 Verification Suite (`test/compiler_suite/test_hebbian_plasticity.car`)**:
   - Test 1: Pure CARTAN 3-factor outer-product calculation.
   - Test 2: Oja stability and normalization under repeated updates.
   - Test 3: Neuromodulated sign inversion (reward vs penalty).
   - Test 4: C runtime `cartan_tensor_hebbian_update` execution and in-place weight evolution.
5. **Test Runner (`test/compiler_suite/run_tests.car`)**:
   - Register Target 53 and verify all 53 targets pass 100%.

## 4. Logical Dependency Tree
```
src/std/hebbian.cl
├── collections.cl / core_runtime.car (vectors & memory)
└── math.cl (tanh, exp, vector ops)
src/cartanc/geomind_runtime.c
├── cartan_hebbian_update_weights
└── cartan_tensor_hebbian_update
test/geomind/chat.cl
└── hebbian.cl + geomind_runtime.c
test/compiler_suite/test_hebbian_plasticity.car (Target 53)
└── test/compiler_suite/run_tests.car
```
