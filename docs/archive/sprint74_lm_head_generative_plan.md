# Sprint 74 Implementation Plan: LM-Head Matrix Projection & True Generative Neural Synthesis Engine

## 1. Objectives
- **Replace Verbatim Offset Retrieval**: Eliminate `tok_id = base_offset + step` contiguous text slice lookup in `test/geomind/chat.car`.
- **LM-Head Matrix Projection ($W_{\text{head}} \cdot h$)**: Project the 32-layer E8 Attention + MoE hidden state ($h \in \mathbb{R}^{32}$) into vocabulary logit scores ($L \in \mathbb{R}^{V}$) using parameter dot products.
- **Autoregressive Logit Sampling**: For each token step, sample token IDs dynamically via `tokenizer_sample_topk(logits, 50.0, temp)` over temperature-scaled logit distributions.

---

## 2. Dependency Tree
- `test/geomind/e8_attention_engine.car` (E8 metric projection $h$)
  └── `test/geomind/moe.car` (MoE expert feed-forward state)
      └── `test/geomind/chat.car` (`geomind_chat_generate_reply`)
          ├── LM-Head projection loop ($L_i = \text{dot}(h, W_{\text{head}, i}) / T$)
          └── Autoregressive sampling (`tokenizer_sample_topk`)

---

## 3. Step-by-Step Implementation Steps
1. **`test/geomind/chat.car`**:
   - Compute 32-layer hidden vector $h$ from SLERP merged weights, E8 attention, and MoE experts.
   - Implement LM-Head dot product projection loop: for each token $i$, compute dot product $L_i = \text{dot}(h, \text{vocab\_row}_i) + \text{jitter}(T)$.
   - Pass $L$ into `tokenizer_sample_topk` to pick each token autoregressively.
   - Autoregressively update hidden state $h$ for step $t+1$.
2. **Rebuild & Synchronize**:
   - Rebuild `geomind.exe` via `cartanc.exe`.
   - Copy `geomind.exe` to root and `bin/` directories.
3. **Verification**:
   - Test `geomind.exe --chat` and `geomind.exe --rlaif` to confirm true generative token sampling across different prompts without contiguous text copying.
4. **Documentation**:
   - Update `CHANGELOG.md` and `docs/ROADMAP.md`.
