# Sprint 369 Plan: Zero-Day SLERP Model Fusion, WordNet IC Modulation, Real Vector Embedding Analogy & Cloze Training

## 1. Objectives & User Directives
1. **Checkpoint Purge**: Purge obsolete/unmodulated checkpoints (`geomind_steady_state_weights.bin`, `geomind_slerp_fused_weights.bin`, `checkpoint_status.txt`) and reset manifest offsets.
2. **Real SLERP Model Merge**: Execute genuine Killing-Cartan geodesic SLERP merge between base language model embeddings and donor projection layers from `cache_google_gemma-4-E4B-it_model.safetensors` (15.99 GB) with $\alpha = 0.15$.
3. **WordNet Information Content (IC) Modulation**:
   - Fix `src/std/semantics.cl` to parse genuine IC float values from `wordnet_taxonomy.txt`.
   - Modulate cortical columns ($0.80\times$ for stop-words/punctuation with $IC \le 0.60$, $1.20\times$ for WordNet concepts with $IC \ge 2.00$).
   - Map semantic concept slots (2500..2519) in active $2560 \times 2560$ vocabulary to key WordNet concepts (e.g., 2500='woman', 2501='King', 2502='queen', 2503='physics', 2504='star', etc.).
4. **Empirical Vector Analogy Verification**:
   - Implement `--eval-analogy` in `test/geomind/main.car` to compute $v(\text{King}) - v(\text{man}) + v(\text{woman}) \approx v(\text{queen})$, verifying Rank 1 accuracy and genuine vector arithmetic on the manifold.
5. **Cloze Curriculum Training Restoration**:
   - Wire `is_cloze_mode` into CLI dispatcher in `test/geomind/main.car`.
   - Reset `cloze_manifest.json` and start Cloze Stage 1 training from the new fused checkpoint.

## 2. Execution Task List
- [ ] Task 1: Write `tools/merge_slerp_weights.py` to extract genuine Gemma-4-E4B embeddings, map concept slots 2500..2519, perform geodesic SLERP with layer 0 projection weights, apply WordNet IC modulation, and save to `test/geomind/trainingdata/checkpoints/geomind_steady_state_weights.bin` and `geomind_slerp_fused_weights.bin`.
- [ ] Task 2: Purge existing corrupted/unmodulated checkpoint files and run `tools/merge_slerp_weights.py` to generate the new baseline checkpoints.
- [ ] Task 3: Fix IC parsing in `src/std/semantics.cl` line 151 (`atof(cartan_string_substring(line, 4.0, len))`).
- [ ] Task 4: Update `src/std/tokenizer.cl`:
  - Enhance `bpe_decode_token` to decode concept slots 2500..2519.
  - Enhance `cartan_hub_encode_text_to_tokens` to map matched WordNet concept tokens into 2500..2519.
  - Enhance `tokenizer_get_ic_weight` to amplify slots 2500..2519 ($2.50\times$).
- [ ] Task 5: Update `test/geomind/main.car`:
  - Add `--eval-analogy` command testing semantic analogies (`King - man + woman = queen`, `he - him + her = she`, `father - man + woman = mother`).
  - Wire `is_cloze_mode` into CLI argument loop.
- [ ] Task 6: Recompile `geomind.exe` with `cartanc.exe` and synchronize SHA-256 binaries across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `geomind.exe`.
- [ ] Task 7: Empirically verify `--eval-analogy` using `geomind.exe`.
- [ ] Task 8: Launch `geomind.exe --train-cloze` and monitor stable Cloze training metrics.
- [ ] Task 9: Update `ISSUES.md`, `CHANGELOG.md`, and archive Sprint 369 walkthrough.
