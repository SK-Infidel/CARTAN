# Startup Code Review: Sprint 536 — Dynamic Just-In-Time (JIT) Context Grounding, Minimal Startup Prefill & On-Demand Attribute Retrieval

## 1. Context & Objective
In Sprint 535, we achieved universal interlocutor recognition and eliminated channel thought leaks. However, empirical analysis of the prefill assembly revealed severe token bloat and duplication:
- **Baseline Prefill**: 351 tokens for a single simple conversational turn (`"Do you know who I am?"`).
- **Tool Schema Bloat**: 176 tokens (50.1% of entire prefill) unconditionally injected on every opening turn, detailing 7 tools even when no tool use is intended.
- **Interlocutor Identity Duplication**: Rick's name, role, and relationship were repeated 4 separate times across Sections 2, 3, 4, and 8.
- **Static Profile Dump**: Injected 63 tokens of all custom attributes (birthday, location, pet, nicknames, etc.) regardless of prompt relevance.
- **Associative Memory Stacking**: Keyword-triggered episodic lookups continuously inflated multi-turn prefill by 50–120 tokens per turn.

**Sprint 536 Objective**: Replace hardcoded, static prefill with **Dynamic Just-In-Time (JIT) Context Grounding**:
1. Minimal startup prefill: Only essential identity and greeting directives ($\le 30$ tokens, $>85\%$ reduction).
2. Just-In-Time (JIT) targeted attribute retrieval: Query Domain 10 only when prompt semantics touch specific personal domains (e.g. pet, birthday, job, location).
3. Just-In-Time (JIT) tool schema loading: Inject tool syntax and capabilities only when tool intent is detected.
4. Clean guest fallback: Warmly introduce self and prompt guest for identification without corporate boundaries.

---

## 2. Logical Dependency Tree
```
test/geomind/chat.cl
├── geomind_chat_build_cognitive_preamble(db) [Minimal: Identity + Interlocutor greeting directive only]
├── geomind_chat_retrieve_jit_user_context(db, user_id, prompt) [NEW: targeted Domain 10 lookups]
│   └── sqlite_vec_get_user_attr(db, user_id, attr_name) [src/std/sqlite_vec.cl]
├── geomind_chat_requires_tool_definitions(prompt) [NEW: Tool intent classifier]
├── geomind_chat_get_tool_definitions() [NEW: Standalone 176-token tool schema]
└── geomind_chat_generate_reply_multimodal [Dynamic assembly: Minimal Preamble + JIT Context + JIT Tools + Prompt]

test/geomind/main.car
└── geomind_chat_interactive_loop [Interactive REPL: handles /exit, exit, quit cleanly]

test/geomind/test_jit_context_and_minimal_prefill.car
└── 5-Gate empirical verification suite (100% Zero-Mock)
```

---

## 3. Discovered Technical Debt & Issues
1. `geomind_chat_build_cognitive_preamble` hardcodes creator attribution, full custom attribute enumeration, and 176-token tool specifications in a single rigid string.
2. `geomind_chat_generate_reply_multimodal` appended redundant hardcoded instruction blocks (Section 8) to user prompts containing "who am i" / "know me".
3. `main.car` REPL loop handled `exit` and `quit` but allowed `/exit` to fall through into generating a model reply turn.
4. No JIT intent detection exists for selectively attaching tool schemas or specific user attributes.

---

## 4. Architectural & Safety Invariants
- **Zero-Mock Rule**: JIT lookups must perform authentic SQLite queries against `entity_states` via `sqlite_vec_get_user_attr`.
- **Gemma Turn Invariant**: Minimal prefill remains combined into the opening `<start_of_turn>user` turn to avoid foreign system role refusal.
- **Fallback Invariant**: If no JIT attributes or tools are triggered, prefill size drops to $< 30$ tokens without losing conversational fluency or identity grounding.
