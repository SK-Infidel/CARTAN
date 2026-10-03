# Sprint 512 Startup Code Review: Thread Pool Idle Standby & Acoustic Optimization

**Date**: 2026-10-02  
**Author**: Antigravity  
**Sprint**: 512  
**Focus**: Thread pool standby/sleep mechanism during interactive prompt wait, eliminating ~40% idle CPU spin and fan roar (`[ISSUE-366]`).

---

## 1. Executive Summary & Problem Diagnosis

During interactive REPL execution of [`geomind.exe`](file:///C:/Users/rich-/source/repos/CARTAN/bin/geomind.exe), system telemetry revealed a constant, invariant ~40% host CPU load and loud cooling fan noise even while sitting idle at the `User> ` prompt.

Inspection of the runtime architecture identifies the exact physical cause:
1. In [`src/std/transformer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl), initialization allocates and launches 7 persistent OS background worker threads via `CreateThread` in `cartan_trans_pool_worker_main` (lines 1238–1624).
2. Each worker thread runs a continuous while loop:
   ```cartan
   while (g_trans_pool_running == 1.0) {
       spin = 0.0;
       state = cartan_f32_at(param, 24.0);
       while (state != 1.0) {
           if (g_trans_pool_running == 0.0) { return 0.0; }
           spin = spin + 1.0;
           if (spin > 5000.0) {
               SwitchToThread();
               spin = 0.0;
           }
           state = cartan_f32_at(param, 24.0);
       }
   ```
3. Win32 `SwitchToThread()` yields execution *only* if another ready thread exists on the same logical CPU core. If no thread is ready (typical on modern multi-core machines during terminal wait), `SwitchToThread()` returns immediately.
4. Consequently, all 7 worker threads spin-wait continuously at 100% core load across 7 cores. On an 8-core / 16-thread CPU, 7 pegged cores equate to ~43.7% total system CPU utilization.
5. This continuous core load keeps CPU boost clocks high, burns dozens of Watts of package power, and ramps cooling fans to high RPM indefinitely while waiting for user input.

---

## 2. Logical Dependency Tree

```
test/geomind/main.car (REPL loop & CLI entry)
 └── test/geomind/chat.cl (Multimodal chat driver & biometric scanning)
      └── src/std/transformer.cl (Causal transformer neural manifold)
           ├── cartan_trans_pool_worker_main (7 persistent background worker threads)
           │    ├── Sleep(10.0) [Standby State: 0% CPU, fan silent]
           │    ├── Sleep(2.0)  [Adaptive Fallback: spin > 500,000 (~2ms idle)]
           │    └── SwitchToThread() [Active Decode / Prefill: ultra-fast spin-wait]
           ├── cartan_trans_pool_enter_standby() -> float
           ├── cartan_trans_pool_resume_active() -> float
           ├── cartan_trans_pool_is_standby() -> float
           └── cartan_trans_pool_shutdown() -> float
                └── WaitForSingleObject + CloseHandle (clean thread join & resource release)
```

### Dependency Boundaries & Blast Radius
- **Upstream callers**: `geomind_chat_interactive_loop` in [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car), `geomind_chat_startup_biometric_scan` in [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl).
- **Core implementation**: [`src/std/transformer.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/transformer.cl).
- **Downstream affected targets**:
  - `test_hybrid_resonant_transformer.car` (Target 58)
  - `test_manifold_full_model_execution.car` (Target 52)
  - `test_manifold_layer_alignment.car` (Target 50)
  - `test_manifold_layer_streaming_pipeline.car` (Target 51)
  - `test_model_config_decoupling.car` (Target 54)
  - `test/geomind/main.car` (`geomind.exe`)

---

## 3. Technical Solution Design

### Dual Standby Architecture: Explicit Mode + Adaptive Fallback

1. **Explicit Standby Hook**:
   - `cartan_trans_pool_enter_standby()` sets `g_trans_pool_standby = 1.0`.
   - `cartan_trans_pool_resume_active()` sets `g_trans_pool_standby = 0.0`.
   - In `geomind_chat_interactive_loop`:
     ```cartan
     cartan_trans_pool_enter_standby();
     printf("User> ");
     cartan_flush(0.0);
     let line = cartan_read_line();
     cartan_trans_pool_resume_active();
     ```
   - When entering standby, worker threads execute `Sleep(10.0)` in each idle loop iteration instead of spinning. At 10 ms slices, each thread wakes only ~100 times per second to inspect memory, consuming ~0.001% CPU. Total process CPU utilization drops to ~0.00%.

2. **Adaptive Fallback Protection**:
   - If GeoMind executes a non-interactive script, an unexpected long calculation, or an unhooked wait, an adaptive threshold `spin > 500000.0` (~2–5 ms of silence) automatically drops workers into `Sleep(2.0)`.
   - During active layer-by-layer token generation, dispatch intervals are ~10–50 microseconds, meaning `spin` never exceeds ~500. Active inference latency is unaffected.

3. **Clean Teardown**:
   - `cartan_trans_pool_shutdown()` sets `g_trans_pool_running = 0.0`, signals sleeping threads (which exit within 10 ms), joins handles with `WaitForSingleObject(h, 1000.0)`, and closes handles with `CloseHandle(h)`.

---

## 4. Verification Strategy

1. **Empirical CPU & Power Profile**:
   - Launch `geomind.exe`. Observe Windows Task Manager / Process Explorer at `User> ` prompt: CPU utilization must drop from ~40% to ~0.0%.
   - Fans must spin down to idle acoustic levels.
2. **Decode Latency Verification**:
   - Submit prompts and verify token decode speed remains identical (no regression in tok/s).
3. **Targeted Regression Suite**:
   - Run affected compiler suite targets (`test_manifold_full_model_execution.car`, etc.).
