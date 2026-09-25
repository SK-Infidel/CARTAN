# Sprint 406 Task List: Live Per-Domain Streaming Telemetry & Continuous Holdout Validation

- [x] Symmetrically establish `val_domain_losses` vector matching `domain_losses` in `test/geomind/train.cl`
- [x] Ensure per-chunk prequential validation forward pass (`lr = 0.0`) updates `val_domain_losses` for each domain
- [x] Shift telemetry output block from 10-chunk gating to stream immediately after each domain chunk finishes
- [x] Report clear per-domain diagnostics: `D[d_idx/num_datasets: path] | Chunk N` with aligned `Train ->` and `Val ->` rows
- [x] Calculate balanced multi-domain mixture averages `ATL` and `AVL` across all active domains in `domain_losses` and `val_domain_losses`
- [x] Recompile natively via `cartanc.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`
- [x] Verify bit-for-bit SHA-256 binary parity across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`
- [x] Run semantic vector analogy verification (4/4 PASS at Rank 1)
- [x] Execute live GPU diagnostic run to verify continuous real-time telemetry streaming
- [x] Record resolution in `ISSUES.md` (`[ISSUE-158]`) and `CHANGELOG.md`
- [x] Archive implementation plan, task list, and walkthrough
