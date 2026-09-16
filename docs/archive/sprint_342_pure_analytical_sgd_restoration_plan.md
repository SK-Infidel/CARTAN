# Sprint 342: Pure Analytical SGD Restoration & Cross-Token Momentum Removal Plan

## 1. Problem Statement & Root Cause
- **User Observation**: "Seems like every time we adjust something something else goes to crap. Now loss isn't dropping hardly at all. I mean it has, but then it goes back up. Atl is staying right where it's at."
- **Mathematical Root Cause**:
  1. In Sprint 340, a persistent GPU velocity buffer (`g_buf_cortical_velocity`, 26.2 MB) was added to `geomind_sgd_backward`:
     `v = 0.90 * v + 0.10 * grad; W = W * decay - lr * v;`
  2. In online sequence modeling, target tokens change every step. For a vocabulary of 2,560 tokens:
     - On token step $t$, the target token gets a single negative gradient ($d \approx -0.99$).
     - On the other 2,559 non-target steps, that same token gets continuous positive gradients ($d \approx +0.0004$).
  3. The persistent EMA velocity acts as an asymmetric low-pass filter:
     - It cuts the target reinforcement signal by 90% ($(1 - \beta) = 0.10$).
     - It integrates background suppression noise across 500+ non-target steps.
     - Gradients from different, unrelated words are smeared together across sequence time.
  4. As a result, the weights were steadily flattened toward zero, driving output logits toward uniform random entropy:
     $-\ln(1 / 2560) = \ln(2560) \approx 7.848$.
     The telemetry observed by the user (`ATL: 7.71 - 7.72`, `TL: ~8.0`) corresponds precisely to maximum entropy in a 2,560-token vocabulary!

## 2. Solution Directives
1. Remove persistent cross-token EMA momentum buffer and restore pure analytical SGD in GPU VRAM (`geomind_sgd_backward`).
2. Retain per-token gradient clipping ($[-1.0, 1.0]$) to protect numerical stability without lag or cross-token smearing.
3. Free 26.2 MB VRAM by eliminating `g_buf_cortical_velocity` and `geomind_zero_velocity`.
4. Restore clean checkpoint `geomind_steady_state_weights.bin.bak` (saved before weights were flattened).
5. Verify on empirical test corpora that training loss drops continuously without bouncing back up.
6. Rebuild with pure self-hosting `cartanc.exe` and synchronize all 4 production binaries.
