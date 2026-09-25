# Sprint 406 Plan: Live Per-Domain Streaming Telemetry & Continuous Holdout Validation

## Background & Objectives
1. **Per-Domain Telemetry Streaming**:
   - Provide immediate feedback upon completion of each domain chunk (~every 2.5s) rather than holding output behind a 10-chunk interval.
   - Display clear per-domain diagnostics pairing `Train ->` and `Val ->` comparison metrics directly for each active dataset.
2. **Symmetric `val_domain_losses` Tracking**:
   - Maintain `val_domain_losses` matching `domain_losses` so `AVL` and `AVPPL` represent the true balanced mean across all 10 domain holdouts.
   - Guarantee that every chunk is validated by its respective domain holdout in an out-of-sample forward pass before gradient updates.

## Scope & Target Files
- Code: [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl)
- Binaries: `test/geomind/geomind.exe`, `bin/geomind.exe`, `./geomind.exe`
- Documentation: `CHANGELOG.md`, `ISSUES.md` (`[ISSUE-158]`), `docs/archive/`

## Execution Plan
1. Rename `domain_val_losses` to `val_domain_losses` in `train.cl`.
2. Move telemetry output block from 10-chunk gating to execute after each domain chunk finishes.
3. Include explicit domain identifier `D[d_idx/num_datasets: path] | Chunk N` in each report header.
4. Calculate balanced mixture averages `atl` and `avl` across all 10 domain holdouts on each chunk.
5. Rebuild with `cartanc.exe` with Zig `-O3 LTO`, verify SHA-256 binary parity across all 3 targets.
6. Verify 4/4 semantic vector analogies passing at Rank 1.
7. Execute live GPU diagnostic run to verify continuous streaming telemetry.
