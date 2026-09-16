# Sprint 334 Plan: Decoupling TL vs ATL Metrics & Multi-Binary Deployment Synchronization

## Mission & Purpose
Eliminate telemetry parroting where `TL` and `ATL` printed identical values due to sharing the same epoch loss accumulator `ep_loss_sum / ep_step_count`. Release Windows process handle locks on root `geomind.exe` and synchronize all four binary targets.

## Root Cause Analysis
1. In `test/geomind/train.cl`, `cur_loss = ep_loss_sum / ep_step_count`.
2. Telemetry reporting assigned `let atl = ep_loss_sum / ep_step_count;` and `let tl = cur_loss;`. Both referred to the cumulative epoch average, causing `TL` and `ATL` to be identical.
3. Windows process PID 31572 locked root `./geomind.exe`, blocking `Copy-Item bin/geomind.exe geomind.exe` from deploying the updated binary.

## Execution Steps
1. Add `interval_loss_sum` and `interval_step_count` accumulators in `test/geomind/train.cl`.
2. Compute `tl = interval_loss_sum / interval_step_count` and reset after each reporting interval.
3. Terminate locked process PID 31572.
4. Synchronize all four binaries (`./geomind.exe`, `bin/geomind.exe`, `build/geomind.exe`, `test/geomind/geomind.exe`).
5. Empirically verify metric divergence on Cloze training.
