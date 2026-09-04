# Sprint 293 Plan: Authentic AZR Compiler-Verified Reasoning Engine

## Objective
Eliminate all simulated proposer, solver, and substring reward verifier mocks in `src/std/reasoning.cl` and `test/geomind/azr_engine.cl` (`[ISSUE-041]`) by implementing genuine multi-level algorithmic reasoning tasks and empirical compiler verification via `cartanc.exe`.

## Scope & Target Issue
- **`[ISSUE-041]` Simulated AZR Proposer, Solver & Reward Verifier**:
  - Components: `src/std/reasoning.cl`, `test/geomind/azr_engine.cl`
  - Current Flaw: Canned string generation, dummy include prepending, and substring existence checks for reward signals.
  - Implementation:
    1. Multi-level algorithmic problem generators (Linear equations, Pythagorean metrics, Quadratic roots, Hyperbolic geometry).
    2. Algorithmic solver constructing complete, valid CARTAN syntax programs.
    3. Verifier compiling and executing candidates via `cartanc.exe run scratch/azr_candidate.car` and checking process exit codes.

## Logical Dependency Tree
```
cartanc.exe (Primary Compiler)
  └── cartan_system (core_runtime.car / io.cl)
        └── azr_framework_eval_binary_reward (src/std/reasoning.cl)
              ├── geomind_azr_eval_reward (test/geomind/azr_engine.cl)
              └── geomind_azr_run_selfplay (test/geomind/azr_engine.cl & main.car)
```

## Definition of Done (DoD)
- [ ] Proposer produces genuine parameterized algorithmic task programs.
- [ ] Solver synthesizes matching valid CARTAN solutions.
- [ ] Verifier compiles and executes candidate code via `cartanc.exe` exit status.
- [ ] Full regression suite passes without error.
- [ ] `ISSUES.md` and `CHANGELOG.md` updated.
- [ ] Sprint plan and retro archived to `docs/archive/`.
