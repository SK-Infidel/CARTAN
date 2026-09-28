# Startup Code Review — Sprint 461
**Date**: September 27, 2026
**Investigator**: Supervisor Agent & CARTAN Squads
**Focus**: Expert System Language Rule Induction, Conversational Pragmatics, and NSES Engine Architecture

---

## 1. Executive Summary & Big Picture

Rick established the strategic priority: **Language first. The system must be able to talk.**
To achieve genuine language competence without mocks or hallucinations, CARTAN's Neuro-Symbolic Expert System (NSES) must ground conversational turns in formal discourse invariants, speech act rules, and semantic causality before neural token generation.

We conducted a full codebase audit of the NSES engine (`src/std/nses_pipeline.cl`, `src/std/cargraph.cl`, `src/std/veto_gate.cl`, `src/std/burroughs.cl`, `src/std/prompt_scaffold.cl`, `tools/cargraph_ingest.car`, and `test/geomind/chat.cl`).

---

## 2. Logical Dependency Tree

```
┌────────────────────────────────────────────────────────┐
│                   c_runtime.c / LLVM IR                │
│             (Direct Memory, Alloc, File I/O)           │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                      src/std/                          │
│   math.cl ──► collections.cl ──► string.cl ──► fs.cl   │
└───────────────────────────┬────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
┌───────────────────────────┐ ┌──────────────────────────┐
│      src/std/cargraph.cl  │ │   src/std/veto_gate.cl   │
│   (Binary Storage Engine) │ │ (Disobedience Firewall)  │
└─────────────┬─────────────┘ └───────────┬──────────────┘
              │                           │
              └─────────────┬─────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│               src/std/nses_pipeline.cl                 │
│         (Master NSES 7-Stage Pipeline Orchestrator)    │
│   - Stage 1: Domain Routing                            │
│   - Stage 2: Guardrails Extraction                     │
│   - Stage 3: Seed Proximity Mapping                    │
│   - Stage 4: Zero-Allocation CSR BFS Traversal         │
│   - Stage 5: Burroughs Stochastic Lateral Injection    │
│   - Stage 6: 4-Block Structured Prompt Assembly        │
│   - Stage 7: Post-Pass Deterministic Veto Gate         │
└───────────────────────────┬────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
┌───────────────────────────┐ ┌──────────────────────────┐
│  tools/cargraph_ingest.car│ │   test/geomind/chat.cl   │
│ (Knowledge Graph Compiler)│ │ (Interactive Chat Engine)│
└───────────────────────────┘ └──────────────────────────┘
```

---

## 3. Findings & Technical Debt Identified

### Finding 1: Missing Language & Discourse Domain (Domain 6) (`[ISSUE-252]`)
- **Location**: `tools/cargraph_ingest.car`, `src/std/nses_pipeline.cl`
- **Defect**: The knowledge graph compiler currently hardcodes only 6 domains:
  - Domain 0: `SYSTEM_CORE` (Physics & logical axioms)
  - Domain 1: `PHYSICS_SIM`
  - Domain 2: `TOPOLOGY_GEOMETRY`
  - Domain 3: `COMPLEXITY_THEORY`
  - Domain 4: `BIOLOGICAL_SYSTEMS`
  - Domain 5: `CAUSAL_TAXONOMY`
- **Impact**: When queries regarding language, conversation, dialogue, or grammar are processed, they fall through to default physical simulation or causal taxonomy domains. There are no rules enforcing speech act coherence, anaphoric reference consistency, or conversational pragmatics.

### Finding 2: Hardcoded Node String Resolution in NSES Memory Traversal
- **Location**: `src/std/nses_pipeline.cl` lines 180–210
- **Defect**: Traversed CSR graph nodes are mapped to text strings via static `if (n_id == 6.0) ...` branches instead of pulling rule strings from the compiled binary graph's string pool or an extensible lookup table.
- **Impact**: Any newly added domains (including Language) cannot surface their traversed memory nodes into the prompt scaffold.

### Finding 3: Lack of Linguistic & Conversational Contradiction Triggers
- **Location**: `src/std/veto_gate.cl`
- **Defect**: `veto_registry_populate_defaults` only defines triggers for energy conservation, entropy, superluminal travel, mathematical contradictions ($2+2=5$), momentum, biology, and physical causality.
- **Impact**: Conversational gibberish or self-negating linguistic contradictions (e.g. asserting that words have no communicative meaning, or that questions require no responses) bypass the deterministic firewall unchecked.

---

## 4. Read-Ahead Opportunities & Synthesis with Neuro-Symbolic Resources

From our review of `awesome-neurosymbolic-ai` and `ibm.github.io/neuro-symbolic-ai`:
1. **ConceptNet & Atomic2020 Primitives**: We can ingest core relational triples (`HasPrerequisite`, `Causes`, `CapableOf`, `Desires`, `IsA`) directly into Domain 6 as Horn clauses.
2. **Discourse Representation Theory (DRT)**: Rules for referent tracking and speech act classification fit directly into CARTAN's `satisfy ... backtrack` paradigm.
3. **Integration with `src/std/language_acquisition.cl`**: High-frequency discourse markers and transition bridges can be anchored directly to Domain 6 memory nodes.

---

## 5. Pre-Sprint Scrum Recommendations
- **Goal for Sprint 461**: Implement Domain 6 (`LANGUAGE_DISCOURSE`) in `tools/cargraph_ingest.car`, expand `src/std/veto_gate.cl` with linguistic pragmatics guardrails, wire dynamic rule/memory retrieval and intent routing in `src/std/nses_pipeline.cl`, and verify end-to-end with Target 71.
