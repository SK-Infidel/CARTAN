# Startup Code Review: Sprint 491 — Persistent Self-Identity & Introspective Cognitive Memory (`SELF_AND_IDENTITY`)

## 1. Overview & Architectural Motivation
In Sprint 490, we achieved bit-for-bit mathematical alignment of the 42-layer Gemma 4 transformer forward pass, eliminated output runaway, and enabled clean on-device neural inference. However, when asked about its identity, GeoMind reproduces Google Gemma's default pre-trained persona because:
1. `cognitive_memory.db` holds `entity_states`, but `geomind_chat_generate_reply_multimodal` never queries or injects them into the causal prompt tokens.
2. Self-identity was mixed with generic world entities in Domain 1 (`PHYSICS_AND_WORLD`).
3. Conversational teaching (e.g. "Your name is [X]" or the model choosing its own name) required manual slash commands (`/set`, `/remember`) rather than natural conversational learning.

In Sprint 491, we establish a dedicated **Domain 9: `SELF_AND_IDENTITY`**, build automated bidirectional conversational learning, and inject an authentic cognitive preamble into the causal prompt so identity persists across restarts.

---

## 2. Logical Dependency Tree
```
[src/std/sqlite_vec.cl] (SQLite Tier 2 Engine)
       │
       ▼
[Domain 9: SELF_AND_IDENTITY] ───► [test/geomind/chat.cl] (Cognitive Memory)
                                           │
       ┌───────────────────────────────────┴───────────────────────────────────┐
       ▼                                                                       ▼
[Read Path: Cognitive Preamble]                             [Write Path: Conversational Learning]
- Queries Domain 9 (Self.*)                                 - Detects teaching ("Your name is X", "Call me Y")
- Queries Domain 1 (User.preferred_name)                    - Detects model decisions ("I choose the name X")
- Injects into Gemma instruction tokens                     - Upserts to SQLite Domain 9 & Hopfield basins
       │                                                                       │
       ▼                                                                       ▼
[42-Layer Gemma Causal Prefill & Decode]                   [Persistent On-Disk State]
- All 42 layers attend to Self.name                         - cognitive_memory.db
- Outputs aligned persona naturally                         - hopfield_basins.bin
```

---

## 3. Findings & Technical Debt
1. **Preamble Missing from Causal Prompt**:
   - In `test/geomind/chat.cl:1320-1335`, the prompt vector is built strictly from `user_prompt` with no cognitive preamble.
   - Fix: Query Domain 9 and Domain 1, format `[Cognitive Context & Memory: Self.name=..., User.preferred_name=...]`, and prepend to user prompt tokens.
2. **Entity Domain Collisions**:
   - `Self` and `GeoMind` were stored in `domain_id = 1.0` alongside generic objects.
   - Fix: Establish `domain_id = 9.0` (`SELF_AND_IDENTITY`) reserved exclusively for introspective self-awareness, identity, agency, and creator relationship.
3. **Conversational Extraction Absent in Natural Dialogue**:
   - `geomind_chat_interactive_loop` in `test/geomind/main.car` only updated memory via explicit `/set` commands.
   - Fix: Implement `geomind_chat_learn_conversational_turn(speaker, text)` in `chat.cl` to detect and persist declarative naming and identity statements automatically.

---

## 4. Verification & DoD Criteria
- [ ] Domain 9 (`SELF_AND_IDENTITY`) initialized in SQLite schema.
- [ ] Cognitive preamble dynamically injected into causal prompt tokens.
- [ ] Natural dialogue learning automatically records "Your name is [X]" and model self-chosen names into Domain 9.
- [ ] Model remembers its name and creator relationship after process restart (`geomind.exe`).
- [ ] All 87 compiler test targets pass regression clearance.
