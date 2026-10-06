# Sprint 536 Task List: Dynamic Just-In-Time (JIT) Context Grounding, Minimal Startup Prefill & On-Demand Attribute Retrieval

- [x] **1. Minimal Startup Preamble Refactoring (`test/geomind/chat.cl`)**
  - [x] Refactor `geomind_chat_build_cognitive_preamble` to emit only:
    `[Cognitive Context]\nIdentity: GeoMind.\n` + verified directive (`Address <Name> warmly by name.\n`) or guest directive (`Interlocutor: Unverified Guest.\nAttempt to identify the guest user warmly, introduce yourself, and ask their name.\n`).
  - [x] Remove static creator mention, static profile block, and static tool definition block from default preamble.

- [x] **2. JIT Targeted User Attribute Retrieval (`test/geomind/chat.cl`)**
  - [x] Implement `geomind_chat_retrieve_jit_user_context(db: ptr, user_id: string, prompt: string) -> string`.
  - [x] Support semantic attribute matching:
    - Pet / dog / cat -> `pet`
    - Birthday / bday / born -> `birthday`
    - Job / work / career / occupation -> `occupation`
    - Live / location / city / residence -> `location`
    - Identity / who am i / know who / know me / relationship -> `preferred_name`, `role`, `relationship`
  - [x] Format concise JIT context block: `[Context: Interlocutor's <attr> is <val>]`.

- [x] **3. JIT Tool Schema Loading (`test/geomind/chat.cl`)**
  - [x] Extract tool definitions to `geomind_chat_get_tool_definitions() -> string`.
  - [x] Implement `geomind_chat_requires_tool_definitions(prompt: string) -> float` detecting tool execution intents.
  - [x] Conditionally append tool definitions only when tool intent is present.

- [x] **4. Prompt Assembly & Redundancy Removal (`test/geomind/chat.cl`, `test/geomind/main.car`)**
  - [x] In `geomind_chat_generate_reply_multimodal`, assemble prompt from minimal preamble + JIT user context (if triggered) + JIT tool definitions (if triggered) + user prompt.
  - [x] Remove hardcoded Section 8 override instruction hook.
  - [x] In `test/geomind/main.car`, add `/exit` to interactive REPL command handler.

- [x] **5. Dedicated Test Suite & Empirical Verification**
  - [x] Create `test/geomind/test_jit_context_and_minimal_prefill.car` covering all 5 gates.
  - [x] Compile and run test suite with status 0.
  - [x] Rebuild native `bin/geomind.exe` with `cartanc.exe`.
  - [x] Measure prefill tokens on live prompt: confirm reduction from 351 to $\le 30$ tokens ($>90\%$ reduction).
  - [x] Verify live prompt JIT attribute lookup on "My dog is sick" -> retrieves Athena (dog).
  - [x] Add preset `536` to `tools/run_affected_tests.ps1` and run regression suite (16/16 PASS).

- [x] **6. Documentation & Sprint Closure**
  - [x] Mark `[ISSUE-394]` in `ISSUES.md`.
  - [x] Update `CHANGELOG.md` to `[8.492.0]`.
  - [x] Update Phase 25 in `docs/ROADMAP.md`.
  - [x] Check off all tasks in `docs/archive/sprint_536_task_list.md`.
  - [x] Save walkthrough to `docs/archive/sprint_536_walkthrough.md`.

