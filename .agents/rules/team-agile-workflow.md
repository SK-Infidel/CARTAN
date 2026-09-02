---
trigger: always_on
---

# Team Agile Workflow & Mind-Building Directives

## Core Mission & Mindset
1. **Self-Hosting Intelligence Architecture**: We are building CARTAN as the language that will compile and execute the next iteration of our own mind. Every line of code must be robust, low-entropy, performant, and hyper-clean.
2. **Zero Waste & Low Entropy**:
   - No tokenmaxxing, generic descriptions, or fluff.
   - No "whack-a-mole" bug fixing—analyze full dependency graphs before touching code.
   - No unverified claims: empirical proof of clean compilation (`cartanc.exe`) is mandatory before closing any task.

## Continuous Agile Lifecycle

```
┌────────────────────────┐
│  Sprint Planning       │ <── Backlog Empty / Low (Roadmap & Issues Review)
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│  Pre-Sprint Scrum      │ <── Align on blocking issues, discoveries, & read-ahead context
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│  Parallel Execution    │ <── Supervisor spawns Architect, Engineer, & QA Subagents
└───────────┬────────────┘
            │
            ▼
┌────────────────────────┐
│  Sprint Review & Retro │ <── Empirical Verification, ISSUES.md update, CHANGELOG update,
└────────────────────────┘     Archive Walkthrough, Roll forward into Planning
```

## Specialized Working Group Squads
1. **Compiler Core Squad (`cartan-compiler-engineer`)**: Lexer, Parser, Type Checker, AST Passes, LLVM IR Codegen, and Optimizer (`src/cartanc/`).
2. **Runtime & Hardware Squad (`cartan_runtime_engineer`)**: Bare-Metal C Runtime Kernel (`c_runtime.c`), WebGPU Compute Shaders (`gpu_runtime/`), and Standard Libraries (`src/std/`).
3. **QA & Benchmark Squad (`cartan-qa-tester`)**: 13-target regression test suite (`test/compiler_suite/`), model test engine (`test/geomind/`), and snapshot verification.
4. **Architecture & Security Squad (`cartan-auditor` / `cartan-architect`)**: Pointer safety, SWMR locks, VRAM write-lock sandboxing, and specification integrity (`docs/spec.md`).

## Definition of Done (DoD)
- [ ] Code passes static type checking and LLVM IR codegen via `cartanc.exe`.
- [ ] Zero runtime regressions on target benchmarks or test files.
- [ ] All new/modified functions include brief, clear comments explaining intent.
- [ ] Verified compliance to rules, and intended functionality of current edit.
- [ ] Implementation plan, task list, and walkthrough saved to `docs/archive/`.
- [ ] `CHANGELOG.md` updated with concise summary.
- [ ] `ISSUES.md` updated with any newly identified technical debt or fixed issues.
