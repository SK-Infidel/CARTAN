# Sprint 445 Task List: Purging Legacy Deceptions, Silenced Lie Submanifolds & Euclidean Grids

- [x] **Task 1**: Purge rigged BPE token remapping from `src/std/tokenizer.cl`. Stripped `tokenizer_map_concept_slot` and fake decode table in `bpe_decode_token`.
- [x] **Task 2**: Implement dynamic submanifold strides in `test/geomind/geometry.cl` (`geomind_frs_stream_routing`, `geomind_frs_brainstem_distance`).
- [x] **Task 3**: Restore Riemannian geodesic parallel transport on $S^{247}$ in `test/geomind/chat.cl` (`cartan_tensor_update_autoregressive_state`), fix multimodal sector offsets (`cartan_multimodal_ground_hidden`), and eliminate synthetic dummy multimodal generation.
- [x] **Task 4**: Correct Sasaki phase-space routing across all dimensions in `test/geomind/moe.cl` (`geomind_sasaki_route`, `geomind_moe_forward_grid`).
- [x] **Task 5**: Align dynamic strides in `src/std/hybrid_resonator.cl` and `test/geomind/e8_attention_engine.cl`.
- [x] **Task 6**: Update default dimensions in `src/std/sleep.cl` and `src/std/resonator.cl` to 248.0.
- [x] **Task 7**: Align analogy stride in `test/geomind/main.car` and use genuine SentencePiece vocabulary token IDs.
- [x] **Task 8**: Harmonize `test/geomind/train.cl` OpenCL kernels (`geomind_streams_backward`, `geomind_autoregressive_step`, `geomind_input_grad_update`) with dynamic submanifold strides, eliminate synthetic phase noise (`sin(phase * 0.001)`), and eliminate out-of-vocab token discarding in `cartan_tensor_train_step`.
- [x] **Task 9**: Compile and empirically verify compiler test suite and `geomind.exe` CLI targets (`--eval-analogy`, `--sleep`, Target 52, Target 64).
- [x] **Task 10**: Update `CHANGELOG.md`, `ISSUES.md`, and `docs/ROADMAP.md`.

