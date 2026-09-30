# Sprint 490 Plan: Pure Neural Inference Fidelity, Attention Scaling & Manifold Echo Damping

## Goal
Resolve [`[ISSUE-292]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md) to achieve high-accuracy, robust pure neural inference (`--no-expert-priming`) in GeoMind by:
1. Restoring active vocabulary masking and scale normalization in the LM-head softcapping kernel.
2. Correcting the attention score scale factor ($1/\sqrt{d_k}$) in the native transformer decoder layer.
3. Implementing continuous manifold prompt echo attractor damping and dynamic frequency repetition decay in the generation loop.
4. Aligning benchmark evaluation token prefix matching in `tools/eval_pure_neural_benchmark.py`.
5. Ensuring 100% regression suite pass (87/87) and 3-stage bootstrap fixpoint parity.

---

## Technical Specifications & Architecture

### Gate 1: Dynamic Prompt Language Detection & Multilingual Vocabulary Masking
- Implement UTF-8 prompt script/language detection (`geomind_detect_prompt_script`) in `test/geomind/chat.cl` detecting Latin/European, Cyrillic, CJK, Arabic, Devanagari, or Multilingual.
- Dynamically resolve and apply the corresponding vocabulary mask in `cartan_tensor_compute_lm_head_logits` in ANY mode (whether `g_expert_priming_enabled` is 1.0 or 0.0), enabling natural responses in the user's prompt language while preventing out-of-script random unicode shards from bleeding in.
- Ensure Zipfian IC damping is cleanly evaluated so natural language semantics are preserved.

### Gate 2: Attention Scale Factor $1/\sqrt{d_k}$
- In `src/std/transformer.cl:1094`, scale attention inner products by $1/\sqrt{head\_dim}$ (for $head\_dim = 256$, factor is $0.0625$):
  ```cl
  let inv_sqrt_hd = 1.0 / sqrt(head_dim);
  ...
  dot = cartan_simd_dot_f32(q_h, k_ht, head_dim) * inv_sqrt_hd;
  ```
- This prevents attention score explosion and restores smooth softmax attention across prompt tokens.

### Gate 3: Prompt Echo Attractor Damping & Frequency Decay
- In `test/geomind/chat.cl:1344-1426`, apply prompt token residual damping:
  - Subtract a fractional projection of the prompt token embeddings from the candidate hidden state before LM-head projection:
    $h' = h - \alpha \sum_{p \in prompt} \langle h, e_p \rangle e_p$.
  - Implement token frequency repetition decay in `cartan_apply_repetition_penalty`.

### Gate 4: Benchmark Suite Harness Refinement
- In `tools/eval_pure_neural_benchmark.py`, ensure case-insensitive prefix and multi-token matching handles both first tokens and target completions.

### Gate 5: Verification & Fixpoint Convergence
- Compile `bin/cartanc_stage1.exe` -> `bin/cartanc_fresh.exe` -> `bin/cartanc_stage3.exe`.
- Verify bitwise fixpoint parity: `SHA256(fresh.ll) == SHA256(stage3.ll)`.
- Run full regression suite `tools/run_affected_tests.ps1 -All` (87/87 passing).
- Run benchmark suite on `build/geomind.exe` and verify substantial accuracy improvement.
- Update `CHANGELOG.md` to `[8.448.0]`, mark `[ISSUE-292]` as FIXED in `ISSUES.md`, and archive walkthrough.
