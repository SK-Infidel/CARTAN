# Startup Code Review — Sprint 462
**Date**: September 28, 2026
**Investigator**: Supervisor Agent & CARTAN Squads
**Focus**: Automated Neuro-Symbolic Triple Ingestion Compiler & Rule Generator (`[ISSUE-253]`)

---

## 1. Executive Summary & Big Picture

Having established Domain 6 (`LANGUAGE_DISCOURSE`) in Sprint 461, scaling the expert system across broader corpora (ConceptNet 5.8, ATOMIC 2020, ProofWriter) requires transitioning from manual rule specification to **automated rule generation and compilation**.

We audited the dataset formats and the CARTAN ingestion toolchain:
- **ConceptNet 5.8 TSV format**: `/a/[/r/Relation/,/c/en/Subject/,/c/en/Object/]` + JSON payload with weight $\ge 1.0$.
- **ATOMIC 2020 format**: `Head \t Relation (e.g. xIntent, xNeed, xEffect) \t Tail \t Confidence`.
- **ProofWriter Horn clauses**: Natural language premises and rules mapped to $P_1 \land P_2 \implies Q$.

---

## 2. Logical Dependency Tree

```
┌────────────────────────────────────────────────────────┐
│                   Raw Dataset Corpora                  │
│       (ConceptNet 5.8 TSV, ATOMIC 2020, ProofWriter)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│               tools/ns_rule_generator.car              │
│    - Tabular Line Parser (TSV/CSV tokenization)        │
│    - Relation Normalizer (HasPrerequisite, Causes, etc)│
│    - Confidence Filtering (Confidence >= 0.95)         │
│    - SMT/SAT Propositional Consistency Checker         │
└───────────────────────────┬────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
┌───────────────────────────┐ ┌──────────────────────────┐
│ Native CARTAN Source Code │ │     Flat Binary Output   │
│ knowledge_base <Domain> { │ │  test/geomind/           │
│   rule <Name> = ...;      │ │  trainingdata/           │
│ }                         │ │  nses_knowledge.car_graph│
└───────────────────────────┘ └──────────────────────────┘
```

---

## 3. Findings & Debt Identified

### Finding 1: Manual Hardcoding Bottleneck (`[ISSUE-253]`)
- **Location**: `tools/cargraph_ingest.car`
- **Defect**: Rules and implication constraints are written line by line in source code. Ingesting hundreds or thousands of high-confidence commonsense triples from ConceptNet or ATOMIC 2020 cannot scale manually.
- **Impact**: Knowledge acquisition is throttled to human authoring speed.

### Finding 2: Ingestion Consistency Verification
- **Location**: `src/std/sat_solver.cl`
- **Requirement**: Automated ingestion must automatically detect conflicting edges (e.g., if one triple implies $A \implies B$ and another asserts $A \implies \neg B$) and reject contradictory triples before writing to `.car_graph`.

---

## 4. Sprint 462 Execution Strategy
1. Author `tools/ns_rule_generator.car` capable of:
   - Reading structured dataset files with `fs_read_all`.
   - Splitting lines and fields with `string_split`.
   - Normalizing relations into standard Horn clauses.
   - Asserting implications in `sat_solver.cl` and validating satisfiability.
   - Emitting validated `.car_graph` files and declarative CARTAN `knowledge_base` code.
2. Verify with **Target 72** (`test/compiler_suite/test_ns_rule_generator.car`).
