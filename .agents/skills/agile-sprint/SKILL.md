---
name: agile-sprint
description: Orchestrates an end-to-end Agile Sprint workflow for CARTAN language development, including Sprint Planning, Pre-Sprint Scrum, subagent execution, empirical QA verification, retrospective reporting, CHANGELOG management, and artifact archiving.
---

# CARTAN Agile Sprint Skill

This skill guides the Supervisor Agent through executing structured, low-entropy Agile sprints for CARTAN language engineering.

## Sprint Execution Phases

### Phase 1: Sprint Planning & Audit
1. Read `docs/ROADMAP.md` and `ISSUES.md` to identify top-priority items.
2. Run full codebase dependency analysis on files targeted for change.
3. Formulate concise Sprint Goal and 1-3 user stories.

### Phase 2: Pre-Sprint Scrum
1. Review blocking issues and discoveries from the audit.
2. Outline read-ahead risks and dependency boundaries.
3. Delegate tasks to specialized subagents:
   - `cartan-compiler-engineer`: Feature implementation and AST/LLVM modifications.
   - `cartan-qa-tester`: Empirical verification (`cartanc.exe` builds & execution).
   - `cartan-auditor`: Deep code inspection and issue tracking.

### Phase 3: Sprint Execution & Verification
1. Subagents execute work using line-by-line precise editing.
2. QA Tester verifies build: `cartanc.exe target.car`.
3. If build fails: inspect full logs, trace root cause, fix underlying contract (no symptom patching).

### Phase 4: Sprint Review & Retrospective
1. Verify Definition of Done (DoD).
2. Save Implementation Plan, Task List, and Walkthrough to `docs/archive/sprint_<N>_walkthrough.md`.
3. Update `CHANGELOG.md` with concise session entries.
4. Mark completed items in `docs/ROADMAP.md` and update `ISSUES.md`.
5. Roll unfulfilled items or newly discovered debt into the next Sprint Planning backlog.
