# Sprint 522 Task List
## Full 42-Layer GPU VRAM Resident INT4 Pipeline & Async Staging

- [x] **Gate 1: Double-Buffered Staging Architecture (`src/std/wgpu.cl`)**
  - [x] Implement ping-pong double-buffered staging buffers in `src/std/wgpu.cl`.
  - [x] Add asynchronous staging map callback and pipeline overlap.
  - [x] Verify zero CPU spin-wait stalling.

- [x] **Gate 2: INT4 WGSL Compute Kernels (`src/std/transformer.cl`)**
  - [x] Calculate exact byte/word offsets for INT4 layer weights and scales (sliding window & global).
  - [x] Write `geglu_int4_fwd` and `down_proj_int4_fwd` WGSL shaders with branchless `unpack4x8unorm` + `select`.
  - [x] Write global-attention variants `geglu_int4_fwd_global` and `down_proj_int4_fwd_global`.
  - [x] Initialize GPU pipelines and persistent bind groups in `cartan_transformer_init_gpu_resident_int4`.

- [x] **Gate 3: 42-Layer VRAM Mounting & Runtime Routing**
  - [x] Implement `cartan_transformer_upload_gpu_resident_layer_int4`.
  - [x] Wire GPU dispatch into `cartan_manifold_layer_forward_native` when `is_int8 == 2.0`.
  - [x] Update `geomind_mount_gpu_resident_layers` in `test/geomind/chat.cl` to mount all 42 INT4 layers into VRAM.

- [x] **Gate 4: Empirical Verification & Closeout**
  - [x] Benchmark decode latency in `scratch/bench_single_decode_step.car`.
  - [x] Rebuild `bin/geomind.exe` and test live prompt inference.
  - [x] Run regression suite via `tools/run_affected_tests.ps1`.
  - [x] Update `ISSUES.md` (mark `[ISSUE-372]` resolved), `docs/ROADMAP.md`, `CHANGELOG.md`, and author `docs/archive/sprint_522_walkthrough.md`.
