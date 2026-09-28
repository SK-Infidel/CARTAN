# Sprint 427 Implementation Plan: Gated Reactive Metacognitive Sleep

## Mission
Eliminate spurious reactive sleep consolidation triggers during pretraining by gating reactive sleep triggers on BOTH high loss/PPL spikes and a broken synaptic pruning threshold (`[ISSUE-175]`).

---

## Targeted Issues
1. **[ISSUE-175] Spurious Reactive Metacognitive Sleep Triggers on PPL Spikes Without Broken Synaptic Thresholds**:
   - `test/geomind/train.cl` lines 2624–2642 trigger reactive sleep whenever `vl > ema_val_loss + 0.35` or loss velocity climbs for 2 steps, even when all 8 synapses are above `1.001` and 0 synapses can be pruned.
   - Fix:
     - Implement `cargraph_has_prunable_synapses(csr: CsrGraph, arena: DynamicDeltaArena, threshold: float) -> float` in `src/std/cargraph_consolidate.cl`.
     - Update `train.cl` reactive triggers (`val_climb_streak >= 2.0`, `acute_spike == 1.0`) to require `cargraph_has_prunable_synapses(nses_pipe.csr, cons_arena, 1.001) == 1.0`.
     - Preserve regular scheduled cadence sleep (`Cadence (Every Other Cycle)`) for periodic Hopfield replay and slow-weight synchronization.

---

## Verification Strategy
- Author regression suite `test/geomind/nses/test_sprint14_gated_reactive_sleep.car`.
- Verify `cargraph_has_prunable_synapses` returns `0.0` when all edges are above threshold and arena is empty, and `1.0` when any edge is decayed below `1.001`.
- Verify reactive sleep is bypassed on acute loss/PPL spikes when threshold is not broken.
- Verify clean compilation of `test_sprint14_gated_reactive_sleep.car` and `bin/geomind.exe` with `cartanc.exe`.
