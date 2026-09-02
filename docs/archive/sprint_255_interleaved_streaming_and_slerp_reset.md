# Sprint 255: Interleaved Multi-Corpus Streaming & Clean SLERP Reset

## Executive Summary
This sprint resolved multi-epoch loss oscillation and premature convergence plateaus in GeoMind training. Previously, validation holdout was extracted 100% from the first chapter of *Moby Dick*, and books were read sequentially in isolation. This caused the validation metric to oscillate as the model learned and shifted between different literary styles, while exponential LR decay froze step sizes. 

## Key Improvements
1. **Balanced Multi-Corpus Validation Holdout**:
   - Uniformly samples validation holdouts across all 13 corpus books (for CE) and all 6 JSONL chunk files (for Cloze).
   - Validation loss now accurately measures joint cross-corpus language ability without single-author bias.
2. **Interleaved Round-Robin Multi-File Streaming**:
   - Replaced single-file sequential reading with simultaneous multi-file streaming.
   - Each batch of 448 samples contains an interleaved mixture of sentences from all active books/chunks, completely eliminating recency bias and catastrophic forgetting.
3. **Calibrated LR Scheduler & Gamma**:
   - Dynamically tracks exact total samples per epoch and defaults to gentle decay (`gamma = 0.96`), preventing learning rates from collapsing to zero.
4. **Clean Baseline SLERP Initialization (`--merge-slerp`)**:
   - Reset and merged fresh 42-layer orthogonal Lie manifold baseline weights (`geomind_cloze_aligned_weights.bin`).
   - Cleared stale intermediate checkpoints so the pipeline starts completely fresh for Stage 1 Cloze training.
