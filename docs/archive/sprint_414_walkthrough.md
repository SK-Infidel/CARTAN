# Sprint 414 Walkthrough: Dynamic Adaptive Domain Focus & Lag Catch-Up Scheduler

**Sprint**: Sprint 414  
**Release**: `[8.372.0]`  
**Status**: Completed & Verified Cleanly  

---

## 1. Overview & Architecture

When multi-domain training encounters a dataset whose validation loss is substantially worse than the other domains (e.g. `storytelling_corpus_clean.txt` resetting to baseline after sleep consolidation), standard round-robin rotation divides compute equally, allowing the lagging dataset to drag down the fleet moving average loss.

Sprint 414 implemented **Dynamic Adaptive Domain Focus & Lag Catch-Up Scheduling** in [`test/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/train.cl):

1. **Continuous Lag Detection**:
   $$\Delta_d = VL_d - \frac{1}{N - 1} \sum_{k \ne d, VL_k > 0} VL_k$$
   - If $\Delta_d > 0.85$, the engine flags domain $d$ as lagging and engages **Focused Training Mode**.
   - Emits an explicit console notification indicating the lagging domain and gap delta.

2. **Focused Training Bursts**:
   - Instead of advancing to the next dataset after 1 chunk, the engine stays locked on the lagging dataset.
   - Retains continuous recurrent hidden state `g_buf_domain_h[d]` across consecutive chunks to accelerate gradient convergence.

3. **Anti-Forgetting Rehearsal Guard**:
   - Every 4 focused chunks (`focus_streak >= 4.0`), the scheduler temporarily triggers a 1-pass round-robin sweep across the remaining $N-1$ fleet domains.
   - Preserves cortical representation across the other datasets and eliminates catastrophic forgetting.
   - Automatically re-locks onto the lagging domain once the rehearsal sweep finishes.

4. **Automatic Parity Disengagement**:
   - Once $\Delta_d \le 0.35$, the scheduler logs parity restoration, disengages focus mode, and seamlessly resumes balanced round-robin training.

---

## 2. Empirical Verification

- **Compilation**: Compiled [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car) via `cartanc.exe` with Zig `-O3 LTO Vectorized Pass Pipeline`.
- **System Integrity**: Verified `geomind.exe --verify` with all physics, Hopfield, and online SFT solvers passing.
- **Regressions**: Verified 100% pass across all 7 NSES test suites (`test_sprint1` through `test_sprint7`) with Exit Code 0.
