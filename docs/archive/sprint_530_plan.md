# Sprint 530 Plan: Standardized Canonical Interlocutor Schema & Ad-Hoc Attribute Discovery Engine

**Sprint**: 530  
**Target Version**: `8.486.0`  
**Primary Issue**: [`[ISSUE-388]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md)  
**Goal**: Implement dynamic ad-hoc attribute discovery for registered interlocutors in Domain 10 (`USERS_AND_RELATIONSHIPS`), coupled with a canonical field normalization registry to enforce standardized schema harmonization across all users, dynamic structured context append in the cognitive preamble, and dynamic profile inspection.

---

## 1. Architecture & Design

### 1.1 Canonical Attribute Normalization Registry
To prevent entropy and fragmented synonyms (`"bday"` vs `"birthday"`, `"dog"` vs `"pet"`, `"career"` vs `"occupation"`):
- Implement canonical normalization mapping in [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl):
  - `bday`, `birthdate`, `date of birth`, `born on` $\to$ `birthday`
  - `dog`, `cat`, `puppy`, `kitten`, `pet` $\to$ `pet`
  - `wife`, `husband`, `partner`, `fiance` $\to$ `spouse`
  - `son`, `daughter`, `kid`, `child` $\to$ `child`
  - `job`, `career`, `work`, `profession` $\to$ `occupation`
  - `city`, `lives in`, `from`, `hometown`, `residence` $\to$ `location`
  - `likes`, `hobby`, `interests`, `loves` $\to$ `interest`
- Any novel attribute that has no established synonym is registered as a new canonical field upon first encounter, ensuring subsequent occurrences across any user bind to that same field.

### 1.2 Conversational Ad-Hoc Discovery Pass
In `geomind_chat_learn_conversational_turn`:
- Scan user turn for personal predicate statements:
  - `"my [attribute] is [value]"` (e.g. `"my birthday is May 14"`, `"my occupation is software architect"`)
  - `"i have a [pet] named [value]"` / `"my [pet]'s name is [value]"`
  - `"my [family_rel] is [value]"`
  - `"i live in [value]"` / `"i am from [value]"`
- Map extracted attribute through the canonical normalizer.
- Upsert into Domain 10: `sqlite_vec_set_user_attr(db, g_active_user_id, canonical_attr, value)`.

### 1.3 Standardized Context Append in Cognitive Preamble
In [`geomind_chat_build_cognitive_preamble`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl#L1349):
- Query all active attributes for `g_active_user_id` from Domain 10 (excluding internal technical fields like `face_embedding`, `face_registered`, `permission_tier`).
- Construct a clean, structured context block appended to the system instruction:
  ```text
  [Interlocutor Profile: Rick Weber | Preferred Name: Rick | Nicknames: Rich | Role: Creator & Architect | Birthday: May 14 | Pet: Buster (dog) | ...]
  ```
- This guarantees the model's self-attention heads are pre-primed with relevant interlocutor background for all subsequent generation steps.

### 1.4 Dynamic Profile Inspection
In `geomind_chat_print_active_interlocutor`:
- Query and enumerate all ad-hoc custom attributes for `g_active_user_id`, displaying them cleanly alongside core identity attributes.

---

## 2. Verification Criteria
1. **Canonical Normalization**: Verified mapping of synonyms (`bday`, `dog`, `job`) to canonical keys (`birthday`, `pet`, `occupation`).
2. **Persistence**: Discovered attributes persist cleanly across restarts in `cognitive_memory.db`.
3. **Structured Context Append**: Validated prompt encoding contains `[Interlocutor Profile: ...]` in system turn.
4. **Parity & Regressions**: 16/16 compiler regression suite targets PASS in `tools/run_affected_tests.ps1 -Sprint 530`.
