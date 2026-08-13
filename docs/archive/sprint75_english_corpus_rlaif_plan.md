# Sprint 75 Implementation Plan: English Corpus Sanitation & 1,000-Question LM-Head RLAIF Engine

## 1. Objectives
- **Sanitize Corpus (`test/geomind/trainingdata/gutenberg_classics.txt`)**: Remove all Latin passages (Newton's Latin *Lex I*) and non-English text (Goethe's German verse), replacing them with 100% pure English classical translations.
- **Re-tokenize English Manifold**: Delete `cache_tokenizer.json` to force `c_runtime.c` & `src/std/hub.car` to ingest pure English vocabulary into native memory (`g_vocab_table[65536]`).
- **Align LM-Head Topic Offsets**: Update topic offsets in `test/geomind/chat.car` to reflect sanitized English word positions.
- **Rebuild & Sync Executable**: Compile `geomind.exe` using `cartanc.exe` and copy to root and `bin/` directories.
- **1,000-Question RLAIF Benchmark**: Execute `tools/rlaif_gutenberg_evaluator.py` across 1,000 questions using LM-Head neural token synthesis ($R_A$ $T=0.35$ vs $R_B$ $T=0.85$), generating an updated 100-session audit log in `tools/gutenberg_rlaif_1000_log.md`.

---

## 2. Step-by-Step Implementation
1. Clean `test/geomind/trainingdata/gutenberg_classics.txt` (English-only).
2. Delete `cache_tokenizer.json`.
3. Update `test/geomind/chat.car` word offsets.
4. Rebuild `geomind.exe` with `cartanc.exe`.
5. Sync `geomind.exe` to root and `bin/`.
6. Launch `python -u tools/rlaif_gutenberg_evaluator.py` in the background.
7. Log Sprint 75 in `CHANGELOG.md`.
