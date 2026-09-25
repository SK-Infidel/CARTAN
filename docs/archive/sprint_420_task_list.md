# Sprint 420 Task List: Asynchronous Double-Buffered BPE Chunk Slicing

- [ ] **Task 1: OpenCL Kernel Split in `test/geomind/train.cl`**
  - Implement [`geomind_train_chunk_gpu_launch_pass(tokens: ptr, lr: float) -> float`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl)
  - Implement [`geomind_train_chunk_gpu_finish_pass(lr: float, n_tokens: float) -> float`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl)
  - Keep [`geomind_train_chunk_gpu_pipelined`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl) as an atomic pass-through wrapper

- [ ] **Task 2: Slicing & BPE Tokenizer Modularization**
  - Implement [`geomind_slice_and_tokenize_chunk(file_content: ptr, content_len: float, start_offset: float, out_tokens: ptr) -> float`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl) with clean newline alignment, empty line handling, SentencePiece BPE encoding, and wrap-around protection

- [ ] **Task 3: Streaming Double-Buffer Pipeline in `geomind_train_streaming_steady_state`**
  - Allocate `active_tokens` and `standby_tokens`
  - Prime `active_tokens` with chunk 0 prior to epoch loop
  - Dispatch validation pass, update focus scheduler, launch asynchronous training pass on GPU
  - Overlap CPU tokenization into `standby_tokens` for `next_d_idx`
  - Finish GPU training pass, collect metrics, update offsets, and zero-copy swap `active_tokens` $\leftrightarrow$ `standby_tokens`

- [ ] **Task 4: Build & Empirical Verification**
  - Compile with `./cartanc.exe build test/geomind/main.car -o geomind.exe`
  - Run regression test `test_sprint7_loss_shaping.car`
  - Run `geomind.exe --verify`
  - Run empirical streaming training with `geomind.exe --train-ce` to verify throughput improvement and zero idle bubbles

- [ ] **Task 5: Documentation & Agile Roll-Forward**
  - Update [`CHANGELOG.md`](file:///C:/Users/rich-/source/repos/CARTAN/CHANGELOG.md) (`[8.378.0]`)
  - Update [`ISSUES.md`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md) (`[ISSUE-162]`)
  - Write walkthrough artifact and archive to `docs/archive/sprint_420_walkthrough.md`
