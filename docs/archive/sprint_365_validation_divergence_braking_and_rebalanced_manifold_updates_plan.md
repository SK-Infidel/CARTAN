# Sprint 365 Plan: Validation Divergence Braking, Rebalanced Manifold Updates & Multi-Domain Holdout

## 1. Context & Objectives
During Stage 2 pre-training across heterogeneous datasets, Average Validation Loss (`AVL` = 4.44) and Average Training Loss (`ATL` = 4.07) diverged, driving validation perplexity (`VPPL`) up from 48 to 85.
Four root causes were identified in Sprint 364 retro:
1. **Input Embedding Scaling Mismatch**: OpenCL kernel `geomind_input_grad_update` scaled updates at `0.10f` (5× larger than manifold curvature `inv_sqrt_dim = 0.01976`), causing token representations to overfit aggressively to the local corpus slice.
2. **Disjoint Adaptive Feedback**: The adaptive controller only monitored training perplexity `TPPL = exp(tl)` and was blind to validation loss (`AVL`) and perplexity (`VPPL`).
3. **Starvation Jitter Deadlock**: The starvation threshold `lr <= lr_floor * 1.5` trapped the optimizer in an unending 100-step jitter loop (`0.0026` $\leftrightarrow$ `0.0033`).
4. **Single-Domain Validation Holdout**: `cloze_validation_holdout.txt` consists solely of narrative/dialogue text. When the training stream ingests academic abstracts (`arxiv_scientific_abstracts.txt`), validation loss artificially inflates due to domain shift.

## 2. Technical Architecture & Changes
1. **Rebalance Input Embedding Updates (`test/geomind/train.cl`)**:
   - Rebalance `geomind_input_grad_update` scaling from `0.10f` to `0.025f`, matching natural Riemannian manifold scaling `inv_sqrt_dim = 0.01976f`.
   - Add gradient clipping and L2 weight decay to input updates matching output projections.
2. **Close the Loop: Validation Divergence & Overfitting Braking (`test/geomind/train.cl`)**:
   - Track validation loss EMA trend `delta_vloss = ema_val_loss - prev_ema_val_loss`.
   - If $AVL > ATL \times 1.08$ (generalization gap $> 8\%$) or `delta_vloss > 0.015` over consecutive intervals, apply automatic braking (`lr = lr * 0.92`).
   - Remove the artificial `tl > 6.0` guard from emergency divergence braking so genuine spikes ($TL > ATL \times 1.25$) are braked immediately.
3. **De-jitter Starvation Probing (`test/geomind/train.cl`)**:
   - Narrow starvation upward probing from `lr <= lr_floor * 1.5` to `lr <= lr_floor * 1.05`, allowing `lr` to settle smoothly without ping-ponging.
   - Set `lr_floor = 0.0015` and initialize active `lr = 0.004` in manifest.
4. **Balanced Multi-Domain Validation Suite (`test/geomind/trainingdata/pretrain_validation_holdout.txt`, `test/geomind/train.cl`)**:
   - Assemble a genuine multi-domain validation holdout containing balanced samples from FineWeb-Edu, OpenWebText, WikiText-103, ArXiv abstracts, and TinyStories.
   - Point Stage 2 validation evaluation in `train.cl` to this multi-domain holdout, preserving `cloze_validation_holdout.txt` for Stage 1.
5. **Compilation, Verification & Synchronization**:
   - Compile `test/geomind/geomind.exe` with `cartanc.exe`.
   - Synchronize across `test/geomind/geomind.exe`, `bin/geomind.exe`, and `./geomind.exe`.
   - Empirically verify `--train-pre` launch, balanced validation loss, and closed-loop braking telemetry.
