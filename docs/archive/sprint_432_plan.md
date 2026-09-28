# Sprint 432 Plan: Line-Synchronized Cloze-Anchored Curriculum & Corpus Regeneration

## Objective
1. **Line-Synchronized Cloze-Anchored Curriculum**:
   Generate 1-to-1 matching cloze companions for every dataset in the pre-training corpus, derived directly from the exact lines of each text dataset. Line $L$ of the cloze companion corresponds to Line $L$ of the text dataset.
2. **Corpus Architecture**:
   Format `corpus.json` as alternating pairs: `[Cloze_1, Text_1, Cloze_2, Text_2, ...]`. As chunk $k$ streams, the engine first trains on the cloze phrases for that passage (priming Hopfield attractors and attention heads with key transition markers and predicates), and then immediately ingests the full continuous text of chunk $k$.
3. **Conversational Corpus Ingestion**:
   Extract clean conversational text from the 4 dialogue datasets (`reddit_casual`, `reddit_qa`, `oasst1`, `alpaca`) and generate their cloze pairs to establish colloquial discourse fluency during pre-training.
4. **Engine Expansion**:
   Expand `g_buf_domain_h` in `test/geomind/train.cl` from 16 to 64 domain slots to safely support 20+ alternating paired datasets.
5. **Fresh Training State Reset**:
   Reset `corpus.json` to epoch 1.0, offset 0.0, lr 0.001, and zeroed loss vectors for a clean, verified training launch.

## Implementation Steps
- **`tools/generate_paired_cloze_corpus.py`**:
  - Extract clean text from conversational JSONL files.
  - Parse each line across all 10 datasets, identifying transition markers (from `language_acquisition.cl`), syntactic clause coordinators, and semantic predicate boundaries.
  - Generate parallel `.jsonl` cloze files where each line is `{"sentence_cloze": "...", "target_phrase": "..."}` with exact line-for-line alignment.
- **`test/geomind/train.cl`**:
  - Expand `g_buf_domain_h` from 16 to 64 slots in `train_mount_gpu()`.
- **`test/geomind/trainingdata/corpus.json`**:
  - Configure 20 alternating datasets (10 cloze-text pairs).
  - Reset training state to offset 0.0, epoch 1.0, starting LR 0.001.
- **Verification**:
  - `test_sprint19_cloze_anchored_corpus.car`: Validate 100% line alignment, JSON parsing, and GPU 64-domain safety.
  - Rebuild `bin/geomind.exe`, verify with `--verify`, and synchronize across workspace.
