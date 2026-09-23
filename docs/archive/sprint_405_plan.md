# Sprint 405 Plan: Multi-Domain Prequential Stream Validation Phasing & Telemetry Layout Restoration

## Background & Objectives
1. **Multi-Domain Validation Phasing Bias**:
   - In Sprint 404, prequential validation executed only when `total_chunks_trained + 1.0` was a multiple of 10. Because the interleaved corpus has 10 datasets, this condition strictly aligned with `d_idx = 9` (dataset 10, `mined_expanded_corpus_cloze_part06.txt`). Datasets 0 through 8 were completely bypassed after baseline startup.
   - Fix: Continuous per-chunk prequential validation across all 10 datasets, recording validation loss in `domain_val_losses` and reporting balanced mixture average `AVL` / `AVPPL`.
2. **Telemetry Layout Restoration**:
   - Restore the original 4-line telemetry comparison format (`Progress ->`, `Train ->`, `Val ->`) on 10-chunk intervals and completely purge the single-line heartbeat dump.
   - Clarify the telemetry header to display `Interleaved Stream [10 Datasets] | 10-Domain Cycle Complete (D1-D10)` rather than misleading `Last: D[10.0: ...]`.

## Scope & Dependencies
- Target: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl)
- Binaries: `test/geomind/geomind.exe`, `bin/geomind.exe`, `./geomind.exe`
- Documentation: `CHANGELOG.md`, `ISSUES.md` (`[ISSUE-157]`), `docs/archive/`

## Execution Plan
1. Implement `domain_val_losses` tracking and per-chunk out-of-sample forward pass before backward pass.
2. Restore warm domain recurrent state before training step.
3. Compute balanced multi-domain validation mixture average `avl` on 10-chunk intervals.
4. Purge 1-line heartbeat output and update telemetry header to indicate 10-domain cycle completion.
5. Rebuild with `cartanc.exe` with Zig `-O3` LTO, verify SHA-256 binary parity across all 3 targets.
6. Verify 4/4 semantic vector analogies passing at Rank 1.
7. Run empirical GPU diagnostic run to verify clean telemetry and balanced metrics.
