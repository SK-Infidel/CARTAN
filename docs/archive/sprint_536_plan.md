# Sprint 536 Plan: Dynamic Just-In-Time (JIT) Context Grounding, Minimal Startup Prefill & On-Demand Attribute Retrieval

## 1. Objectives
1. **Minimal Startup Prefill**:
   - Refactor `geomind_chat_build_cognitive_preamble` to emit only essential identity and greeting directives ($\le 30$ tokens).
   - Verified user directive: `Address <Name> warmly by name.`
   - Unverified guest directive: `Attempt to identify the guest user warmly, introduce yourself and ask their name.`
   - Eliminate creator attribution from opening turn (retained in Domain 9 for self queries).
   - Eliminate static profile attribute dump and static tool specification from startup prefill.
2. **Just-In-Time (JIT) Attribute Retrieval**:
   - Implement `geomind_chat_retrieve_jit_user_context(db: ptr, user_id: string, prompt: string) -> string`.
   - Perform targeted lookups into Domain 10 (`USERS_AND_RELATIONSHIPS`) for specific topics mentioned in the prompt (e.g. `pet`, `birthday`, `occupation`, `location`, `identity`/`relationship`).
   - Inject only the specific relevant attribute when prompted (e.g. user says "My dog is sick" -> injects `[Context: Interlocutor's pet is Athena (dog)]`).
3. **Just-In-Time (JIT) Tool Schema Loading**:
   - Implement `geomind_chat_requires_tool_definitions(prompt: string) -> float`.
   - Separate tool schema into `geomind_chat_get_tool_definitions() -> string`.
   - Inject tool schema into prompt only when tool execution intent is detected.
4. **Clean Interactive Loop & Dedicated Verification**:
   - Add `/exit` handling in `test/geomind/main.car`.
   - Create 5-gate test suite `test/geomind/test_jit_context_and_minimal_prefill.car`.
   - Validate 16/16 compiler regression targets in `tools/run_affected_tests.ps1 -Sprint 536`.
   - Empirically verify live prompt prefill reduction and JIT attribute recall on `bin/geomind.exe`.

---

## 2. Squad Responsibilities
- **cartan_architect**: Minimal prefill schema design, JIT context formatting, and intent separation.
- **cartan_runtime_engineer**: JIT SQLite attribute query efficiency, tool schema conditional gating, and REPL input handling.
- **cartan_qa_tester**: 5-gate empirical verification suite, prefill token count measurement ($>80\%$ drop), and regression suite.
