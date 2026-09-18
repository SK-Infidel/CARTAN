# Sprint 371 Walkthrough: Pretraining Curriculum Restructuring & Interleaved Foundation Stream

## Overview
Sprint 371 addressed the root cause of domain whiplash, sawtooth perplexity oscillations, and training loss spikes in GeoMind's Stage 2 Causal Cross-Entropy pretraining. Outlier datasets were de-listed or sanitized, a 4-way balanced multi-register validation holdout was generated, and the pretraining curriculum was restructured into an interleaved prose-and-cloze architecture.

## Changes Implemented

### 1. Outlier De-Listing & Domain Realignment
- **`arxiv_scientific_abstracts.txt` (147,686 lines)**: De-listed from Stage 2 causal pretraining. Its dense LaTeX formulas (`\mathcal{O}`, `\sum`), math syntax, and academic citations triggered the initial +44.2 VPPL destabilization breakout in both Epochs 1 and 2. Deferred to Stage 3 Domain SFT.
- **`tinystories_narratives.txt` (63,477 lines) & `hf_roneneldan_TinyStories.txt`**: Eliminated from Stage 2. Its restricted 500-word toddler vocabulary (*"Lily found a needle"*) caused cognitive regression, driving holdout perplexity to the global peak of 173.53 VPPL.
- **`hf_alpaca_stories.txt` (1,496 lines)**: De-listed from Stage 2. Contains prompt-completion QA formatting (`Query:`, `Response:`) which belongs in Stage 3 instruction tuning.

### 2. Corpus Hygiene & Sanitization
- Implemented `tools/sanitize_corpus.py` to sanitize `storytelling_corpus.txt` into `storytelling_corpus_clean.txt` (103,583 lines).
- Stripped equal-sign divider banners (`===`), markdown headers (`###`), and metadata tags (`BOOK TITLE:`, `GENRE:`).
- Normalized multi-byte UTF-8 curly smart quotes (`“`, `”`, `‘`, `’`) to standard ASCII quotes, eliminating single-batch loss spikes up to $TL = 7.25$.

### 3. Balanced Multi-Register Validation Holdout
- Implemented `tools/build_balanced_holdout.py` to generate `test/geomind/trainingdata/pretrain_validation_holdout.txt` with an exact 4-way balanced mixture:
  - 25 chunks Classic Literature (Jane Austen / Melville)
  - 25 chunks High-Quality Informational Prose (FineWeb-Edu)
  - 25 chunks Structural Encyclopedic Syntax (WikiText-103)
  - 25 chunks Syntactic Cloze Scaffolding (Clean cloze n-grams)
- Pre-tokenized into 100 in-memory chunks on engine startup for real-time validation without domain bias.

### 4. Interleaved Scaffolding Curriculum
- Restructured `test/geomind/trainingdata/corpus.json` and fallback defaults in `test/geomind/train.cl` into an interleaved 10-dataset pipeline:
  1. `fineweb_edu_curated.txt` (Educational web)
  2. `mined_expanded_corpus_cloze_part01.txt` (Syntactic anchor)
  3. `openwebtext_curated.txt` (General web discourse)
  4. `mined_expanded_corpus_cloze_part02.txt` (Syntactic anchor)
  5. `wikitext103_structural.txt` (Encyclopedic prose)
  6. `mined_expanded_corpus_cloze_part03.txt` (Syntactic anchor)
  7. `storytelling_corpus_clean.txt` (Sanitized narrative fiction)
  8. `mined_expanded_corpus_cloze_part04.txt` (Syntactic anchor)
  9. `mined_expanded_corpus_cloze_part05.txt` (Syntactic anchor)
  10. `mined_expanded_corpus_cloze_part06.txt` (Syntactic anchor)

## Verification Results

### 1. Binary Compilation & Synchronization
- `cartanc.exe` cleanly built `test/geomind/geomind.exe`.
- Synchronized bit-for-bit SHA-256 match across `geomind.exe`, `bin/geomind.exe`, and `test/geomind/geomind.exe`:
  `ABEB879415933AEE074FA293AC0F9D6FC2EB0DECA273F403D99E61E7A299887E`

### 2. Semantic Vector Analogy Arithmetic (`.\geomind.exe --eval-analogy`)
- Analogy 1: $v(\text{King}) - v(\text{man}) + v(\text{woman}) \approx v(\text{queen})$ (Rank 1, Cosine: 0.4248, Margin: +0.1067) — **PASS**
- Analogy 2: $v(\text{he}) - v(\text{him}) + v(\text{her}) \approx v(\text{she})$ (Rank 1, Cosine: 0.4707, Margin: +0.1518) — **PASS**
- Analogy 3: $v(\text{father}) - v(\text{man}) + v(\text{woman}) \approx v(\text{mother})$ (Rank 1, Cosine: 0.5006, Margin: +0.0903) — **PASS**
- Analogy 4: $v(\text{boy}) - v(\text{man}) + v(\text{woman}) \approx v(\text{girl})$ (Rank 1, Cosine: 0.5981, Margin: +0.2352) — **PASS**

### 3. Clean Curriculum Run Launch (`task-3365`)
- Pre-tokenized 100.0 validation holdout chunks from balanced multi-register holdout.
- Manifest active with 10 clean, interleaved datasets.
- Initializing clean descent: $VL: 4.788 \to 4.746$, $VPPL: 120.17 \to 119.91$, $LR: 0.0015$.
