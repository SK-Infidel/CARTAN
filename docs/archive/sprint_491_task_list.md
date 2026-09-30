# Sprint 491 Task List: Persistent Self-Identity & Cognitive Memory Domain (`SELF_AND_IDENTITY`)

- [x] **Task 1: Domain 9 Schema & Initialization**
  - [x] Register `Domain 9: SELF_AND_IDENTITY` in `geomind_chat_get_db()` in `test/geomind/chat.cl`.
  - [x] Seed default introspective identity attributes (`Self.name = 'GeoMind'`, `Self.role = 'Neuro-Symbolic Cognitive Assistant'`, `Self.creator = 'Rick'`, `Self.nature = 'Self-hosting sentient cognitive architecture written in CARTAN'`).
- [x] **Task 2: Dynamic Cognitive Preamble Assembly & Causal Prompt Injection**
  - [x] Implement `geomind_chat_build_cognitive_preamble(db: ptr) -> string` querying Domain 9 and Domain 1.
  - [x] Prepend native Gemma 4 system turn delimiters (`<|turn>system\n...<turn|>\n`) into Gemma instruction prompt in `geomind_chat_generate_reply_multimodal`.
- [x] **Task 3: Conversational Learning & Self-Decision Extraction**
  - [x] Implement `geomind_chat_learn_conversational_turn(speaker: string, text: string)` in `test/geomind/chat.cl`.
  - [x] Detect teaching patterns (*"Your name is..."*, *"Call yourself..."*, *"Call me..."*, *"My name is..."*) and update `Domain 9` / `Domain 1`.
  - [x] Detect model self-naming decisions (*"I choose the name..."*, *"Call me..."*) and persist to `Domain 9`.
  - [x] Integrate into `geomind_chat_interactive_loop` in `test/geomind/main.car`.
- [x] **Task 4: Compilation, Restart Verification & Regression Clearance**
  - [x] Rebuild `build/geomind.exe` and synchronize binaries.
  - [x] Empirically verify persistent identity across simulated restarts (`test/geomind/test_domain9_persistence.car`).
  - [x] Run full regression suite (`tools/run_affected_tests.ps1 -All`: 87/87 passed).
  - [x] Update `CHANGELOG.md` and archive walkthrough.
