# Sprint 308 Implementation Plan: Phase 66 — Active Continuous Hopfield Associative Basins & Online In-Context 1-Shot Recall

## 1. Objective & Scope
Activate **Phase 66** of the CARTAN Master Development Roadmap:
1. Implement Key-Value Modern Continuous Hopfield Associative Memory ($W_{\text{mem}} = \sum_k \xi_k^{\text{val}} (\xi_k^{\text{key}})^T$) in `src/cartanc/geomind_runtime.c` and `src/std/resonator.cl`.
2. Provide one-shot online memory injection and $\beta$-temperature associative energy basin relaxation during conversational inference in `test/geomind/chat.cl`.
3. Support direct `/remember <fact>` ingestion in interactive chat mode.
4. Author regression test Target 60 (`test/compiler_suite/test_continuous_hopfield_recall.car`), verify clean execution, and register in `test/compiler_suite/run_tests.car`.

---

## 2. Mathematical Specification
1. **Continuous Hopfield Associative Attractor Storage**:
   $$\xi_k^{\text{key}} = \frac{k_k}{\|k_k\|}, \quad \xi_k^{\text{val}} = \frac{v_k}{\|v_k\|} \in \mathbb{R}^{2560}$$
2. **Associative Resonance & Softmax Energy Contraction**:
   $$s_k = \beta \langle \xi_k^{\text{key}}, q \rangle, \quad \alpha_k = \frac{\exp(s_k - \max_j s_j)}{\sum_{m=1}^P \exp(s_m - \max_j s_j)}$$
   $$\text{recalled\_state} = \sum_{k=1}^P \alpha_k \xi_k^{\text{val}}$$
   $$\rho_{\max} = \max_{k=1..P} \langle \xi_k^{\text{key}}, q \rangle$$
3. **Manifold State Blending**:
   $$h_{\text{grounded}} = (1 - \gamma \rho_{\max}) h + (\gamma \rho_{\max}) \text{recalled\_state}$$
   where $\gamma = 0.35$ modulates context anchoring based on resonance confidence.

---

## 3. Tasks & Work Breakdown
- [ ] **Task 1 (`src/cartanc/geomind_runtime.c`)**:
  - Add `g_hopfield_key_basins` and `g_hopfield_val_basins`.
  - Implement `cartan_hopfield_store_pair`, `cartan_hopfield_store_pair_vec`.
  - Implement `cartan_hopfield_query`, `cartan_hopfield_query_vec`.
  - Implement `cartan_hopfield_get_max_resonance`.
  - Update `cartan_hopfield_save_basins` and `cartan_hopfield_load_basins` for dual-matrix serialization with backward-compatible format detection.
- [ ] **Task 2 (`src/std/resonator.cl`)**:
  - Implement `resonator_store_pair` and `resonator_query` for pure Cartan level-2 execution.
- [ ] **Task 3 (`test/geomind/chat.cl`, `test/geomind/main.car`)**:
  - Connect Hopfield query recall into `geomind_chat_generate_reasoning_pass`.
  - Store prompt-reply Key-Value pairs in `geomind_chat_generate_reply_multimodal`.
  - Add `/remember <text>` handling in `geomind_chat_start`.
- [ ] **Task 4 (`test/compiler_suite/test_continuous_hopfield_recall.car`)**:
  - Authored Target 60 testing:
    1. Key-Value attractor pair storage.
    2. Sharp $\beta$ associative query recovery ($\alpha > 0.90, \rho > 0.95$).
    3. Multi-attractor orthogonal separation.
    4. In-context factual sentence recall.
    5. Binary serialization round-trip.
- [ ] **Task 5 (Verification & Closure)**:
  - Verify Target 60 via `cartanc.exe`.
  - Register in `run_tests.car` (60/60 passing).
  - Update `docs/ROADMAP.md`, `ISSUES.md`, and `CHANGELOG.md`.
  - Save retrospective to `docs/archive/`.
