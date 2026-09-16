# Sprint 344: Dynamic Learning Rate Adaptation & Manifest Persistence Walkthrough

## Summary of Changes
Resolved static learning rate (`LR`) during streaming cloze curriculum training (`geomind.exe --train-cloze`):
1. **Intra-Epoch Adaptive Learning Rate Engine (`test/geomind/train.cl`)**:
   - **Plateau Detection**: If validation loss fails to drop by at least 0.005 over 3 consecutive evaluation intervals (300 lines), automatically decay `lr = lr * 0.95` (floor 0.001).
   - **Divergence Spike Braking**: If interval training loss spikes above `atl * 1.25` and exceeds 6.0 after 300 steps, emergency brake `lr = lr * 0.90` (floor 0.001).
   - **Continuous Annealing**: Every 500 lines, gently scale `lr = lr * 0.99`.
2. **Manifest Persistence (`cloze_manifest.json` & `corpus.json`)**:
   - Updated `geomind_manifest_save` signature and JSON serialization to record `"current_lr"`.
   - Updated all callsites in `test/geomind/train.cl` and `test/geomind/main.car`.
   - Manifest loading restores `current_lr` when CLI `-lr` is omitted, preserving live adapted learning rates across restarts.
3. **CLI Argument Alignment (`test/geomind/main.car`)**:
   - Set default for `-lr` parameter parsing to `0.0`, allowing explicit CLI overrides while deferring to manifest `current_lr` by default.

## Verification
1. **Self-Hosting Compilation**: Rebuilt `main.car` cleanly with `cartanc.exe`.
2. **Binary Parity**: Verified SHA-256 parity across `bin/geomind.exe`, `./geomind.exe`, `build/geomind.exe`, and `test/geomind/geomind.exe` (`3C12A739291F9AB0B4CAADE4ECFAE2AC5D3751BC9963D366384C626C1DB6FDED`).
3. **Empirical Telemetry**:
   - Observed dynamic descent in live streaming cloze training:
     `0.05 -> 0.0495 -> 0.047025 -> 0.0465547 -> 0.044227`.
   - Confirmed `cloze_manifest.json` persistence of `"current_lr": 0.047025`.
