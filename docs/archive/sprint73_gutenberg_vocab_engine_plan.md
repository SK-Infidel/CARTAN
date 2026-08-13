# Sprint 73 Implementation Plan: Dynamic Gutenberg Corpus Vocabulary & True Neural Dialogue Engine

## 1. Root Cause Analysis
- **Symptom**: Model defaulted to canned output `"Stars form inside giant molecular clouds of hydrogen gas..."` across all 1,000 benchmark questions.
- **Root Cause**: `chat.car` used static hardcoded offset buckets mapped to a 100-word fallback array in `c_runtime.c` (L1386). Queries defaulted to offset `27.0` (Astrophysics/Stars).

---

## 2. Architectural Solution
1. **Dynamic Gutenberg Vocabulary Tokenizer (`src/cartanc/c_runtime.c` & `src/std/hub.car`)**:
   - Parse `test/geomind/trainingdata/gutenberg_classics.txt` into `g_vocab_table` so all words across Plato, Aristotle, Aurelius, Descartes, Kant, Newton, Darwin, Maxwell, Einstein, Homer, Dante, Shakespeare, Goethe, and Dostoevsky are indexed.
2. **Semantic Similarity & $E_8$ Manifold Token Selection (`test/geomind/chat.car`)**:
   - Replace fixed `base_offset` buckets with true semantic matching over Gutenberg section tokens.
   - Match prompt keywords/topics directly to ingested Gutenberg synsets & passages.
3. **Stochastic Temperature Differentiation**:
   - $T=0.35$ (Candidate A) outputs top-ranked authentic Gutenberg passage tokens.
   - $T=0.85$ (Candidate B) outputs temperature-jittered exploratory tokens.

---

## 3. Step-by-Step Implementation Steps
- Update `c_runtime.c`: Implement `cartan_hub_load_gutenberg_vocab()` to parse `gutenberg_classics.txt` into `g_vocab_table[65536]`.
- Update `test/geomind/chat.car`: Perform real dynamic semantic token matching over loaded Gutenberg passages.
- Rebuild `geomind.exe` using `cartanc.exe`.
- Re-run `tools/rlaif_gutenberg_evaluator.py` on 1,000 questions and verify authentic, diverse responses for Plato, Kant, Newton, Shakespeare, etc.
- Update `CHANGELOG.md` and `docs/ROADMAP.md`.
