# Sprint 84 Implementation Plan: Google Gemma Checkpoint & Google SentencePiece Integration

## 1. Executive Summary & Core Directive
- **User Directive**: Remove old GeoMind model checkpoints and rebuild from scratch using Google's official SentencePiece BPE tokenizer and Google Gemma checkpoint (`google/gemma-2b` / `google/gemma-2-2b-it`).
- **Core Changes**:
  1. Purge legacy `cache_model.safetensors` and `cache_tokenizer.json` files.
  2. Configure `src/std/hub.car` and `test/geomind/chat.car` to fetch Google Gemma pretrained weights (`google/gemma-2b-it`) and Google SentencePiece tokenizer JSON (`google/gemma-2b-it`, `tokenizer.json`).
  3. Update `src/cartanc/c_runtime.c` to parse official Google SentencePiece `tokenizer.json` key-value mappings (`"model":{"vocab": ...}`) directly into native runtime memory (`g_vocab_table[256000]`).
  4. Rebuild `geomind.exe` natively with `cartanc.exe`.

---

## 2. Step-by-Step Implementation
1. **Purge Legacy Checkpoints**:
   - Delete `cache_model.safetensors` and `cache_tokenizer.json`.
2. **`src/cartanc/c_runtime.c`**:
   - Upgrade `cartan_hub_ensure_tokenizer_json` to parse official Google SentencePiece `tokenizer.json` JSON token-to-id maps cleanly into `g_vocab_table`.
3. **`test/geomind/chat.car` & `src/std/hub.car`**:
   - Set pretrained model target to `google/gemma-2b-it`.
   - Wire Gemma 256,000 vocabulary size and $E_8$ Riemannian projection layers.
4. **Rebuild & Synchronize**:
   - Rebuild `geomind.exe` using `cartanc.exe` and sync to root and `bin/`.
5. **Verification**:
   - Verify native execution (`geomind.exe --chat "Explain physics"`).
6. **Documentation**:
   - Log Sprint 84 in `CHANGELOG.md` and update `docs/ROADMAP.md`.
