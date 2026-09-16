# Sprint 348 Implementation Plan: Weight Decay Elimination, Token Bucketing, & Checkpoint Rescaling

## Objectives
1. Forensically determine why training loss remained stuck at ~4.643 across 54 epochs.
2. Eliminate mathematical traps preventing parameter descent.
3. Rescale checkpoint tensor to restore healthy parameter variance.
4. Support full vocabulary token embeddings via modulo bucketing.
5. Recompile with self-hosting `cartanc.exe` and synchronize 4 production binaries.
6. Verify active loss movement empirically and terminate processes for user execution.

## Root Causes Identified
- Per-token exponential decay `decay_factor = 1.0 - (lr * 0.0001)` ran 240,000 times/epoch, halving weights every epoch ($0.486^{54} \approx 10^{-17}$).
- Weights reached equilibrium at $\sigma_W \approx 0.00046$, collapsing logit variance to $\sigma_{\text{logits}} \approx 0.023$ and locking cross-entropy loss at $-\ln(1/104) \approx 4.643$.
- `geomind_input_grad_update` divided updates by `dim` ($2560$), causing float32 underflow.
- 39.6% of tokens had token ID $\ge 2560$, receiving zero embedding representations and zero gradient updates.

## Execution Steps
- [x] Rescale checkpoint weights $8\times$ (`tools/rescale_checkpoint.ps1`).
- [x] Set `decay_factor = 1.0` in GPU (`train.cl:604`) and CPU (`train.cl:553`).
- [x] Scale output SGD gradients by $4.0\times$.
- [x] Remove division by `dim` in `geomind_input_grad_update`.
- [x] Implement token modulo bucketing (`eff_tok = tok % vocab`) across GPU and CPU.
- [x] Reset manifest `current_lr = 0.035`.
- [x] Recompile via `cartanc.exe` and verify 4-way SHA-256 binary parity.
- [x] Perform smoke test and terminate cleanly for user interactive launch.
- [x] Update `ISSUES.md` (`[ISSUE-099]`), `CHANGELOG.md` (`[8.305.0]`), and archive documentation.
