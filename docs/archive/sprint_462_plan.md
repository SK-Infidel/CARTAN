# Sprint 462 Plan: Automated Neuro-Symbolic Rule Generator & Horn-Clause Ingestion Compiler

## Sprint Objective
Resolve `[ISSUE-253]` by developing `tools/ns_rule_generator.car`—an automated ingestion and transpilation engine that ingests relational triples (ConceptNet / ATOMIC 2020 format), filters by confidence, checks SMT/SAT consistency, and compiles them directly into native CARTAN declarative `knowledge_base` syntax and `.car_graph` flat binaries. Verify with Target 72 and the full 72-target compiler regression suite under zero-mock standards.

---

## Technical Specifications

### Phase 1: Tool Architecture (`tools/ns_rule_generator.car`)
1. **CLI Interface**:
   ```bash
   ns_rule_generator.exe <input_triples.tsv> <output.car_graph> [output_declarative.car]
   ```
2. **Parser & Normalization Engine**:
   - Parses TSV format: `head \t relation \t tail \t confidence \t is_strict`.
   - Normalizes relations into human-readable, logically sound natural language rules:
     - `HasPrerequisite(A, B)` $\implies$ `"A is a mandatory prerequisite for B."`
     - `Causes(A, B)` $\implies$ `"A directly causes B."`
     - `CapableOf(A, B)` $\implies$ `"A is capable of B."`
     - `xIntent(A, B)` $\implies$ `"The communicative intent behind A is B."`
     - `xNeed(A, B)` $\implies$ `"Executing A requires B beforehand."`
     - `xEffect(A, B)` $\implies$ `"The pragmatic consequence of A is B."`
3. **Automated SMT/SAT Consistency Guard**:
   - Allocates `sat_solver` for the rule set.
   - Converts causal and prerequisite pairs into SAT implications (`sat_add_implication(solver, head_id, tail_id)`).
   - Flags and rejects any circular contradictions or conflicting axioms ($P \land \neg P$).
4. **Dual Output Emission**:
   - Compiles validated triples directly into flat binary `.car_graph` via `cargraph_builder_*`.
   - Optionally writes native declarative CARTAN code (`knowledge_base <Domain> { rule R = ...; }`).

### Phase 2: Target 72 Regression Test (`test/compiler_suite/test_ns_rule_generator.car`)
1. Provide authentic sample corpus containing linguistic and commonsense triples (communication, speech, questions, answers).
2. Invoke rule generation routines to ingest triples, generate declarative CARTAN rule declarations, verify SAT consistency, and serialize to `.car_graph`.
3. Load the emitted `.car_graph` via `cargraph_load_binary` and verify headers, rule texts, and strict counts.

### Phase 3: Regression Suite Integration & DoD Verification
1. Compile `tools/ns_rule_generator.car` with `cartanc.exe`.
2. Add Target 72 to `test/compiler_suite/run_tests.car` and `.gitignore`.
3. Rebuild `build/run_tests.exe` and execute all 72 targets (72/72 passing).
4. Update `ISSUES.md` (`[ISSUE-253]` -> `[FIXED]`), `CHANGELOG.md` (`[8.420.0]`), `docs/ROADMAP.md`, and save `docs/archive/sprint_462_walkthrough.md`.
