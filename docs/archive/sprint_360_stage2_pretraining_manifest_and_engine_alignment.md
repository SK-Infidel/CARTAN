# Sprint 360: Stage 2 Pre-Training Manifest Configuration & Fallback Discovery Alignment

## 1. Overview & Objectives
Configured the primary pre-training manifest (`test/geomind/trainingdata/corpus.json`) and aligned the Stage 2 Causal Pre-training engine (`--train-pre` / `--train-ce`) to sequence across all raw continuous text corpora before advancing to Stage 3 Supervised Fine-Tuning (SFT).

## 2. Dataset Portfolio (142.04 MB Total Across 14 Raw Text Partitions)
1. `test/geomind/trainingdata/sft/fineweb_edu_curated.txt` (36.23 MB)
2. `test/geomind/trainingdata/sft/openwebtext_curated.txt` (37.06 MB)
3. `test/geomind/trainingdata/sft/wikitext103_structural.txt` (7.84 MB)
4. `test/geomind/trainingdata/sft/arxiv_scientific_abstracts.txt` (10.24 MB)
5. `test/geomind/trainingdata/sft/tinystories_narratives.txt` (10.16 MB)
6. `test/geomind/trainingdata/storytelling_corpus.txt` (6.72 MB)
7. `test/geomind/trainingdata/mined_expanded_corpus_cloze_part01.txt` (5.55 MB)
8. `test/geomind/trainingdata/mined_expanded_corpus_cloze_part02.txt` (5.63 MB)
9. `test/geomind/trainingdata/mined_expanded_corpus_cloze_part03.txt` (5.60 MB)
10. `test/geomind/trainingdata/mined_expanded_corpus_cloze_part04.txt` (5.61 MB)
11. `test/geomind/trainingdata/mined_expanded_corpus_cloze_part05.txt` (5.61 MB)
12. `test/geomind/trainingdata/mined_expanded_corpus_cloze_part06.txt` (5.56 MB)
13. `test/geomind/trainingdata/hf_roneneldan_TinyStories.txt` (0.06 MB)
14. `test/geomind/trainingdata/hf_alpaca_stories.txt` (0.16 MB)

Conversational dialogue datasets (`reddit`, `oasst1`, `alpaca`) are reserved for Stage 3 SFT.

## 3. Engine Alignment & Binary Build
- Updated fallback dataset auto-discovery in `test/geomind/train.cl` for `stage_mode == 2.0`.
- Aligned `--train-pre` in `test/geomind/main.car` to default target loss 3.00.
- Recompiled with `cartanc.exe` and synchronized binaries across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe` (SHA-256: `98EDF54D452D1C0976AC7C939BBBC6798B57B0211C0F6FB16053CDF72CAEA048`).
