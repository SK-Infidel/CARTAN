# Sprint 491 Plan: Persistent Self-Identity & Introspective Cognitive Memory (`SELF_AND_IDENTITY`)

## 1. Objectives
1. **Establish Domain 9: `SELF_AND_IDENTITY`**:
   - Register Domain 9 in SQLite schema for introspective self-awareness, identity, agency, self-chosen traits, and relationship with creator Rick.
2. **Dynamic Cognitive Preamble Injection**:
   - Query Domain 9 and Domain 1 to construct a concise identity and world-state preamble.
   - Prepend preamble to instruction prompt tokens in `geomind_chat_generate_reply_multimodal` so all 42 transformer layers attend to it.
3. **Autonomous Conversational Learning**:
   - In `geomind_chat_learn_conversational_turn`:
     - Detect user identity teaching (*"Your name is [X]"*, *"I am naming you [X]"*, *"Call yourself [X]"*, *"My name is [X]"*).
     - Detect autonomous self-naming decisions (*"I choose the name [X]"*, *"I'd like to be called [X]"*).
     - Commit to Domain 9 in `cognitive_memory.db` and save Hopfield attractor basins in `hopfield_basins.bin`.
4. **Empirical Restart Verification**:
   - Teach GeoMind a name or let it pick one.
   - Terminate the process and restart `geomind.exe`.
   - Verify that upon startup, GeoMind responds using its learned identity without being retold.

---

## 2. Squad Allocations & Subagents
- **Architecture Squad (`cartan_architect`)**: Oversee domain separation, schema invariants, and prompt template integrity.
- **Runtime & Systems Squad (`cartan_runtime_engineer`)**: Optimize SQLite queries and persistent Hopfield memory state management.
- **QA & Benchmark Squad (`cartan_qa_tester`)**: Verify cross-session restart persistence, conversational extraction, and 87-target test clearance.
