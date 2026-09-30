# Sprint 492 Plan: Multi-Turn Conversational Coherence, Dynamic Factual Grounding & Test Harness Integrity

## 1. Objectives & Scope
- **Gate 1 (Harness Integrity, [ISSUE-316])**: Wire Target 88 (`test_autodiff_backward_syntax.car`) into `tools/run_affected_tests.ps1` (`1..88`) and `test/compiler_suite/run_tests.car` (`88/88`), eliminating the test omission gap.
- **Gate 2 (Dynamic Entity Grounding, [ISSUE-318])**: Eradicate static hardcoded substrings (`"france"`, `"biology"`, `"cell"`) in `geomind_chat_retrieve_factual_attractor`, replacing them with dynamic entity state queries against SQLite `entity_states`.
- **Gate 3 (Multi-Turn Conversational Coherence, [ISSUE-317])**:
  - Add session episode retrieval functions to `src/std/sqlite_vec.cl` to query recent dialogue turns in chronological order.
  - Implement dynamic multi-turn dialogue sequence assembly in `test/geomind/chat.cl`:
    `<bos><|turn>system\n[System Preamble]<turn|>\n<|turn>user\n[Turn 1]<turn|>\n<|turn>model\n[Reply 1]<turn|>\n...<|turn>user\n[Active Prompt]<turn|>\n<|turn>model\n`
  - Ensure conversational learning, online critic, and Hopfield attractor memory operate coherently across multi-turn interactions.
- **Gate 4 (Empirical Verification & Zero Regressions)**:
  - Verify multi-turn contextual continuity in `geomind.exe`.
  - Pass all 88 regression suite targets with 0 failures (`tools/run_affected_tests.ps1 -All`).

---

## 2. Architectural Design

### 2.1 Multi-Turn Prompt Sequence Assembly
```
┌────────────────────────────────────────────────────────┐
│                   <bos> Token (2)                      │
├────────────────────────────────────────────────────────┤
│ <|turn>system\n [Cognitive Preamble: Domain 9 & 1] <turn|>\n │
├────────────────────────────────────────────────────────┤
│ <|turn>user\n [Turn 1 User Prompt] <turn|>\n          │
│ <|turn>model\n [Turn 1 Model Response] <turn|>\n       │
│ ...                                                    │
├────────────────────────────────────────────────────────┤
│ <|turn>user\n [Active User Prompt] <turn|>\n           │
├────────────────────────────────────────────────────────┤
│ <|turn>model\n                                         │
└────────────────────────────────────────────────────────┘
```

### 2.2 Dynamic Entity Grounding
Instead of:
```cartan
if (cartan_string_contains(prompt, "france") != 0.0) { ... }
```
We query:
`sqlite_vec_find_entity_attribute_in_prompt(db, prompt)` which iterates through registered entities in `entity_states` and checks if `prompt` contains the entity name. When found, it retrieves its primary attribute value dynamically.
