# Sprint 371 Plan: Pretraining Curriculum Restructuring, Outlier Elimination & Multi-Register Holdout

## Objective
Eliminate domain whiplash, toddler syntax regression, and format pollution from Stage 2 Causal CE pretraining. Restructure the curriculum into an interleaved prose-cloze pipeline with a balanced 4-register validation holdout to achieve smooth, monotonic loss and perplexity descent.

## User Stories
1. **As an AI Research Engineer**, I need outlier corpora (`arxiv`, `tinystories`, `alpaca`) de-listed from Stage 2 pretraining so that the semantic metric tensor and vocabulary representations are not distorted by LaTeX notation, QA prompt delimiters, or toddler-level vocabulary.
2. **As an ML Practitioner**, I need `storytelling_corpus.txt` sanitized of markdown dividers (`===`, `###`) and multi-byte smart quotes so that training loss does not suffer artificial spikes ($TL \ge 7.25$).
3. **As a Model Evaluator**, I need `pretrain_validation_holdout.txt` to contain a balanced mixture of Classic Literature, Educational Web, Encyclopedic Prose, and Syntactic Cloze so that validation perplexity reflects authentic general language acquisition.
4. **As an Architect**, I need prose and cloze datasets interleaved rather than sequentially segregated so that the model never drifts into monolithic domain overfit or catastrophic forgetting.

## Tasks
1. [x] Audit active training run and identify sources of distribution shock (`arxiv` +44.2 VPPL, `tinystories` 173.53 VPPL, `storytelling` TL=7.25).
2. [x] Terminate active background training process (`geomind.exe` PID 40184) and free GPU resources.
3. [x] Implement `tools/sanitize_corpus.py` to strip markdown banners and normalize curly quotes in `storytelling_corpus.txt` $\to$ `storytelling_corpus_clean.txt`.
4. [x] Implement `tools/build_balanced_holdout.py` to create a 100-chunk 4-way balanced holdout (Literature, FineWeb-Edu, WikiText-103, Syntactic Cloze).
5. [x] De-list `arxiv`, `tinystories`, and `alpaca` from Stage 2 in `test/geomind/train.cl` and `test/geomind/trainingdata/corpus.json`.
6. [x] Interleave clean prose with cloze syntactic anchors in `corpus.json` and `train.cl`.
7. [x] Recompile `geomind.exe` with `cartanc.exe` and synchronize binaries across all paths.
8. [x] Verify semantic vector analogies remain at Rank 1 (`--eval-analogy`).
9. [x] Launch clean pretraining run and empirically verify smooth loss descent.
10. [x] Update `ISSUES.md`, `CHANGELOG.md`, and archive sprint documentation.
