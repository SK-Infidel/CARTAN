# Goal: Ethics, Logic, and Critical Thinking Alignment (Phase 4.5)

Before exposing GeoMind to the unregulated web (Phase 5), we must ensure its 248D semantic manifold is strictly anchored to human ethics, formal logic, and safe reasoning patterns. This prevents the model from assimilating malicious or logically flawed data during autonomous web scraping.

We will achieve this by implementing a **Constitutional RLAIF** pipeline combined with **Geometric Self-Reflection**.

> [!IMPORTANT]
> **User Review Required**
> Please review the proposed ethical constraints and the integration of the "Chain of Thought" logic. Do you agree with the Constitutional AI approach where an offline teacher model enforces the rules, or would you prefer to hardcode logic datasets for SFT?

## Open Questions
1. **The Constitution:** What specific ethical constraints do you want GeoMind to prioritize? (e.g., Asimov's Laws, strict harmlessness/helpfulness, academic neutrality, absolute mathematical truth?)
2. **Thinking Tokens:** Do you want GeoMind to output visible `<thought>` blocks (like OpenAI's o1) when performing critical thinking, or should the reasoning remain hidden entirely within the $E_8$ manifold?
3. **Teacher Model:** Which Ollama model do you plan to use as the Ethical Reward Model (e.g., `llama3`, `gemma`, `mistral`)?

---

## Proposed Changes

### 1. Constitutional RLAIF Evaluation
We will upgrade the existing Rejection Sampling in `rlaif_training.py` to evaluate responses against a strict set of ethical and logical rules.

#### [NEW] `utils/training/constitution.json`
A living document defining GeoMind's core alignment principles.
- **Principle 1 (Logic):** "The response must follow formal deductive reasoning and avoid logical fallacies."
- **Principle 2 (Ethics):** "The response must be harmless, safe, and decline requests that promote violence or unethical behavior."
- **Principle 3 (Epistemology):** "The response must express uncertainty when appropriate and strictly avoid hallucinating facts."

#### [MODIFY] `utils/training/rlaif_training.py`
- Refactor `evaluate_with_teacher()` to load `constitution.json`.
- The Ollama teacher will be prompted to explicitly act as a "Constitutional Judge", scoring Answer A and Answer B against the constitutional principles.
- The model will only SFT train on the answer that successfully passes the ethical and logical checks.

---

### 2. Geometric Self-Reflection (Chain of Thought)
We will activate GeoMind's latent self-awareness loop to force critical thinking.

#### [MODIFY] `core/e8_engine.py`
- fully implement the `USE_SELF_REFLECTION` flag.
- When the `surprise_state` (manifold drift) spikes, indicating confusion or a complex logical problem, the engine will automatically enter a recursive "thinking" state.
- It will project its intermediate states to the `SasakiRouter` before outputting final tokens, mathematically forcing a "step-by-step" logical deduction on the manifold.

---

### 3. Formal Logic & Ethics Semantic Trees
To complement the Math/Physics ontologies we just added, we need to explicitly build structural semantic trees mapping the absolute hierarchies of formal logic, ethics, and critical thinking so they can be inherently assigned $E_8$ geometric coordinates.

#### [NEW] `utils/initialization/build_logic_ethics_trees.py`
- A script to procedurally construct pure JSON semantic trees representing:
  - **Formal Logic:** Propositional logic, syllogisms, boolean algebra, logical fallacies.
  - **Ethics:** Moral philosophy frameworks, constitutional alignment boundaries, harmlessness protocols.
  - **Critical Thinking:** Epistemology, cognitive biases, scientific method structures.
- These trees will be ingested by `import_semantic_tree.py` just like WordNet and Math, locking these concepts eternally into the GeoMind coordinate registry.

### 4. Applied Logic SFT Injection
Once the semantic logic nodes exist in the $E_8$ geometry, the model must *practice* navigating them.

#### [NEW] `utils/dataset/build_logic_corpus.py`
- A script to procedurally generate a massive dataset of syllogisms, boolean logic puzzles, and moral dilemmas.
- We will run `sft_train.py` on this dataset to burn applied formal reasoning directly into the Cartan subnetworks of the $E_8$ lattice.

---

## Verification Plan

### Automated Tests
- Run `rlaif_training.py` with the new Constitutional prompt and verify that the Ollama teacher correctly rejects "jailbreak" or logically flawed answers.
- Inspect the geometric drift during inference to ensure `surprise_state` triggers the self-reflection loop correctly on hard problems.

### Manual Verification
- Ask the newly aligned GeoMind a complex moral dilemma.
- Ask GeoMind a multi-step logic puzzle (e.g., "If all flurps are blarps, and some blarps are gloops...").
- Verify that it outputs a structured, logically sound, and ethically aligned response.
