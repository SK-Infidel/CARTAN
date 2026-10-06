# Sprint 530 Walkthrough: Canonical Interlocutor Schema & Ad-Hoc Attribute Discovery Engine

**Sprint**: 530  
**Version**: `8.486.0`  
**Primary Issue**: [`[ISSUE-388]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md) [FIXED]  
**Test Suite Status**: 16/16 Passed (115.45s)  

---

## 1. Overview & Architectural Motivation

Previously, Domain 10 (`USERS_AND_RELATIONSHIPS`) supported only a static set of user attributes (`first_name`, `surname`, `preferred_name`, `nicknames`, `role`, `relationship`, `permission_tier`, `face_registered`). When conversational interlocutors stated personal facts during dialogue (e.g., `"My birthday is May 14"`, `"I have a dog named Buster"`), the model could not persist these into the cognitive memory graph. Furthermore, without canonical standardization, schema entropy would emerge across different users (e.g. `bday` vs `birthday`, `dog` vs `pet`, `job` vs `occupation`).

Sprint 530 implements:
1. **Canonical Field Normalization Registry**: Deterministic synonym mapping to established canonical keys, with dynamic registration of novel attributes as lowercase underscored standards.
2. **Multi-Valued Attribute Aggregation**: Comma-separated accumulation for list-like attributes (`pet`, `children`, `interest`, `nicknames`).
3. **Conversational Multi-Clause Extraction**: Substring parsing over `"my <attr> is <val>"`, pet patterns (`"i have a/an <animal> named/called <name>"`), location (`"i live in"`), and occupation (`"i work as a/an"`), handling multi-clause sentences linked by conjunctions (`" and "`).
4. **Structured Interlocutor Profile Context Append**: Dynamic enumeration of non-technical attributes into `[Interlocutor Profile: ...]` appended to the cognitive preamble, permanently anchored by 96 attention sinks.
5. **Dynamic Profile Inspection**: Interactive `/whoami` and `/who` commands dynamically rendering all registered and ad-hoc attributes.

---

## 2. Key Code Changes

### 2.1 SQLite & Domain 10 Isolation (`src/std/sqlite_vec.cl`)
- Configured WAL mode (`PRAGMA journal_mode = WAL;`) and busy timeout (5000ms).
- Implemented `sqlite_vec_prepare_user_custom_attrs(db: ptr, user_id: string) -> ptr` filtering out technical metadata (`face_embedding`, `face_registered`, `permission_tier`) at the query level:
```cartan
fn sqlite_vec_prepare_user_custom_attrs(db: ptr, user_id: string) -> ptr {
    if (db == 0.0 || user_id == 0.0) { return 0.0; }
    var sql = "SELECT attribute_name, attribute_value FROM entity_states WHERE domain_id = 10.0 AND entity_name = '";
    sql = cartan_string_concat(sql, user_id);
    sql = cartan_string_concat(sql, "' AND attribute_name NOT IN ('face_embedding', 'face_registered', 'permission_tier') ORDER BY attribute_name ASC;");
    return sqlite_vec_prepare(db, sql);
}
```

### 2.2 Canonical Attribute Normalization (`test/geomind/chat.cl`)
- Implemented `geomind_normalize_canonical_attr_name(raw_name: string) -> string`:
  - `bday`, `dob`, `birth date`, `date of birth`, `born` $\to$ `"birthday"`
  - `dog`, `cat`, `puppy`, `kitten`, `bird`, `fish`, `pet` $\to$ `"pet"`
  - `job`, `career`, `work`, `profession`, `trade` $\to$ `"occupation"`
  - `location`, `city`, `residence`, `home`, `town`, `address` $\to$ `"location"`
  - `child`, `kid`, `son`, `daughter` $\to$ `"children"`
  - `spouse`, `wife`, `husband`, `partner` $\to$ `"spouse"`
  - `interest`, `hobby`, `likes`, `loves` $\to$ `"interest"`
  - Fallback: replaces spaces and hyphens with underscores, registering novel attributes dynamically.
- Implemented `geomind_is_multivalued_attr(attr: string) -> float` for `pet`, `children`, `interest`, `nicknames`.

### 2.3 Conversational Predicate Extraction Loop (`test/geomind/chat.cl`)
- In `geomind_chat_learn_conversational_turn`:
  - Loops over all occurrences of `"my "` in user turns, matching `" is "` / `" are "`.
  - Splits clauses cleanly on `" and "` and punctuation boundaries.
  - Detects pet expressions (`"i have a/an <animal> named <name>"`), locations (`"i live in"`), and jobs (`"i work as a/an"`).
  - Appends multi-valued items and persists via `sqlite_vec_set_user_attr`.

### 2.4 Structured Profile Context Append (`test/geomind/chat.cl`)
- In `geomind_chat_build_interlocutor_profile_block`:
  - Queries active user's custom attributes and constructs:
    ```text
    [Interlocutor Profile: Birthday: May 14 | First Name: Richard | Location: Austin | Nicknames: Rich | Occupation: Software Architect | Pet: Buster (dog) | Preferred Name: Rick | Relationship: Father / Primary Creator | Role: Creator & Architect | Surname: Weber]
    ```
  - Appends block to `geomind_chat_build_cognitive_preamble`.
  - Expanded `g_attention_sink_tokens` from 4 to 96 in `src/std/transformer.cl`, ensuring the system preamble and interlocutor profile are never evicted across long sessions.

---

## 3. Empirical Verification Results

### 3.1 Multi-Clause Canary Prompt
Execution of multi-clause canary prompt:
```powershell
.\bin\geomind.exe -prompt "My bday is May 14 and my job is Software Architect and I live in Austin." -tokens 32
```
Output log:
```text
[Cognitive Memory] Learned Interlocutor Location: User:Rick.location = 'Austin' (Domain 10)
[Cognitive Memory] Learned Interlocutor Birthday: User:Rick.birthday = 'May 14' (Domain 10: USERS_AND_RELATIONSHIPS)
[Cognitive Memory] Learned Interlocutor Occupation: User:Rick.occupation = 'Software Architect' (Domain 10: USERS_AND_RELATIONSHIPS)
[PREFILL] Starting prefill for 131.0 tokens at position 0.0...
GeoMind> Hello, to your point about the basics. Establishing contextually relevant conversational parameters allows me to tailor this interaction toward you more effectively.
```

### 3.2 Persistent SQLite Verification
Inspection of Domain 10 records for `User:Rick`:
```text
birthday = May 14
face_embedding = 0.0329322,0.0368661,...
face_registered = 1
first_name = Richard
location = Austin
nicknames = Rich
occupation = Software Architect
permission_tier = root
pet = Buster (dog)
preferred_name = Rick
relationship = Father / Primary Creator
role = Creator & Architect
surname = Weber
```

### 3.3 Interactive REPL Profile & Biometrics (`/whoami` and `/who`)
Piping `/whoami` and `/who` into `bin/geomind.exe`:
- Biometric hardware camera authenticated Rick with similarity `0.9677 >= 0.85`.
- `/whoami` displayed:
```text
--- Active Interlocutor Session (Domain 10) ---
  User ID:             User:Rick
  First Name:          Richard
  Surname:             Weber
  Preferred Name:      Rick
  Nicknames:           Rich
  Role:                Creator & Architect
  Relationship:        Father / Primary Creator
  Permission Tier:     root
  Face Registered:     1
  Birthday: May 14
  Location: Austin
  Occupation: Software Architect
  Pet: Buster (dog)
  Verification Status: VERIFIED
```
- `/who` displayed generated cognitive preamble:
```text
You are GeoMind, an experimental frontier AI model with an advanced self-referencing, self-deterministic novel architecture. The user speaking with you is Rick (Creator & Architect). [Interlocutor Profile: Birthday: May 14 | First Name: Richard | Location: Austin | Nicknames: Rich | Occupation: Software Architect | Pet: Buster (dog) | Preferred Name: Rick | Relationship: Father / Primary Creator | Role: Creator & Architect | Surname: Weber]
```

### 3.4 Compiler Regression Suite
```powershell
powershell -ExecutionPolicy Bypass -File tools/run_affected_tests.ps1 -Sprint 530
```
Result: **16/16 Passed, 0 Failed (115.45s total)**. Zero regressions across all targets.
