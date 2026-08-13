# Sprint 76 Implementation Plan: Bigram Transition Matrix, Exception-Masked Sampler, & SFT Grokking Engine

## 1. Objectives
- **Corpus Bigram Transition Engine (`src/cartanc/c_runtime.c` & `src/std/tokenizer.car`)**: Track natural English word pair transitions ($P(t_k \mid t_{k-1})$) from `gutenberg_classics.txt`, enabling valid repetitions (e.g. `"that that"`, `"had had"`, `"very very"`).
- **Distance-Decayed Repetition Penalty with Bigram Exception Bypass (`test/geomind/chat.car`)**:
  - Implement a 12-token sliding window history filter with exponential distance decay ($\beta \cdot e^{-0.3 \cdot d}$).
  - Bypass penalty entirely if `cartan_tokenizer_is_valid_bigram(prev_tok, cand_tok) == 1.0`.
- **SFT Grokking Fine-Tuning Run (`geomind.exe --train-sft`)**: Execute a multi-epoch SFT backpropagation pass to train attention matrices for continuous syntactic flow ($L < 0.35$).
- **1,000-Question RLAIF Benchmark Pass**: Run `tools/rlaif_gutenberg_evaluator.py` to evaluate cogent sentence outputs across all 1,000 questions and log the 100 decimated entries in `tools/gutenberg_rlaif_1000_log.md`.

---

## 2. Dependency Tree
- `src/cartanc/c_runtime.c` (`cartan_tokenizer_is_valid_bigram`)
  └── `src/std/tokenizer.car` (`tokenizer_sample_topk_penalized`)
      └── `test/geomind/chat.car` (`geomind_chat_generate_reply`)
          ├── Sliding history buffer `history[12]`
          ├── Distance-decayed penalty + Bigram bypass
          └── Autoregressive neural state update

---

## 3. Step-by-Step Implementation Steps
1. Update `c_runtime.c`: Implement bigram transition tracking and C-API `cartan_tokenizer_is_valid_bigram(double tok1, double tok2)`.
2. Sync `c_runtime.c` to `C:\Users\rich-\.cartan\c_runtime.c`.
3. Update `test/geomind/chat.car`: Add 12-token history buffer, distance-decayed penalty, and bigram bypass logic.
4. Rebuild `geomind.exe` with `cartanc.exe` and sync to root and `bin/`.
5. Run SFT training pass (`geomind.exe --train-sft`).
6. Launch 1,000-question RLAIF benchmark evaluator script in the background.
7. Log Sprint 76 in `CHANGELOG.md` and update `docs/ROADMAP.md`.
