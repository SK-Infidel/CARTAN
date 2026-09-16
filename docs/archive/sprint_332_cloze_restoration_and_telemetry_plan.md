# Sprint 332 Implementation Plan: Cloze Clean Corpus Extraction, Validation Telemetry Restoration, Checkpoint Fusion, and Binary Synchronization

## Objectives
1. **Clean Cloze Corpus Extraction**: Extract all 240,000 cloze pairs across 6 raw JSONL files into clean, continuous prose text files (`mined_expanded_corpus_cloze_part01..06.txt`), eliminating JSON syntax/boilerplate contamination (`{"sentence_cloze": ...}`).
2. **Validation Holdout Dataset**: Construct an independent 200-sentence validation holdout file (`test/geomind/trainingdata/cloze_validation_holdout.txt`).
3. **Pure CARTAN File Append**: Add `cartan_append_file` and `fs_append_all` in `src/std/fs.cl` using standard C `fopen(path, "a")`.
4. **Validation Cross-Entropy Loss Engine**: Implement `geomind_compute_validation_loss` in `test/geomind/train.cl` running zero-weight-update forward passes (`learning_rate <= 0.0`) over holdout tokens via `e8_attention_forward_step` and `cartan_tensor_train_step`.
5. **Full Telemetry Restoration**: Restore historical streaming metrics to console and `logs/stage1_cloze_training.log`:
   - `TL`: Instantaneous Training Loss
   - `ATL`: Average Training Loss across the epoch
   - `VL`: Holdout Validation Cross-Entropy Loss
   - `AVL`: Exponential Moving Average Validation Loss
   - `VPPL`: Validation Perplexity ($\exp(\text{AVL})$)
   - `LR`: Current Learning Rate
6. **Fresh Geodesic Weight Fusion**: Purge corrupted checkpoints and execute fresh SLERP merge (`--merge-slerp`).
7. **Binary Synchronization**: Ensure all 4 `geomind.exe` binary locations (`./`, `bin/`, `build/`, `test/geomind/`) are recompiled and synchronized.
8. **Empirical Verification**: Launch Stage 1 Cloze training and verify loss descent with zero memory leaks.
