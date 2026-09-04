# Sprint 297 Plan: Authentic Model Fusion & Evolutionary Weight Merging Engine (`[ISSUE-046]`)

## 1. Objectives & Scope
- **Target Issue**: `[ISSUE-046] Undefined Functions in merge_model_weights.cl Causing Linker Failure`
  - Address missing model fusion algorithms in [`src/std/fusion.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/fusion.cl) called by [`test/geomind/merge_model_weights.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/merge_model_weights.cl).
  - Resolve tensor interoperability with `cartan_tree_set` and `cartan_tree_get_f32` in [`src/cartanc/core_runtime.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car).
- **Zero-Mock Commitment**:
  - Implement full, authentic mathematical formulations for:
    1. `fusion_dare_merge(t1, t2, drop_p)`
    2. `fusion_task_arithmetic(base, t1, t2, w1, w2)`
    3. `fusion_knots_orthogonal_merge(base, t1, t2, rank)`
    4. `fusion_m2n2_dynamic_split(t1, t2, split_ratio)`
    5. `fusion_m2n2_attraction_pair(t1, t2)`
    6. `fusion_m2n2_map_elites_crossover(t1, t2, diversity_scale)`
  - Ensure dynamic size allocation via `cartan_tensor_alloc` across all fusion algorithms to handle arbitrary parameter tensor dimensions without 2000-element capacity truncations.

## 2. Mathematical Design
1. **DARE (Drop And REscale)**:
   $$\tilde{\delta}_i = \begin{cases} 0 & \text{with probability } p \\ \frac{1}{1-p}(t_2[i] - t_1[i]) & \text{with probability } 1-p \end{cases}$$
   $$t_{merged}[i] = t_1[i] + \tilde{\delta}_i$$
2. **Task Arithmetic**:
   $$\tau_1 = t_1 - \text{base}, \quad \tau_2 = t_2 - \text{base}$$
   $$\theta_{merged} = \text{base} + w_1 \tau_1 + w_2 \tau_2$$
3. **KnOTS (Knowledge Orthogonal Task Subspaces)**:
   $$\text{proj}_{\tau_1}(\tau_2) = \frac{\langle \tau_1, \tau_2 \rangle}{\|\tau_1\|^2 + \epsilon} \tau_1$$
   $$\tau_2^\perp = \tau_2 - \text{proj}_{\tau_1}(\tau_2)$$
   $$\theta_{merged} = \text{base} + \tau_1 + \tau_2^\perp$$
4. **M2N2 Dynamic Split-Point Boundary Crossover**:
   $$k = \lfloor N \cdot \text{clamp}(\text{split\_ratio}, 0, 1) \rfloor, \quad W = \max(1.0, 0.02 N)$$
   $$\alpha_i = \sigma\left(\frac{i - k}{W}\right), \quad t_{merged}[i] = (1 - \alpha_i) t_1[i] + \alpha_i t_2[i]$$
5. **M2N2 Attraction Pairing**:
   $$v_{mid} = \frac{v_1 + v_2}{2}, \quad w_{pull} = \frac{|v_2| - |v_1|}{1 + |v_1| + |v_2|}$$
   $$v_{merged} = v_{mid} + 0.5 \cdot w_{pull} \cdot (v_2 - v_1)$$
6. **M2N2 MAP-Elites Crossover**:
   $$v_{mid} = \frac{v_1 + v_2}{2}, \quad \Delta = \frac{|v_2 - v_1|}{2}$$
   $$v_{merged} = v_{mid} + \sin(1.61803398875 \cdot i) \cdot \Delta \cdot 0.1 \cdot \text{diversity\_scale}$$

## 3. Work Breakdown & Tasks
- [ ] Task 1: Update [`src/cartanc/core_runtime.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/core_runtime.car) to support tensor fallback in `cartan_tree_set` and `cartan_tree_get_f32`.
- [ ] Task 2: Implement all 6 missing fusion functions in [`src/std/fusion.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/fusion.cl) and modernize existing functions to use `cartan_tensor_alloc`.
- [ ] Task 3: Build and execute [`test/geomind/merge_model_weights.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/merge_model_weights.cl).
- [ ] Task 4: Run full 49-target regression test suite via `scratch/run_tests.exe`.
- [ ] Task 5: Document fix in `ISSUES.md`, update `CHANGELOG.md`, create retro artifact, and commit to `master`.
