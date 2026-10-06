# Startup Code Review: Sprint 535 - Universal Interlocutor Recognition & Dynamic Greeting, Channel Thought Suppression & Natural Persona Alignment

## 1. Executive Summary & Objective
In Sprint 535, we address critical conversational usability, persona alignment, and interlocutor recognition issues identified during live sessions:
1. **Universal Interlocutor Recognition & Dynamic Greeting**: When any interlocutor is identified (via facial biometrics or conversational onboarding into Domain 10: Rick, family, friends, or colleagues), GeoMind must greet them by their preferred name upon session startup, address them warmly during conversation, and directly confirm their identity when asked without corporate disclaimers or evasiveness.
2. **Channel Thought Suppression**: Gemma-4 emits reasoning inside `<|channel>thought ... </body></html>` or `<channel|>`. This reasoning leaked to stdout because `geomind_sanitize_output_for_display` only checked for `<think>`. We must strip all channel/thought tags and HTML tags, while masking token `100.0` (`<|channel>`) during conversational generation to prevent trapping decode inside thought channels.
3. **Cognitive Preamble Persona Realignment**: Remove the sterile "experimental frontier AI model with an advanced self-referencing novel architecture" phrase that triggers safety refusal modes. Prime GeoMind as an authentic sovereign intelligence created by Rick, instructed to converse naturally, warmly, and directly with recognized interlocutors.

---

## 2. Code Review & Findings Across Components

### A. [`test/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/chat.cl)
1. **`geomind_compute_e8_lm_head` (Line 80)**:
   - Control token mask only filters `0.0, 2.0, 3.0, 105.0, 2364.0, 4368.0`.
   - Special channel tokens `100.0` (`<|channel>`), `101.0` (`<channel|>`), and `98.0` (`<|think|>`) are unmasked. When the model selects `100.0`, it enters the internal channel thought block, terminates prematurely at `</body></html>` (`106.0`), and never reaches the user-facing response.
   - *Fix*: Mask `100.0`, `101.0`, and `98.0` with `-10000.0` during conversational decode.

2. **`geomind_sanitize_output_for_display` (Line 1267)**:
   - Only checks `<think> ... </think>` and `<tool_call:...>`.
   - Fails to sanitize `<|channel>thought`, `<channel|>`, `</body></html>`, `<|think|>`, `gwrl_internal`, and other channel wrappers.
   - *Fix*: Add pattern matchers to strip `<|channel>thought` up to `<channel|>`, `</body></html>`, `</thought>`, or `<|channel>`, as well as stray `</body></html>`.

3. **`geomind_chat_build_cognitive_preamble` (Line 2716)**:
   - Sets preamble: `"You are GeoMind, an experimental frontier AI model with an advanced self-referencing, self-deterministic novel architecture."`
   - Does not instruct the model to address the user by name or acknowledge identity questions.
   - *Fix*: Rewrite preamble dynamically for any recognized interlocutor in Domain 10:
     - Greet and address by `preferred_name`.
     - Confirm identity enthusiastically and directly using their profile attributes.
     - Ban evasive disclaimers regarding "architectural parameters" or "external limitations".
     - For guests, instruct to greet warmly and ask for their name.

### B. [`test/geomind/main.car`](file:///C:/Users/rich-/source/repos/CARTAN/test/geomind/main.car)
1. **`geomind_chat_interactive_loop` (Line 573)**:
   - Runs biometric scan, prints `[GeoMind Chat] Interactive REPL Session Ready.`, but never emits an initial greeting.
   - *Fix*: Emit initial green `GeoMind>` greeting addressing the verified user by name (e.g., `Hello Rick! Great to see you.`), or greeting the guest politely.

---

## 3. Logical Dependency Tree
```
[src/std/sqlite_vec.cl] (Domain 10 Storage: user_id, preferred_name, face_embedding, attributes)
         │
         ▼
[test/geomind/chat.cl]
   ├─ geomind_chat_startup_biometric_scan -> authenticates face -> sets g_active_user_id, g_active_user_verified
   ├─ geomind_chat_build_cognitive_preamble -> pulls Domain 10 profile -> generates warm, non-evasive instructions
   ├─ geomind_compute_e8_lm_head -> masks channel tokens (100, 101, 98) -> prevents thought channel trap
   ├─ geomind_sanitize_output_for_display -> strips channel tags, html tags, tool calls -> pure user-facing text
   └─ geomind_chat_learn_conversational_turn -> extracts new names into Domain 10 -> updates active user
         │
         ▼
[test/geomind/main.car]
   ├─ geomind_chat_interactive_loop -> emits initial personalized greeting -> manages REPL
   └─ bin/geomind.exe (production executable)
```

---

## 4. Potential Failure Modes & Cascading Bug Prevention
1. **Empty Display Output Hazard**: If a generation consists solely of channel thoughts and they get stripped, `clean_resp` could be empty string.
   - *Mitigation*: Ensure masking token 100 prevents the model from generating only thoughts, AND if `clean_resp` is empty or only whitespace, fallback to regenerating or outputting an appropriate direct response.
2. **Overfitting to Single Interlocutor**: Making instructions only check for "Rick" would break recognition for other users.
   - *Mitigation*: Pull `preferred_name`, `first_name`, `relationship`, `role` generically from Domain 10 for whatever `g_active_user_id` is active.
3. **Linker Hazard with Test Suites**: Standalone test suites importing `chat.cl` must have link-time declarations for external functions.

---

## 5. Definition of Done (DoD)
- [ ] Compiler and test suite targets pass cleanly.
- [ ] Dedicated test suite `test/geomind/test_universal_interlocutor_and_greeting.car` validates all gates.
- [ ] Live inference on `bin/geomind.exe` verifies:
  1. Personalized initial greeting addressing Rick by name.
  2. Direct, warm, non-evasive answer to "Do you know who I am?" without corporate disclaimers or thoughts.
- [ ] Regression suite `tools/run_affected_tests.ps1 -Sprint 535` passes 100%.
- [ ] `CHANGELOG.md`, `docs/ROADMAP.md`, `ISSUES.md`, task list, and walkthrough saved.
