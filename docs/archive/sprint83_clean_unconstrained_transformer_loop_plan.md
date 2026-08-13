# Sprint 83 Implementation Plan: Clean Unconstrained Transformer Token Generation Loop

## 1. Executive Summary & Core Objective
- **Objective**: Completely remove all hardcoded author offset windows (`base_offset`), case-sensitive string matching rules, and synthetic modulo shortcuts from `test/geomind/chat.car`.
- **Implementation**:
  - Implement standard, unconstrained neural token generation:
    1. Tokenize prompt into token IDs (`hub_autotokenizer`).
    2. Pass tokens through 32-layer E8 Riemannian attention + MoE + Continuous Hopfield relaxation.
    3. Compute authentic logits across 49,152 vocabulary tokens via 2D parameter inner products ($L = W_{\text{lm\_head}} \cdot h_{\text{relaxed}}$).
    4. Apply Softmax Top-$P$ nucleus sampling to generate natural, fluent, unconstrained English sentences.

---

## 2. Step-by-Step Implementation
1. **`test/geomind/chat.car`**:
   - Refactor `geomind_chat_generate_reply(prompt, max_tokens, temp)` to eliminate all author offset checks.
   - Implement unconstrained vocabulary logit calculation over $V = 49,152$.
   - Decode sampled token IDs through `cache_tokenizer.json` into clean English text.
2. **Rebuild & Synchronize**:
   - Rebuild `geomind.exe` using `cartanc.exe` and sync to root and `bin/`.
3. **Verification**:
   - Test `geomind.exe --chat "Hello! How are you doing today?"` and `geomind.exe --chat "Explain physics"`.
4. **Documentation**:
   - Log Sprint 83 in `CHANGELOG.md` and update `docs/ROADMAP.md`.
