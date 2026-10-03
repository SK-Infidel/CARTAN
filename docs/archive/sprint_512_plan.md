# Sprint 512 Plan: Thread Pool Idle Standby & Silent REPL Operation

**Target Issue**: `[ISSUE-366]` Continuous Thread Pool Spin-Wait Idle Load (~40% CPU) & Thermal Fan Ramping  
**Date**: 2026-10-02  
**Supervisor**: Antigravity  

---

## Sprint Objectives
1. **Zero Idle Load**: Transition 7 persistent background worker threads from continuous spin-wait to non-busy sleep states (`Sleep(10.0)`) during prompt wait periods (`cartan_read_line()`), reducing idle REPL CPU consumption from ~40% to ~0.0%.
2. **Preserve Ultra-Low Latency**: Maintain high-throughput microsecond spin-waiting strictly during active prefill and autoregressive token decode passes, ensuring zero degradation in tokens/second.
3. **Dual Standby Architecture**:
   - Explicit Standby API: `cartan_trans_pool_enter_standby()` and `cartan_trans_pool_resume_active()`.
   - Adaptive Backoff: If idle for >500,000 spins (~2 ms) without explicit standby, automatically throttle to `Sleep(2.0)`.
   - Clean Teardown: `cartan_trans_pool_shutdown()` with `WaitForSingleObject` and `CloseHandle`.
4. **Targeted Verification**:
   - Recompile `cartanc.exe` and `geomind.exe`.
   - Validate 0% CPU utilization and quiet acoustic behavior at the REPL prompt.
   - Run affected test suite targets (`test_manifold_full_model_execution.car`, etc.).

---

## User Stories
- **Story 1 (Acoustics & Power)**: As a developer running `geomind.exe` in interactive chat, I want the computer CPU and cooling fans to remain silent and cool while I read or type prompts, so the laptop battery is preserved and fan noise is eliminated.
- **Story 2 (Latency & Throughput)**: As an AI system generating responses, I want worker threads to execute with maximum parallel responsiveness during active token decode passes without OS scheduling jitter.
- **Story 3 (Clean Lifecycle)**: As an engineer exiting `geomind.exe`, I want background threads to join and terminate cleanly without hanging or leaving orphan threads.
