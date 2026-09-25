# Sprint 410 Task List: Burroughs Lateral Injection Engine & Structured Prompt Scaffold

- [x] **Task 1: Pre-Sprint Scrum & Archive Alignment**
  - [x] Save `sprint_410_plan.md` and `sprint_410_task_list.md` to `docs/archive/`.
  - [x] Confirm zero blocking issues from Sprint 1-3.

- [x] **Task 2: Burroughs Fragment Pool & PRNG Sampler ([`src/std/burroughs.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/burroughs.cl))**
  - [x] Implement `BurroughsFragment` and `BurroughsPool` data structures.
  - [x] Implement `burroughs_pool_create`, `burroughs_pool_add`, `burroughs_pool_free`.
  - [x] Implement `BurroughsRngState` with high-uniformity L'Ecuyer/Marsaglia combined PRNG.
  - [x] Implement `burroughs_sample_fragment` with `entropy_tier` gating and monotonic `usage_count` updates.

- [x] **Task 3: Inviolable Structured Prompt Assembler ([`src/std/prompt_scaffold.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/prompt_scaffold.cl))**
  - [x] Implement `PromptScaffoldBuffer` with capacity management and bounds protection.
  - [x] Implement delimiter sanitization preventing adversarial tags from spoofing `[SYSTEM BOUNDS - INVIOLABLE]`.
  - [x] Implement 4-block assembler synthesizing bounds, knowledge, lateral context, and user input.

- [x] **Task 4: Empirical QA Verification Harness ([`test/geomind/nses/test_sprint4_burroughs_prompt.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/nses/test_sprint4_burroughs_prompt.car))**
  - [x] `TS-4.1`: Verify `entropy_tier == 0` produces null lateral injection.
  - [x] `TS-4.2`: Chi-Square ($\chi^2$) test on 10,000 draws ($p > 0.01$) and assert usage count integrity.
  - [x] `TS-4.3`: Boundary containment adversarial jailbreak attempt test.
  - [x] Latency benchmarks (sampling $\le 0.3\text{ ms}$, assembly $\le 0.4\text{ ms}$).

- [x] **Task 5: Compilation, Execution & DoD Verification**
  - [x] Compile with `cartanc.exe` to native executable.
  - [x] Execute `test_sprint4.exe` and assert clean exit code 0.
  - [x] Verify zero regressions on previous test harnesses.

- [x] **Task 6: Sprint Review, Documentation & Release**
  - [x] Save walkthrough to `docs/archive/sprint_410_walkthrough.md`.
  - [x] Update `test/geomind/Research/NSES_IMPLEMENTATION_PLAN.md`.
  - [x] Update `CHANGELOG.md` with release `[8.368.0]`.
