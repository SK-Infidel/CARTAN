# Sprint 529 Plan: Windowed Repetition Penalty, Ghost Slot Masking & StreamingLLM Attention Sinks

## Mission & Sprint Goals
Address the 3 generative root causes identified by Rick in `[ISSUE-387]`:
1. **Windowed Repetition Penalty**: Confine `cartan_apply_repetition_penalty` strictly to the last 64 generated tokens in `history` (instead of the entire 500+ token conversation), ending cumulative logit suppression on essential English connectives (`" the"`, `" is"`, `" of"`, `" to"`, `"."`, `","`).
2. **Ghost Slot Invariant & Large-Negative Masking**: Update `cartan_kv_cache_clear_range` in `src/std/transformer.cl` to fill $K$ slots with $-10000.0$ ($Q \cdot K \ll -10000 \implies \exp(-\text{huge}) = 0.0$), eliminating Softmax dilution from zeroed ghost slots.
3. **StreamingLLM Attention Sinks & Local Sliding Window Attention**: Implement Attention Sinks ($t \in [0, \text{SINK\_TOKENS}-1]$, default 4 tokens) + Local Sliding Window ($t \in [\text{win\_start}, \text{max\_seq}-1]$, default 256 tokens) in `cartan_manifold_layer_forward_native` and batch forward passes, capping causal attention compute at a fixed $O(1)$ constant ($\le 260$ tokens) indefinitely.

---

## User Stories
1. **As a User (Rick)**, I want multi-turn chat sessions to sustain $\ge 7\text{ tok/s}$ decode throughput indefinitely regardless of turn count, so that dialogue never slows down.
2. **As a User (Rick)**, I want natural English grammar, connectives, and punctuation preserved across extended dialogue without synthetic distortion or foreign grammar emulation.
3. **As a Compiler/Language Engineer**, I want mathematical certainty that uncommitted or rejected speculative draft slots never dilute attention Softmax distributions.

---

## Technical Architecture & Dependency Tree

```
                       [test/geomind/main.car]
                                  │
                                  ▼
                        [test/geomind/chat.cl]
                                  │
      ┌───────────────────────────┼───────────────────────────┐
      │                           │                           │
      ▼                           ▼                           ▼
[Windowed Rep Penalty]   [Ghost Slot Masking]       [StreamingLLM Sinks]
(Last 64 tokens only;   (K filled with -10000.0;    (Sink 0..3 + Window 256;
 protects connectives)   zero softmax contribution)  O(1) attention compute)
                                  │                           │
                                  ▼                           ▼
                     [src/std/transformer.cl]   [src/std/transformer.cl]
                     (cartan_kv_cache_clear)    (manifold_forward_native)
```

---

## Definition of Done (DoD)
- [ ] `cartan_apply_repetition_penalty` bounded to last 64 tokens across sliding window, consecutive repeats, 2-grams, and frequency decay.
- [ ] `cartan_kv_cache_clear_range` masks $K$ with $-10000.0$ so unaccepted slots receive $0.0$ Softmax attention weight.
- [ ] StreamingLLM Attention Sinks (4 tokens) + Local Sliding Window (256 tokens) implemented in `cartan_manifold_layer_forward_native` and batch forward paths.
- [ ] `bin/geomind.exe` compiled cleanly with `cartanc.exe`.
- [ ] Multi-turn prompt verification proves sustained decode speed and clean, fluent English grammar.
- [ ] `tools/run_affected_tests.ps1 -Sprint 529` passes 16/16 compiler regression targets.
- [ ] `[ISSUE-387]` closed in `ISSUES.md`, `CHANGELOG.md` updated to `[8.485.0]`, `docs/ROADMAP.md` updated, and artifacts archived.
