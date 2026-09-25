# Sprint 418 Task List

- [x] **Task 1: Optimize `resonator_continuous_hopfield_relax` in `src/std/resonator.cl`**
  - Invert inner loop order ($k < N$ outer, $d < \text{dim}$ inner) to reduce tree lookups from $O(N \cdot D)$ to $O(N)$.
  - Add sparse thresholding (`weight_k > 0.0001`) to bypass near-zero activations.
  - Free intermediate vectors to guarantee zero memory fragmentation.

- [x] **Task 2: Deduplication and Basin Compaction in `src/std/resonator.cl`**
  - Implement `resonator_add_attractor_dedup(bank, vec, dim, max_cos_thresh)`.
  - Implement `resonator_compact_bank(bank, dim, prune_thresh)` to remove redundant attractors.
  - Expose `cartan_hopfield_store_vector_dedup(vec, dim, max_cos_thresh)`.

- [x] **Task 3: Deduplication & Bounded Micro-Nap Replay in `src/std/sleep.cl`**
  - Update `sleep_run_axiomatic_consolidation` to check novelty ($\cos \le 0.98$) before storing attractors.
  - Update `cartan_sleep_consolidate_cycle` to apply compaction with `thresh = 0.98`.
  - Cap streaming micro-nap replay to the most salient unique attractors ($\le 64$) for instant resumption.

- [x] **Task 4: Sanitize `hopfield_basins.bin`**
  - Deduplicate existing 1,430 basins down to clean canonical attractors.

- [x] **Task 5: Recompile and Empirical Verification**
  - Compile `geomind.exe` via `cartanc.exe`.
  - Benchmark sleep consolidation speed (verify $<100\text{ ms}$).
  - Verify NSES test suites pass.
  - Update `CHANGELOG.md` and `ISSUES.md`.

