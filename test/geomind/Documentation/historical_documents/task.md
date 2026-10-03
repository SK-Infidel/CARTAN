# Vision Alignment Execution Tasks

- `[x]` Analyze code discrepancies between `E8MultiDecompEngine` (MoE) and Legacy Block architecture.
- `[x]` Update `config.py` to `NUM_DECOMP_STREAMS = 7` and remove `BLOCK_TYPES`.
- `[x]` Update `Documentation/vision.md` with:
  - 7 maximal subgroups (streams).
  - Geometric neural networks design.
  - Tokenization / BCEN continuous coordinates.
  - Input matrices.
  - 4x4 MoE and the Brainstem.
  - Inverse Randers backward pass.
  - Assimilation / SVD Procrustes projection.
  - Definition of what a "weight" is (Lattice coordinate).
- `[x]` Update `Documentation/architecture.md` to formally deprecate legacy blocks and document the 7 streams and `E8MagicSquareMoE` architecture.
- `[x]` Update `user_guide.md` script paths for init configuration.
- `[x]` Create `walkthrough.md` to summarize the changes.
