# Sprint 405 Task List: Multi-Domain Validation Phasing & Telemetry Restoration

- [x] Identify root cause of dataset 10 validation phasing bias in `test/geomind/train.cl`
- [x] Allocate `domain_val_losses` vector and track per-domain EMA validation loss
- [x] Wire continuous per-chunk prequential validation forward pass (`lr = 0.0`) across all 10 datasets
- [x] Ensure pre-validation recurrent hidden state is restored before autoregressive training step
- [x] Calculate balanced multi-domain mixture average `AVL` / `AVPPL` on 10-chunk intervals
- [x] Purge intrusive single-line heartbeat output
- [x] Update telemetry header to report `10-Domain Cycle Complete (D1-D10)`
- [x] Free `domain_val_losses` on all exit paths in `geomind_train_streaming_steady_state`
- [x] Recompile natively via `cartanc.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`
- [x] Verify bit-for-bit SHA-256 binary parity across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`
- [x] Run semantic vector analogy verification (4/4 PASS at Rank 1)
- [x] Execute live GPU diagnostic run to verify clean telemetry and balanced metrics
- [x] Document resolution in `ISSUES.md` (`[ISSUE-157]`) and `CHANGELOG.md`
- [x] Archive implementation plan, task list, and walkthrough
