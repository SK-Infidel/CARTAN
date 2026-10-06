# Sprint 530 Task List: Canonical Interlocutor Schema & Ad-Hoc Attribute Discovery Engine

- [x] **1. Canonical Field Normalizer & Registry (`src/std/sqlite_vec.cl` & `test/geomind/chat.cl`)**
  - [x] Implement `geomind_normalize_canonical_attr_name(raw_name: string) -> string` to map synonyms (`bday`, `dog`, `job`, `residence`, etc.) to established canonical keys (`birthday`, `pet`, `occupation`, `location`, etc.).
  - [x] Ensure novel attributes are registered dynamically as new canonical standards.

- [x] **2. Conversational Ad-Hoc Discovery Pass (`test/geomind/chat.cl`)**
  - [x] In `geomind_chat_learn_conversational_turn`: implement extraction patterns for personal attributes (`"my [attr] is [val]"`, `"i have a [pet] named [val]"`, `"i live in [val]"`).
  - [x] Normalize extracted attributes through the canonical mapper.
  - [x] Persist into Domain 10 under `g_active_user_id` via `sqlite_vec_set_user_attr`.

- [x] **3. Structured Context Append in Cognitive Preamble (`test/geomind/chat.cl`)**
  - [x] In `geomind_chat_build_cognitive_preamble`: enumerate all non-internal attributes for `g_active_user_id`.
  - [x] Construct standardized `[Interlocutor Profile: ...]` append block.
  - [x] Update `geomind_chat_print_active_interlocutor` to dynamically enumerate all ad-hoc attributes.

- [x] **4. Build, Benchmarks & Regression Suite**
  - [x] Rebuild `bin/geomind.exe` with `cartanc.exe`.
  - [x] Test live discovery Canary prompt: teach model a new fact (`"my birthday is May 14"` and `"i have a dog named Buster"`), verify canonical normalization and persistence.
  - [x] Add preset 530 to `tools/run_affected_tests.ps1` and run regression suite (16/16 PASS).

- [x] **5. Review, Documentation & Closure**
  - [x] Close `[ISSUE-388]` in `ISSUES.md`.
  - [x] Update `CHANGELOG.md` to `[8.486.0]`.
  - [x] Update Phase 25 in `docs/ROADMAP.md`.
  - [x] Save walkthrough to `docs/archive/sprint_530_walkthrough.md`.
