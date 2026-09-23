# Sprint 377 Plan: Validation Isolation, Weight Decay Regularization, & Post-Attention Spherical Normalization

## Objective
Remediate the severe validation divergence and overconfidence delusion ($VL \approx 5.80$, $VPPL \approx 352$, $VCERT \approx 22.6\%$) observed during continuous multi-dataset pretraining. Restore the clean baseline checkpoint, reset manifest tracking to Epoch 1.0, and re-establish tight mathematical parity between training and validation streams.

## Root Cause Hypotheses & Targets
1. **Validation Inter-Chunk Bleed**: `geomind_train_chunk_gpu_pipelined` was saving the final hidden state of holdout chunks to `g_buf_prev_chunk_h`, causing independent validation paragraphs to bleed across each other and polluting the initial state of the next training chunk.
2. **Zero Weight Decay Softmax Sharpening**: SGD `decay_factor` was hardcoded to `1.0`, allowing LM head weight norms to grow unbounded and artificially sharpening softmax probabilities into overconfident wrong guesses ($VSURP \approx 9.61\text{ bits}$).
3. **Un-Normalized Post-Attention/Hopfield Hidden Vectors**: Tier 1 Causal MHA and Tier 3 Hopfield memory injection modified $\mathbf{h}$ without re-normalizing onto the Riemannian sphere prior to forward GEMV projection, creating logit dilation.

## Proposed Changes
1. [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl):
   - Guard `g_buf_prev_chunk_h` persistence with `if (lr > 0.0)`.
   - Clear `g_has_prev_chunk_h = 0.0` and zero `g_buf_train_hidden` before every holdout chunk in `geomind_compute_validation_loss`.
   - Set `decay_factor = 0.99995` in both GPU and CPU SGD updates.
   - Insert `cartan_gpu_launch_local(g_pipe_rmsnorm)` directly after Tier 3 Hopfield injection before `g_pipe_gemv`.
2. Checkpoint & Manifest Restoration:
   - Restore [`geomind_steady_state_weights.bin.bak`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/checkpoints/geomind_steady_state_weights.bin.bak) over `geomind_steady_state_weights.bin`.
   - Reset [`corpus.json`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/trainingdata/corpus.json) to Dataset 0, offset 0.0, Epoch 1.0, LR 0.0022.
3. Verification:
   - Compile via `cartanc.exe`.
   - Verify 4/4 semantic vector analogies on `geomind.exe --eval-analogy`.
   - Verify empirical live training telemetry ($VL \approx TL$, $VPPL \approx TPPL$, $VENT \approx ENT$).
