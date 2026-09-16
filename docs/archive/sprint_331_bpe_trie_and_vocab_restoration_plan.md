# Sprint 331 Implementation Plan: Native 65k BPE Trie Restoration & Architecture Purification

## 1. Objectives & Executive Summary
- **Primary Mission**: Eliminate the single-byte ASCII fallback ($b + 235$) and 512-token clamping introduced in Sprint 323. Restore Google Gemma's official SentencePiece BPE tokenizer across the active 65,536 vocabulary in pure CARTAN syntax.
- **Deliverables**:
  1. [`tools/build_gemma_vocab_bin.py`](file:///C:/Users/rich-/source/repos/CARTAN/tools/build_gemma_vocab_bin.py): Reusable build tool compiling [`cache_google_gemma-4-E4B-it_tokenizer.json`](file:///C:/Users/rich-/source/repos/CARTAN/cache_google_gemma-4-E4B-it_tokenizer.json) into a compact, contiguous first-child/next-sibling binary Trie arena ([`test/geomind/trainingdata/gemma_vocab_65k.bin`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/gemma_vocab_65k.bin), 3.98 MB).
  2. [`src/std/tokenizer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/tokenizer.cl): Pure CARTAN $O(L)$ longest-prefix BPE subword encoder (`bpe_encode`) and $O(1)$ zero-copy string decoder (`bpe_decode_token`).
  3. [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl): Purge artificial byte mask (`cartan_apply_english_vocab_mask`), recalibrate Reflective Doubt entropy threshold ($7.2 \to 10.5$), and render decoded subword tokens cleanly.
  4. Regression suite execution and zero-mock verification.

---

## 2. Logical Dependency Tree

```
cache_google_gemma-4-E4B-it_tokenizer.json (262,144 tokens)
       │
       ▼ (tools/build_gemma_vocab_bin.py)
test/geomind/trainingdata/gemma_vocab_65k.bin (Compact Trie Arena: 200,345 nodes, 65,536 string offsets)
       │
       ▼
src/std/tokenizer.cl (cartan_hub_init_bpe_trie_if_needed, bpe_encode, bpe_decode_token)
       │
       ├────────────────────────────────────────┐
       ▼                                        ▼
test/geomind/chat.cl                    test/geomind/train.cl
- Decodes real subwords                 - Ingests true subwords
- Purges byte mask (267..361)           - Causal sequence training
- Recalibrates Reflective Doubt
       │
       ▼
build/geomind.exe & bin/geomind.exe (Verified via cartanc.exe)
```

---

## 3. Step-by-Step Task List

- [x] **Task 1: Create Vocab Binary Compiler Helper**
  - Save `tools/build_gemma_vocab_bin.py`.
  - Generate `test/geomind/trainingdata/gemma_vocab_65k.bin`.

- [ ] **Task 2: Implement Pure CARTAN BPE Trie & String Decoder ([`src/std/tokenizer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/tokenizer.cl))**
  - Implement `cartan_hub_init_bpe_trie_if_needed()` loading `gemma_vocab_65k.bin`.
  - Implement binary buffer unpackers (`cartan_bin_read_i32`, `cartan_bin_read_u32`).
  - Implement $O(1)$ `bpe_decode_token(tok_id: float) -> string`.
  - Implement $O(L)$ `bpe_encode(text: string) -> ptr` with longest-prefix trie matching and Gemma byte fallback ($238 + b$).

- [ ] **Task 3: Purge Synthetic Masks & Recalibrate Doubt ([`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl))**
  - Remove calls to `cartan_apply_english_vocab_mask`.
  - Recalibrate Reflective Doubt entropy threshold from $7.2$ to $10.5$.
  - Verify `c_cartan_print_token` renders real subwords cleanly.

- [ ] **Task 4: Compilation & Verification**
  - Compile `bin/geomind.exe` and `cartanc.exe`.
  - Verify all 62 compiler regression test targets in `test/compiler_suite/run_tests.car`.
  - Verify `geomind.exe --chat "What is an algorithm?"` emits recognizable subwords.

- [ ] **Task 5: Documentation & Changelog**
  - Record Sprint 331 Walkthrough in `docs/archive/`.
  - Update `CHANGELOG.md` and `ISSUES.md`.
