# Sprint 319 Plan: Unified Training Pipeline Documentation & CLI Help Reference

## 1. Objective & Scope
- Document that omitting learning rate arguments runs with the optimal safe default ceiling ($0.001$), geometric decay ($0.995$/epoch), and floor ($0.0001$).
- Update `print_help_dialogue()` in `test/geomind/main.car` so `--help` displays training flags, stage target losses, and safety rollback mechanics.
- Add Section 5 to `docs/TRAINING_TOOLCHAIN.md` providing a permanent reference for the 3-stage curriculum, CLI arguments, and rollback protocol.

## 2. Architecture & Design
- **CLI Reference (`test/geomind/main.car`)**:
  - Add "Training & Optimization Flags" and "Safety & Rollback Features" sections to `print_help_dialogue()`.
- **System Documentation (`docs/TRAINING_TOOLCHAIN.md`)**:
  - Document Stage 1 Cloze (`4.20`), Stage 2 CE (`3.00`), Stage 3 SFT (`2.00`).
  - Document parameter table with default values.
  - Document `.bin.bak` and `checkpoint_status.txt` behavior.

## 3. Verification Criteria
- `build/geomind.exe --help` displays updated documentation.
- `docs/TRAINING_TOOLCHAIN.md` contains comprehensive Section 5.
