# Sprint 447 Task List

- [x] **Task 1**: Add input file existence checks in `src/cartanc/main.car` for `build`, `run`, `doc`, and `bindgen` commands. Recompile `cartanc.exe` and empirically verify failure on non-existent files.
- [x] **Task 2**: Purge ghost targets (38, 39, 40, 41, 46, 47) from `test/compiler_suite/run_tests.car`, fix target 30 and target 37 file paths, and renumber all valid targets.
- [x] **Task 3**: Purge synthetic sine/cosine mock logits in `--train-distill` across `test/geomind/train.cl`, `test/geomind/main.car`, and `test/geomind/geomind_app.cl`; replace with genuine vocabulary logit distributions.
- [x] **Task 4**: Wire genuine file reading and SentencePiece BPE tokenization into `webgpu_run_causal_training_pipeline` in `test/geomind/train.cl`.
- [x] **Task 5**: Remove dead duplicate file `test/geomind/hub.cl`.
- [x] **Task 6**: Recompile `geomind.exe` and verify all empirical test gates (G1: `test_finsler_randers.exe`, G2: `test_lie_streams.exe`, G3: `test_hybrid_resonant_transformer.exe`, G4: `run_tests.exe`, G5: `geomind.exe --eval-analogy`, G6: `geomind.exe --sleep`).
- [x] **Task 7**: Update `CHANGELOG.md`, `ISSUES.md`, and `docs/ROADMAP.md`.
