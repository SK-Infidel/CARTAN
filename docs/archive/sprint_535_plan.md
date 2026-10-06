# Sprint 535 Plan: Universal Interlocutor Recognition & Dynamic Greeting, Channel Thought Suppression & Natural Persona Alignment

## 1. Sprint Goal
Enable universal interlocutor recognition across all users (Rick, registered users, and onboarding guests) with dynamic personalized greetings by name, realign the cognitive preamble to eliminate evasive architectural disclaimers, and suppress raw channel thought leakage (`<|channel>thought ... </body></html>`) to deliver authentic, direct dialogue.

---

## 2. Squad Responsibilities

### Compiler Core Squad Lead (`cartan_compiler_engineer`)
- Ensure token masking and string operations compile natively in CARTAN.
- Ensure ABI and memory safety across string concatenation and pattern matching.

### Architecture & Geometry Lead (`cartan_architect`)
- Design universal cognitive preamble formatting for Domain 10 interlocutors.
- Formulate clear directives ensuring direct, warm responses without safety refusal triggers.

### Runtime & Hardware Lead (`cartan_runtime_engineer`)
- Implement LM head logit masking for channel control tokens (`100.0`, `101.0`, `98.0`) in `geomind_compute_e8_lm_head`.
- Implement robust protocol tag and HTML channel sanitization in `geomind_sanitize_output_for_display`.
- Implement dynamic session greeting in `geomind_chat_interactive_loop`.

### QA & Benchmark Squad Lead (`cartan_qa_tester`)
- Build dedicated 5-gate test suite `test/geomind/test_universal_interlocutor_and_greeting.car`.
- Verify live prompt inference and REPL session on native `bin/geomind.exe`.
- Execute compiler regression suite via `tools/run_affected_tests.ps1 -Sprint 535`.

---

## 3. Implementation Steps

1. **LM Head Channel Token Masking (`test/geomind/chat.cl`)**:
   - Mask token `100.0` (`<|channel>`), `101.0` (`<channel|>`), and `98.0` (`<|think|>`) in `geomind_compute_e8_lm_head`.

2. **Output Sanitization & Tag Stripping (`test/geomind/chat.cl`)**:
   - Enhance `geomind_sanitize_output_for_display` to strip `<|channel>thought` blocks, `</body></html>`, `<|think|>`, etc.

3. **Cognitive Preamble Persona Realignment (`test/geomind/chat.cl`)**:
   - Overhaul `geomind_chat_build_cognitive_preamble` to dynamically prime GeoMind with the active interlocutor's preferred name, role, and relationship from Domain 10.
   - Instruct GeoMind to address them by name and directly answer identity inquiries.

4. **Dynamic REPL Greeting (`test/geomind/main.car`)**:
   - In `geomind_chat_interactive_loop`, emit an initial personalized green greeting upon biometric identification.

5. **Empirical Verification**:
   - Compile and execute `test/geomind/test_universal_interlocutor_and_greeting.car`.
   - Rebuild `bin/geomind.exe` and test live prompt.
   - Run affected tests preset 535.
