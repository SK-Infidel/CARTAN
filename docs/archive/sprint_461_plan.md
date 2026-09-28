# Sprint 461 Plan: Language & Discourse Domain Synthesis for CARTAN NSES

## Sprint Objective
Resolve `[ISSUE-252]` by implementing Domain 6 (`LANGUAGE_DISCOURSE`) across the Neuro-Symbolic Expert System (NSES). Ingest foundational conversational pragmatics, speech act invariants, and semantic causality into `tools/cargraph_ingest.car`, expand `src/std/veto_gate.cl` with linguistic guardrails, update `src/std/burroughs.cl` with linguistic lateral fragments, enhance `src/std/nses_pipeline.cl` with language routing and expanded memory node resolution, recompile `.car_graph`, and verify with Target 71 in the regression suite.

---

## Technical Specifications

### Phase 1: Ingest Domain 6 (`LANGUAGE_DISCOURSE`) in `tools/cargraph_ingest.car`
1. Register Domain 6 with 7 total domains in `cargraph_ingest.car`:
   - `cargraph_builder_add_domain(builder, 6.0, 42.0, 10.0, 2.0); // LANGUAGE_DISCOURSE (2 strict, 8 factual)`
2. Add Domain 6 Rules:
   - **Rule 42 (Strict Invariant)**: "Speech act coherence: Query and question speech acts mandate an informative assertion or clarification response, not an arbitrary ungrounded directive."
   - **Rule 43 (Strict Invariant)**: "Anaphoric binding: Pronoun referents must maintain syntactic agreement in number, person, and entity category with their antecedent."
   - **Rule 44 (Factual)**: "Syntactic parsing and lexical recognition are mandatory prerequisites for semantic comprehension."
   - **Rule 45 (Factual)**: "Adjacent conversational dialogue turns must preserve topical coherence or transition via explicit discourse markers."
   - **Rule 46 (Factual)**: "Human dialogue consists of alternating conversational turns bounded by end-of-turn delimiter tokens."
   - **Rule 47 (Factual)**: "Lexical tokens ground continuous semantic concept embeddings into symbolic communication structures."
   - **Rule 48 (Factual)**: "High Information Content (IC) terms carry higher semantic discriminative weight than closed-class syntactic stopwords."
   - **Rule 49 (Factual)**: "Asserting a proposition commits the speaker to its direct logical consequences across subsequent turns."
   - **Rule 50 (Factual)**: "Conversational cooperative principle: Contributions should be informative, truthful, relevant, and perspicuous."
   - **Rule 51 (Factual)**: "Discourse transition bridges establish explicit causal, contrastive, or elaborative relationships between thoughts."
3. Add Domain 6 CSR Causal Edges:
   - Edge 44 -> 45 (Lexical parsing -> Topical coherence, weight 1.25)
   - Edge 45 -> 47 (Topical coherence -> Lexical grounding, weight 1.20)
   - Edge 42 -> 49 (Speech act coherence -> Logical commitment, weight 1.30)
   - Edge 47 -> 48 (Lexical grounding -> High IC discrimination, weight 1.15)
   - Edge 50 -> 51 (Cooperative principle -> Discourse transition bridges, weight 1.20)

### Phase 2: Linguistic Invariant Triggers in `src/std/veto_gate.cl`
1. In `veto_registry_populate_defaults`:
   - Add Rule 8 (Domain 6: `LANGUAGE_DISCOURSE`):
     - Contradiction triggers: "words have no meaning", "language cannot communicate", "questions do not require answers", "meaningless random text without syntax", "grammar has no rules", "statements contradict their premises".
     - Canonical assertion: "In accordance with communicative pragmatics, language conveys structured meaning through shared vocabulary, grammatical syntax, and coherent speech acts."

### Phase 3: Linguistic Burroughs Fragments in `src/std/burroughs.cl`
1. In `burroughs_pool_populate_defaults`:
   - Add Domain 6 lateral injection fragments across Entropy Tiers 1, 2, and 3:
     - Tier 1: "Language is a symbolic coordinate system mapped across collective memory."
     - Tier 2: "Words act as discrete quantization filters over continuous topological thought manifolds."
     - Tier 3: "Syntactic structures weave recursive self-referential mirrors of conscious intent."

### Phase 4: Stage 1 Routing & Memory Resolution in `src/std/nses_pipeline.cl`
1. In `nses_pipeline_execute_turn`:
   - **Stage 1 (Domain Routing)**: Match language/dialogue keywords:
     `"language"`, `"word"`, `"grammar"`, `"speech"`, `"talk"`, `"dialogue"`, `"conversation"`, `"syntax"`, `"meaning"`, `"communicate"`, `"question"`, `"answer"`. Route to `6.0` (`LANGUAGE_DISCOURSE`).
   - **Stage 3 (Seed Proximity)**: Push seed rule `42.0` (Speech act coherence) and `44.0` (Lexical recognition).
   - **Stage 4 (Memory Node Extraction)**: Add resolutions for nodes `42.0` through `51.0`.

### Phase 5: Recompilation, Target 71 Regression Test & Verification
1. Recompile `tools/cargraph_ingest.car` with `cartanc.exe`.
2. Execute `cargraph_ingest.exe` to emit updated `test/geomind/trainingdata/nses_knowledge.car_graph`.
3. Author `test/compiler_suite/test_nses_language_domain.car` (Target 71) verifying:
   - Loading updated `.car_graph` with 7 active domains.
   - Stage 1 routing to Domain 6.0 on language prompts.
   - CSR BFS traversal yielding Domain 6 memory nodes.
   - Veto gate firing on linguistic contradiction phrases.
4. Add Target 71 to `test/compiler_suite/run_tests.car`, recompile `run_tests.exe`, and execute all 71 regression targets.
5. Update `ISSUES.md`, `CHANGELOG.md` (`[8.419.0]`), and archive walkthrough.
