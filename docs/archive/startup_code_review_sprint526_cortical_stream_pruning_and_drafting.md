# Startup Code Review: Sprint 526 — Activating Cortical Streams via Dynamic Vocabulary Pruning & Speculative Fast Drafting

**Date**: 2026-10-03  
**Reviewer**: Supervisor Agent & Squad Leads (Compiler, Runtime, QA, Architecture)  
**Target Repository**: `SK-Infidel/CARTAN`  
**Focus Files**: `test/geomind/chat.cl`, `test/geomind/streams.cl`, `test/geomind/moe.cl`, `src/std/transformer.cl`, `src/std/resonator.cl`

---

## 1. Executive Summary & Big Picture Context

In Sprint 525, language coherence was restored by removing uncalibrated in-place vector modifications from the 42-layer transformer latent state $\mathbf{h}$. However, an architectural audit by Rick revealed that the 8 Cortical Streams and Sasaki Brainstem Router are currently **dormant** during conversational decode:
1. `test/geomind/chat.cl:2564-2582` evaluates the Sasaki Router on $(h_{24}, \dot{h}_{24})$, but only updates telemetry counters (`g_telemetry_stream_0..7`).
2. `geomind_single_stream_forward` is never invoked in the active generation loop.
3. The LM head projection evaluates 167,243 Latin/Universal tokens on every token step ($\sim 38\text{ ms}$), creating the primary decode latency bottleneck.
4. Speculative drafting previously suffered from false-positive "ghost passes" because candidate tokens were drafted *before* the current token was computed, causing 0% acceptance and duplicate 42-layer evaluations.

Sprint 526 activates the 8 Cortical Streams in two mathematically non-destructive roles:
- **Role A: Stream-Driven Speculative Fast Drafting ($2\times - 4\times$ speedup)**: Anchor token $tok_0$ is always verified; the active cortical stream drafts $K=3$ speculative tokens ($c_1, c_2, c_3$) in $< 0.1\text{ ms}$; all are verified in a single batched 42-layer pass, guaranteeing $\ge 1\times$ progress with zero ghost passes.
- **Role B: Stream-Gated Dynamic Vocabulary Pruning ($8\times$ LM head speedup)**: Dominant stream prunes the active vocabulary mask from 167k down to $\sim 2,500$ tokens (core syntax + stream domain tokens), dropping LM head latency from $\sim 38\text{ ms} \to \sim 4\text{ ms}$.

---

## 2. Logical Dependency Tree

```mermaid
graph TD
    A["test/geomind/main.car"] --> B["test/geomind/chat.cl"]
    B --> C["src/std/transformer.cl"]
    B --> D["test/geomind/streams.cl"]
    B --> E["test/geomind/moe.cl"]
    B --> F["src/std/resonator.cl"]
    B --> G["src/std/hub.cl"]
    B --> H["test/geomind/semantics.cl"]
    B --> I["test/geomind/doubt.cl"]
    
    subgraph "Role B: Dynamic Vocabulary Pruning"
        D -->|Stream Domain Affinity| M["Stream Pruned Vocab Masks (0..7)"]
        E -->|dom_stream, dom_w| M
        M -->|mask_ptr (~2.5k tokens)| C
        C -->|Op 6.0 SIMD GEMV| L["LM Head Logits (38ms -> 4ms)"]
    end

    subgraph "Role A: Speculative Fast Drafting"
        L -->|tok_0 Sampled| S["Drafter: Active Stream (SSM/Poincare)"]
        S -->|Draft c_1, c_2, c_3 in <0.1ms| V["Batched 42-Layer Pass (tok_0, c_1, c_2, c_3)"]
        V -->|Verify cand_h against LM Head| K["KV Cache Commit & Rollback (cartan_kv_cache_clear_range)"]
    end
```

---

## 3. Findings & Code Inspection

### 3.1 Dormant Cortical Streams (`test/geomind/chat.cl:2564-2582`)
- **Inspection**: The Sasaki Brainstem Router determines `dom_stream` and `dom_w` at layer 24 on tangent coordinates $(h_{24}, \dot{h}_{24})$. However, this information is only stored in telemetry counters and a mild logit bias on 5 punctuation tokens.
- **Remedy**:
  - Feed `dom_stream` and `dom_w` into `geomind_get_stream_pruned_vocab_mask(script, dom_stream, dom_w)`.
  - Feed `cur_h` and `dom_stream` into `geomind_stream_draft_candidate_tokens`.

### 3.2 167k-Token Mask Evaluation in LM Head (`test/geomind/chat.cl:383-400`, `src/std/transformer.cl:4050-4068`)
- **Inspection**: `geomind_get_language_mask_for_script(1.0)` enables all Latin tokens (158,980) + universal tokens (8,263) = 167,243 tokens. Each active token requires a 2560D AVX2 SIMD dot product.
- **Remedy**:
  - Create 8 stream-specialized domain masks.
  - Each mask activates $\sim 1,000$ core syntactic tokens (punctuation, conjunctions, pronouns, auxiliary verbs) plus $\sim 1,500$ stream-specific domain tokens.
  - Active tokens per evaluation drop from 167k $\to \sim 2,500$ (98.5% reduction in dot products), dropping LM head latency from $38\text{ ms} \to 4\text{ ms}$.

### 3.3 Speculative Drafting Ghost Pass Elimination
- **Inspection**: Sprint 525 drafted candidates *before* computing the current token. When candidate 0 failed verification, 0 tokens were accepted, incurring a second 42-layer pass.
- **Remedy**:
  - Sample $tok_0$ first from $h_t$. $tok_0$ is unconditionally valid and accepted.
  - Drafter predicts $[c_1, c_2, c_3]$ following $tok_0$.
  - Batched forward runs $[tok_0, c_1, c_2, c_3]$ in a single pass.
  - Even if all speculative drafts fail, $tok_0$ was completed and committed. Net progress is $\ge 1$ token per pass with **zero ghost passes**.

---

## 4. Verification & DoD Targets
1. `bin/geomind.exe` prompt benchmark: verify LM head latency drops to $\le 6\text{ ms}$ with dynamic pruning.
2. Speculative drafting acceptance rate $\ge 40\%$ on conversational prompts with zero semantic degradation.
3. 16/16 compiler regression suite passes via `tools/run_affected_tests.ps1`.
4. `CHANGELOG.md` updated to `[8.482.0]`.
