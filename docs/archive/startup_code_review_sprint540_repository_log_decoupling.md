# Startup Code Review: Sprint 540 - Repository Log Decoupling & GeoMind Log Partitioning

**Date**: 2026-10-05  
**Reviewer**: Antigravity  
**Target Issue**: `[ISSUE-398]`  
**Scope**: Partitioning `CHANGELOG.md` and `ISSUES.md` into dedicated GeoMind artifacts (`test/geomind/CHANGELOG.md`, `test/geomind/ISSUES.md`) and pruning root logs to retain strictly CARTAN language, compiler, runtime, and stdlib enhancements.

---

## 1. Executive Summary & Findings

In accordance with user directive Rule 3 ("There is a testing only model in the geomind folder, it is NOT part of this project") and Rick's mandate to separate repository logs:
1. **Severe Cross-Domain Log Coupling**:
   - `ISSUES.md` contains 398 issues: 157 pure CARTAN issues, 131 pure GeoMind issues, and 110 mixed issues.
   - `CHANGELOG.md` contains 575 version entries tracking both CARTAN language releases and GeoMind model/REPL experiments in a single file.
   - Pure GeoMind model issues (e.g. prompt tuning, canary generation, persona greetings, historical OpenCL passes, storytelling corpora) pollute the language compiler's technical debt registry.
2. **Missing Dedicated GeoMind Artifacts**:
   - `test/geomind/` lacks its own `CHANGELOG.md` and `ISSUES.md`.
3. **Partitioning Requirements**:
   - **`test/geomind/ISSUES.md`**: Must host all pure GeoMind issues and the GeoMind model-facing specifications of mixed issues.
   - **`test/geomind/CHANGELOG.md`**: Must host the complete history of GeoMind model milestones, SFT passes, REPL features, and multimodal perception capabilities.
   - **Root `ISSUES.md`**: Must be stripped of pure GeoMind issues. For mixed issues, it must retain only the CARTAN compiler, language, runtime, or standard library technical debt/feature (e.g. `llvm_codegen.car`, `wgpu.cl`, `transformer.cl`, SIMD dot products, pinned KV cache, `_kbhit` ABI lowering), referencing `test/geomind/ISSUES.md` for model-level specifics.
   - **Root `CHANGELOG.md`**: Must be stripped of model-level canary and prompt tweaks, keeping only the CARTAN language and runtime deliverables required to implement GeoMind features.

---

## 2. Logical Dependency Tree

```
                       ┌──────────────────────────────────────────────┐
                       │          CARTAN Programming Language         │
                       │           (Self-Hosting Compiler)            │
                       └──────────────────────┬───────────────────────┘
                                              │
                     ┌────────────────────────┴────────────────────────┐
                     ▼                                                 ▼
       ┌───────────────────────────┐                     ┌───────────────────────────┐
       │   Compiler Core Engine    │                     │     Standard Libraries    │
       │     (`src/cartanc/`)      │                     │        (`src/std/`)       │
       ├───────────────────────────┤                     ├───────────────────────────┤
       │ • ast.ch, lexer.car       │                     │ • tensor.cl, fs.cl, io.cl │
       │ • parser.car, type_checker│                     │ • wgpu.cl (WebGPU engine) │
       │ • optimizer.car           │                     │ • transformer.cl (GQA)    │
       │ • llvm_codegen.car        │                     │ • tokenizer.cl (262k Trie)│
       │ • core_runtime.car        │                     │ • sqlite_vec.cl (Tier 2)  │
       │ • main.car (Clang/LLD)    │                     │ • cargraph.cl, nses.cl    │
       └─────────────┬─────────────┘                     └─────────────┬─────────────┘
                     │                                                 │
                     └────────────────────────┬────────────────────────┘
                                              │ Compiles & Imports
                                              ▼
                               ┌─────────────────────────────┐
                               │        GeoMind Model        │
                               │      (`test/geomind/`)      │
                               ├─────────────────────────────┤
                               │ • main.car (REPL & Host CLI)│
                               │ • chat.cl (JIT Preamble)    │
                               │ • moe.cl (Sasaki Routing)   │
                               │ • streams.cl (8 Lie Streams)│
                               │ • train.cl (Curriculum SFT) │
                               └─────────────────────────────┘
```

---

## 3. Log Categorization & Migration Matrix

| Category | Definition | Root Repository (`/`) | GeoMind Model (`test/geomind/`) |
| :--- | :--- | :--- | :--- |
| **Pure CARTAN** | AST, lexer, parser, type checker, macros, LLVM codegen, optimizer, FFI, stdlib infrastructure, CLI driver. | **Retained in Full** | Omitted |
| **Pure GeoMind** | Model prompt phrasing, canaries, storytelling corpora, persona greetings, historical OpenCL archives, model doc realignment. | **Stripped Out** | **Migrated to `test/geomind/`** |
| **Mixed (CARTAN Feature for GeoMind)** | CARTAN compiler/stdlib feature implemented to empower GeoMind (e.g. `\e` string lowering, `_kbhit` ABI, AVX2 SIMD dot products, pinned KV cache arena, double-buffered GDDR6 staging). | **Retain CARTAN compiler & stdlib feature description; reference GeoMind issue.** | **Retain GeoMind model issue description; reference enabling CARTAN feature.** |

---

## 4. Issues Identified & Registration

- **`[ISSUE-398]` Registered**:
  - *Title*: Coupled Repository Logs: Partitioning `CHANGELOG.md` and `ISSUES.md` into Dedicated GeoMind Artifacts.
  - *Severity*: High (Architectural Boundaries, Zero-Entropy Workspace Standards).
  - *Component*: `ISSUES.md`, `CHANGELOG.md`, `test/geomind/ISSUES.md`, `test/geomind/CHANGELOG.md`.
