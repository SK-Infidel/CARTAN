# Sprint 477 Implementation Plan: Objective Next-Token Manifold, Full English Lexicon, Productive NSES Knowledge Priming, and Interactive REPL Stability

## 1. Context & Motivation
Rick pointed out that the model should arrive at correct semantic tokens objectively without artificial, hardcoded boosts (`cur_mit + 2.5`) or manual token index suppressions. Furthermore, the active vocabulary mask had blindspots omitting critical English entities, factual prompts like `"The capital of france is,"` defaulted to generic function words, and the interactive chat REPL terminated prematurely after runaway high-entropy generations.

## 2. Sprint Goal
Eliminate all artificial token boosts and manual index suppressions across `test/geomind/chat.cl`, restore comprehensive English lexical coverage in vocabulary projection, productively wire NSES cognitive memory and CarGraph domain attractor retrieval into continuous latent state priming, stabilize the interactive chat REPL with conversational turn management and early termination, and verify empirical generation objectively on both biological and factual prompts.

---

## 3. Architecture & User Stories

### Story 1: Zero Artificial Boosts & Objective Lexical Selection
- Remove the `cur_mit + 2.5` override in `chat.cl`.
- Remove hardcoded token ID suppressions in `cartan_apply_repetition_penalty`.
- Replace hardcoded suppressions with authentic Zipfian function-word suppression based on pre-loaded Information Content (`g_e8_ics`) and dynamic top-p nucleus / top-k sampling.

### Story 2: Comprehensive English Lexical Coverage & Fast Projection
- Ensure all English tokens (including capitalized variants, named entities like `Paris`, `France`, and scientific terms) are present in the active vocabulary mask `geomind_vocab_mask.bin`.
- Ensure that valid vocabulary tokens are never masked out or omitted.

### Story 3: Productive NSES Cognitive Memory & CarGraph Attractor Priming
- When a prompt is received, NSES identifies the active domain and retrieves matching entity facts from SQLite `cognitive_memory.db` and rule embeddings from `nses_knowledge.car_graph`.
- Project the retrieved factual attractor embedding directly into the prompt hidden state $h$ (`0.75 * h + 0.25 * attractor_emb`) prior to transformer layer execution, grounding the neural latent trajectory in verified symbolic knowledge.

### Story 4: Interactive REPL Stabilization & Conversational Turns
- In `geomind_chat_interactive_loop`:
  - Set default conversational response limit to 24 tokens (instead of 256).
  - Stop generation immediately upon EOS token (`1.0`), newline (`\n`), or sentence terminators (`.`, `?`, `!`).
  - Eliminate vector memory leaks in the generation loop (`cur_h`, `layer_h`, `mom`).
  - Retain multi-turn conversational history across turns so the model maintains coherent context.

---

## 4. Definition of Done (DoD)
- [ ] Zero hardcoded token index overrides or manual suppressions in `test/geomind/chat.cl`.
- [ ] Full English vocabulary coverage restored without omitted entity tokens.
- [ ] NSES cognitive memory / CarGraph attractor actively primes prompt hidden state.
- [ ] Interactive REPL does not exit after one prompt, and generates clean, bounded responses.
- [ ] All 86 compiler test targets pass with 0 regressions via `build/run_tests.exe`.
- [ ] Empirical generation verified on `"In biology, cells divide through"` and `"The capital of france is,"`.
- [ ] `CHANGELOG.md` updated with version `[8.435.0]`.
- [ ] `ISSUES.md` updated with status of `[ISSUE-275]`, `[ISSUE-276]`, `[ISSUE-277]`, `[ISSUE-278]`.
