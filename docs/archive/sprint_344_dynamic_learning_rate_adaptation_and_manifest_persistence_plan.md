# Sprint 344: Dynamic Learning Rate Adaptation & Manifest Persistence Plan

## Problem Statement
During streaming cloze curriculum training (`--train-cloze`), `lr` remained static at `0.05` across hundreds of thousands of sentences. The learning rate was only scaled down at the end of full epochs, failing to adapt to intra-epoch plateaus or divergence spikes. In addition, restarting training reset `lr` back to initial base ceilings due to missing manifest persistence.

## Objectives
1. **Intra-Epoch Dynamic LR Engine**:
   - **Validation Plateau Braking**: Decay `lr = lr * 0.95` when validation loss fails to improve by 0.01 over 3 consecutive intervals (300 lines). Floor: `0.001`.
   - **Divergence Spike Braking**: Emergency brake `lr = lr * 0.90` if `tl > atl * 1.25` and `tl > 6.0` after 300 steps. Floor: `0.001`.
   - **Continuous Annealing**: Decay `lr = lr * 0.99` every 500 lines. Floor: `0.001`.
2. **Manifest Persistence**:
   - Update `geomind_manifest_save(path, list, cur_idx, cur_offset, cur_ep, cur_lr)` to serialize `"current_lr"`.
   - Update all callsites in `test/geomind/train.cl` and `test/geomind/main.car`.
   - Restore `current_lr` on resumption when CLI `-lr` is omitted.
3. **CLI Argument Override**:
   - Default CLI `-lr` to `0.0` in `test/geomind/main.car`. If `-lr` is provided, override manifest; if omitted, load adapted `current_lr` from manifest.
4. **Empirical Verification**:
   - Compile using self-hosting `cartanc.exe`.
   - Ensure SHA-256 binary parity across all 4 production paths (`bin/geomind.exe`, `./geomind.exe`, `build/geomind.exe`, `test/geomind/geomind.exe`).
   - Run short multi-line test and verify dynamic LR transitions in telemetry.
