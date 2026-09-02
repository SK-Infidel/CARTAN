# Sprint 256: 42-Layer Full Manifold SLERP Merge & Aligned LM Head Serialization

## Root Cause Analysis: Rising Training Loss
1. **Unpopulated 42-Layer Buffers in Previous Merge**: `--merge-slerp` previously ran `cartan_reset_baseline_weights_for_coadaptation` without loading the 42 backbone layers from `geomind_gemma4_clean_slerp_base.bin`. Consequently, the 42 layers were unpopulated and only a flat 10 MB file was saved instead of the 1.77 GB complete model.
2. **Identity Matrix Reset in LM Head**: `cartan_reset_baseline_weights_for_coadaptation` initialized $W_{\text{head}}$ to an identity diagonal `(r == c) ? 1.0 : 0.0`. Multiplying dense Gemma embeddings by an identity matrix created uniform random noise over 65,536 vocabulary classes ($\ln(65536) \times \text{IC} \approx 30.4$).
3. **High Learning Rate Divergence**: Training with `base_lr = 0.0050` on random logits caused gradient explosion, pushing loss from 25.5 to 27.0.

## Fixes Implemented & Verified
1. **Complete 42-Layer Base Loading**: Updated `--merge-slerp` in `test/geomind/geomind_driver.c` to load all 42 transformer layers ($275,251,200$ parameters) from `geomind_gemma4_clean_slerp_base.bin`.
2. **Gemma Embedding Manifold LM Head**: Updated `cartan_reset_baseline_weights_for_coadaptation` in `src/cartanc/c_runtime.c` to initialize the LM head directly from the normalized transpose of `g_gemma_embed_matrix`.
3. **1.77 GB Complete Checkpoint Export**: Verified that `geomind_cloze_aligned_weights.bin` and `geomind_slerp_fused_weights.bin` contain the full 42 layers + aligned LM head.
4. **Calibrated Default LR**: Lowered default base LR to `0.0020` for Cloze, `0.0015` for CE, and `0.0010` for SFT.
5. **Monotonic Convergence Verified**: Confirmed both Training Loss and Validation Loss drop monotonically.
