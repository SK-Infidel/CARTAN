# Sprint 418: Hopfield Attractor Deduplication, Salient Memory Compaction, and Inverted Vectorized Relaxation

## 1. Problem Statement
During Stage 2 Causal CE training, each metacognitive sleep cycle experienced escalating latency (from <1s up to >45s).
Empirical telemetry revealed:
1. `sleep_run_axiomatic_consolidation` unconditionally appended all 42 NSES rule embeddings to `hopfield_basins.bin` on every nap without deduplication, ballooning basin count from 1,241 up to 1,430.
2. `sleep_run_consolidation_cycle` executed an $O(N^2)$ quadratic cross-attractor replay ($1430 \times 1430 \times 2560 \times 3 \approx 15.7 \text{ billion operations}$).
3. `resonator_continuous_hopfield_relax` nested $k < N$ inside $d < \text{dim}$, executing $2560 \times N = 3.66 \text{ million}$ tree lookups per step.
4. `cartan_sleep_consolidate_cycle` accepted a prune threshold (`thresh = 0.98`) but never actually pruned redundant basins.

## 2. Technical Architecture & Logical Dependency Tree
```
  src/std/resonator.cl
    ├── resonator_continuous_hopfield_relax (Loop inversion + sparse softmax pruning)
    ├── resonator_add_attractor_dedup (Cosine threshold deduplication check)
    └── resonator_prune_redundant_basins (Compaction pass discarding cos > 0.98)
          ▲
          │
  src/std/sleep.cl
    ├── sleep_replay_basin (Fast vectorized Hopfield relaxation)
    ├── sleep_run_consolidation_cycle (Prune redundant basins + cap micro-nap replay)
    └── sleep_run_axiomatic_consolidation (Novelty check before insert, zero duplicates)
          ▲
          │
  test/geomind/train.cl & test/geomind/sleep.car
    └── Cadence & Reactive Metacognitive Sleep Consolidation (sub-100ms execution)
```

## 3. Detailed Implementation Steps
1. **Loop Inversion in `src/std/resonator.cl`**:
   - Pull `cartan_tree_get(bank, k)` out of the inner dimension loop.
   - Allocate accumulator `recall` once per step; iterate $k < N$, skipping basins with softmax weight $\le 10^{-4}$.
   - Free temporary vectors (`scores`, `recall`) to prevent RAM leakage.
2. **Attractor Deduplication & Compaction in `src/std/resonator.cl`**:
   - Implement `resonator_add_attractor_dedup(bank, vec, dim, max_cos_thresh)`.
   - Implement `resonator_compact_bank(bank, dim, prune_thresh)` to eliminate duplicates.
3. **Compacted Sleep Cycle in `src/std/sleep.cl`**:
   - Update `sleep_run_consolidation_cycle` to compact the bank with `thresh = 0.98`.
   - Update `sleep_run_axiomatic_consolidation` to check resonance before storing, preventing rule duplication.
   - Cap micro-nap replay to the most salient unique attractors ($\le 64$) for instant resumption.
4. **Sanitize `hopfield_basins.bin`**:
   - Cleanly prune existing 1,430 basins down to genuine unique attractors.
5. **Compilation & Empirical Benchmark**:
   - Compile `geomind.exe` with self-hosted `cartanc.exe`.
   - Execute benchmark sleep cycle and verify execution time $<100\text{ ms}$.
   - Verify zero regressions on NSES test suites.
