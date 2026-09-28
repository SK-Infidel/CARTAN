# Sprint 470 Implementation Plan: Complete Cognitive Architecture Synthesis (Domains 11..17 & Universal Veto Harmonization)

## 1. Objectives
1. **Knowledge Ingestion & Proof (`tools/cargraph_ingest.car`)**:
   - Ingest 7 cognitive domains (Domains 11..17, Rules 92..161, 2 strict invariants + 8 relational rules per domain).
   - Expand total domains to 18 (0..17), total rules to 162 (0..161), strict invariants to 36.
   - Solve 192-variable propositional SMT/SAT consistency proof across all 18 domains and serialize flat binary `test/geomind/trainingdata/nses_knowledge.car_graph`.
2. **Universal Veto Gate & Contradiction Suppression (`src/std/veto_gate.cl`)**:
   - Add Veto Rules for Domains 2 & 3 (missing previously) and Domains 11..17 (Rules 14..22).
   - Register contradiction tokens for ALL domains (101..1704).
3. **Universal Lexicon & Discourse Framing (`src/std/domain_lexicon.cl`)**:
   - Add specialized terminology with authentic IC weights ($\ge 0.90$) for Domains 11..17.
   - Register canonical discourse frames 11..17 and expand category error validation across all 18 domains.
4. **Cognitive Pipeline Routing & CSR Bridges (`src/std/nses_pipeline.cl`)**:
   - Wire Stage 1 intent detection for Domains 11..17.
   - Wire Stage 3 seed selection for all new domains.
   - Wire cross-domain CSR bridges and memory tree fallbacks for unbacked node IDs 92..161.
5. **Lateral Primes & Training Routing (`src/std/burroughs.cl`, `test/geomind/train.cl`)**:
   - Add lateral primes for Domains 11..17 across tiers 1, 2, and 3.
   - Route dataset paths for Domains 11..17.
6. **Empirical Regression Suite (`test/compiler_suite/`)**:
   - Authored Target 80 (`test/compiler_suite/test_nses_universal_cognitive_domains.car`).
   - Whitelist in `.gitignore`, register in `test/compiler_suite/run_tests.car`, and pass all 80 compiler regression targets (80/80 passing, exit code 0).

## 2. Milestones
- **Milestone 1**: Compile and execute updated `tools/cargraph_ingest.car`, verify 192-variable SAT proof passes, and generate `nses_knowledge.car_graph`.
- **Milestone 2**: Update `src/std/veto_gate.cl`, `src/std/domain_lexicon.cl`, `src/std/burroughs.cl`.
- **Milestone 3**: Update `src/std/nses_pipeline.cl` and `test/geomind/train.cl`.
- **Milestone 4**: Author and verify Target 80 (`test_nses_universal_cognitive_domains.car`), recompile runner, and verify 80/80 test suite.
- **Milestone 5**: Documentation, changelog, roadmap, walkthrough, and commit/sync.
