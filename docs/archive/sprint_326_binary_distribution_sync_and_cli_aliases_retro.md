# Sprint 326 Retrospective: Binary Distribution Sync & CLI Argument Aliases

---

## 1. Executive Summary

- **Sprint**: 326
- **Primary Objective**: Investigate stalled Cloze training on epoch 11 with flat loss, trace execution path to binary, terminate stale process, synchronize binary deployments across `bin/geomind.exe` and `./geomind.exe`, and add CLI argument aliases (`-tl`, `-ep`).
- **Trigger**: User reported: *"Ok, now it's the opposite problem. It's on the 11th epoch of cloze training and it's not dropping."*
- **Outcome**: **SUCCESS**. Identified that `.\bin\geomind.exe` was an outdated legacy C-runtime binary from September 2nd holding 41.5 GB of RAM. Terminated stale process 13772, added `-tl` and `-ep` CLI argument aliases in `main.car`, recompiled with `cartanc.exe`, synchronized identical pure-Cartan binaries across `build/`, `bin/`, and repo root, and empirically verified correct startup loss (`6.12`) with `-tl 3.80`.

---

## 2. Root Cause Analysis

1. **Stale Binary Execution (`bin/geomind.exe`)**:
   - The user ran `.\bin\geomind.exe --train-cloze -tl 3.50`.
   - Inspection of `bin/geomind.exe` revealed it was built on **September 2, 2026** (13.3 MB, legacy C runtime), predating Sprints 320–325.
   - It executed the deprecated 42-layer / 256k vocabulary streaming loop with cosine LR annealing that decayed LR to `0.000063`, stalling train loss at ~9.5 and validation loss at ~11.5 with validation perplexity >107,000.
2. **Missing Binary Synchronization**:
   - Recent compiler builds only compiled to `build/geomind.exe` (1.26 MB) without syncing to `bin/geomind.exe` or the repository root `./geomind.exe`.
3. **CLI Parameter Aliases (`-tl` vs `-target-loss`)**:
   - `main.car` only matched `-target-loss` and `-epochs`. Short flags like `-tl 3.50` were ignored and fell back to hardcoded stage defaults.

---

## 3. Implemented Solutions

1. **Process Termination**:
   - Force-stopped stale PID 13772 (`geomind.exe`), freeing 41.5 GB of RAM.
2. **CLI Argument Aliases (`test/geomind/main.car`)**:
   - Implemented `get_cli_target_loss(arg_count, default_val)` supporting both `-target-loss` and `-tl`.
   - Implemented `get_cli_epochs(arg_count, default_val)` supporting both `-epochs` and `-ep`.
3. **Multi-Location Binary Deployment**:
   - Recompiled `test/geomind/main.car` via `cartanc.exe`.
   - Deployed updated 1.26 MB native executable across all distribution paths:
     - `build/geomind.exe`
     - `bin/geomind.exe`
     - `./geomind.exe`
4. **Empirical Verification**:
   - Tested `.\bin\geomind.exe --train-cloze -tl 3.80 -epochs 1`.
   - Verified that `bin/geomind.exe` parsed `-tl 3.8` and initialized with baseline step loss `6.12329`.

---

## 4. Artifacts & Deliverables

- `test/geomind/main.car`: Added `get_cli_target_loss` and `get_cli_epochs` helpers.
- `bin/geomind.exe`: Synchronized to latest pure-Cartan build.
- `geomind.exe`: Synchronized root binary.
- `ISSUES.md`: Logged `[ISSUE-075]`.
- `CHANGELOG.md`: Updated with Sprint 326.
