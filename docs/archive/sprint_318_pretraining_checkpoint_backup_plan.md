# Sprint 318 Plan: Pre-Training Checkpoint Safety Backup & Interruption (Ctrl-C) Detection

## 1. Objective & Scope
- Implement automated pre-training checkpoint backup to prevent checkpoint corruption during flawed or interrupted runs.
- Distinguish between clean runs and aborted/interrupted runs (e.g. Ctrl-C, SIGINT, process crashes).
- Automatically back up `geomind_steady_state_weights.bin` to `geomind_steady_state_weights.bin.bak` ONLY when the previous run was successful.
- Automatically restore from `geomind_steady_state_weights.bin.bak` if a previous run was interrupted mid-flight.

## 2. Architecture & Design
- **Status State Machine (`test/geomind/train.cl`)**:
  - State file: `test/geomind/trainingdata/checkpoints/checkpoint_status.txt`.
  - States: `SUCCESS` (clean completion) vs. `IN_PROGRESS` (active run).
  - Startup protocol:
    1. Read `checkpoint_status.txt`.
    2. If `SUCCESS`: Copy `geomind_steady_state_weights.bin` to `geomind_steady_state_weights.bin.bak`.
    3. If `IN_PROGRESS`: Log warning, copy `geomind_steady_state_weights.bin.bak` back over `geomind_steady_state_weights.bin` to rollback partial weights.
    4. Write `IN_PROGRESS\n` to `checkpoint_status.txt`.
  - Shutdown protocol:
    1. Serialize weights to `geomind_steady_state_weights.bin`.
    2. Write `SUCCESS\n` to `checkpoint_status.txt`.

## 3. Verification Criteria
- Verified backup creation on clean runs.
- Verified rollback on simulated interrupted runs.
- Full 62-target regression suite passes cleanly.
