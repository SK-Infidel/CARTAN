# Sprint 527 Task List: CPU Thread-Pool Optimization & Cortical Stream Calibration

- [x] **1. Tooling: Orthonormal SVD Stream Adapter Generator (`tools/calibrate_stream_adapters.py`)**
  - [x] Ingest 262k authentic token embeddings and stream domain masks.
  - [x] Compute top $d_s$ singular vectors for each Lie subgroup ($d_0=120, d_1=136, d_2=86, d_3=80, d_4=66, d_5=60, d_6=48, d_7=24$).
  - [x] Serialize orthonormal $W_{\text{in}} \in \mathbb{R}^{d_s \times 2560}$ and $W_{\text{out}} \in \mathbb{R}^{2560 \times d_s}$ to `geomind_stream_adapters.bin`.
  - [x] Verify bit-accurate serialization and orthonormal properties ($W_{\text{in}} W_{\text{in}}^T = I_{d_s}$).

- [x] **2. Runtime: Stream Adapter Loader & Submanifold Execution (`test/geomind/streams.cl`)**
  - [x] Implement `geomind_load_stream_adapters_if_needed()`.
  - [x] Implement `cartan_simd_matvec_f32` or optimized GEMV for $W_{\text{in}}$ and $W_{\text{out}}$.
  - [x] Update `geomind_single_stream_forward` to project $2560 \to d_s \to 2560$.

- [x] **3. Runtime: CPU Thread-Pool Latency Optimization (`src/std/transformer.cl`)**
  - [x] Remove `Sleep(2.0)` from `cartan_trans_pool_worker_main` during active inference.
  - [x] Retain `Sleep(10.0)` strictly when `g_trans_pool_standby == 1.0`.
  - [x] Optimize barrier spin-wait in `cartan_trans_pool_dispatch` with tight pause loop.
  - [x] Add compiler volatile pointer semantics and atomic intrinsics to eliminate `0xc0000005` multithreaded race conditions.

- [x] **4. Build, Benchmarks & Regression Suite**
  - [x] Compile native `bin/geomind.exe` with `cartanc.exe`.
  - [x] Benchmark CPU decode tok/s on canary prompts (Homer, Kant, France).
  - [x] Benchmark speculative drafting acceptance with calibrated adapters.
  - [x] Add Sprint 527 mapping to `tools/run_affected_tests.ps1` and verify all 16 compiler targets PASS.

- [x] **5. Review, Documentation & Closure**
  - [x] Mark `[ISSUE-385]` as resolved in `ISSUES.md`.
  - [x] Update `CHANGELOG.md` to `[8.483.0]`.
  - [x] Update Phase 25 in `docs/ROADMAP.md`.
  - [x] Save walkthrough to `docs/archive/sprint_527_walkthrough.md`.

