# Startup Code Review: Sprint 542 — Standard Library Promotion: Pure Native String Enhancements, ANSI Terminal & HTML Processing Modules

## Executive Summary & Sprint Goal
The goal of Sprint 542 is to promote high-utility, general-purpose modules developed and hardened inside `Projects/geomind/` directly into the CARTAN standard library (`src/std/`). 
Specifically:
1. **`src/std/string.cl`**: Expand with essential missing native string algorithms (`string_trim`, `string_char_to_lower`, `string_index_of`, `string_index_of_offset`, `string_index_of_ignore_case`, `string_index_of_offset_ignore_case`, and `string_starts_with_offset`).
2. **`src/std/terminal.cl`**: Establish standard terminal ANSI coloring, cursor control, in-place line rewriting (`\e[2K\r`), animated Braille & ASCII spinners, and non-blocking CRT keyboard polling (`terminal_kbhit`, `terminal_getch`).
3. **`src/std/html.cl`**: Establish standard web text extraction, HTML entity decoding (`html_decode_entities`), tag stripping (`html_strip_tags`), tag block excision (`html_remove_tag_block`), page title parsing (`html_extract_title`), link extraction (`html_extract_links`), relative-to-absolute URL resolution (`url_resolve`), and SSRF security validation (`url_is_ssrf_blacklisted`).
4. **Refactor `Projects/geomind/chat.cl`**: Refactor GeoMind to import and consume the new standard libraries rather than duplicating private implementations.
5. **Empirical Regression Target**: Create `Projects/geomind/Testing-scratch/test_stdlib_string_terminal_html.car` (Target 89) and verify 100% pass across affected targets.

---

## Logical Dependency Tree

```
┌────────────────────────────────────────────────────────┐
│                   Compiler Core                        │
│ (cartanc.exe: LLVM IR Codegen, String Escapes, ABI)    │
└───────────────────────────┬────────────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
  ┌───────────────────┐           ┌───────────────────┐
  │ src/std/math.cl   │           │src/std/constants  │
  └─────────┬─────────┘           └─────────┬─────────┘
            │                               │
            └───────────────┬───────────────┘
                            │
                            ▼
                  ┌───────────────────┐
                  │ src/std/string.cl │ <── (Expanded in Sprint 542)
                  └─────────┬─────────┘
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
  ┌───────────────────┐           ┌───────────────────┐
  │src/std/terminal.cl│           │  src/std/html.cl  │
  │ (New in Sprint 542│           │(New in Sprint 542)│
  └─────────┬─────────┘           └─────────┬─────────┘
            │                               │
            └───────────────┬───────────────┘
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
┌───────────────────────────────┐ ┌──────────────────────────────────────┐
│   Projects/geomind/chat.cl    │ │Projects/geomind/Testing-scratch/     │
│ (Refactored to stdlib modules)│ │test_stdlib_string_terminal_html.car  │
└───────────────────────────────┘ └──────────────────────────────────────┘
```

---

## Audit & Code Inspection Findings

1. **`src/std/string.cl` Gaps**:
   - Currently contains 118 lines implementing basic operations (`string_len`, `string_concat`, `string_starts_with`, `string_contains`, `string_replace`, `string_substring`, `string_split`, `string_ends_with`, `string_to_lower`).
   - Lacks `string_trim`, substring search by index (`index_of`), case-insensitive substring search, and offset-based searching.
   - Result: Consumer code like `chat.cl` was forced to re-implement `geomind_string_trim`, `geomind_string_index_of_offset_ignore_case`, and `geomind_char_to_lower`.
   - Resolution: Implement these natively in `src/std/string.cl` using clean pointer and byte operations.

2. **Terminal ANSI & Interactive UI (`src/std/terminal.cl`)**:
   - Currently, CARTAN has compiler support for `\e` and `\E` escape sequences (Sprint 534) and CRT `_kbhit`/`_getch` ABI lowering (Sprint 533), but no standard library module encapsulates them.
   - Resolution: Create `src/std/terminal.cl` with global color toggle state (`terminal_set_color_enabled`), color codes, line erasure, spinner frame generators, and non-blocking key polling.

3. **HTML & Web Content Processing (`src/std/html.cl`)**:
   - Currently, CARTAN provides `src/std/http.cl` to make HTTP GET/POST requests, but has no standard utility to clean or extract information from the returned HTML markup.
   - Resolution: Create `src/std/html.cl` encapsulating entity decoding, tag stripping, link extraction, URL resolution, and SSRF security checking.

4. **Zero-Mock & Zero-Simulation Compliance**:
   - All string searches, entity replacements, URL resolutions, and ANSI styling must execute genuine character-by-character parsing and memory management with zero mocked behavior.

---

## Issue Registration: `[ISSUE-400]`

- **Title**: Standard Library Promotion: Pure Native String Enhancements, ANSI Terminal & HTML Processing Modules
- **Severity**: Medium (Standard Library Completeness, Reusability & Code Deduplication)
- **Component**: `src/std/string.cl`, `src/std/terminal.cl`, `src/std/html.cl`, `Projects/geomind/chat.cl`, `Projects/geomind/Testing-scratch/test_stdlib_string_terminal_html.car`
- **Description**: High-utility general-purpose functionality (string trimming, case-insensitive substring searching, ANSI terminal formatting, ASCII/braille spinners, non-blocking keyboard polling, HTML entity decoding, tag stripping, link extraction, relative URL resolution, and SSRF security filtering) was privately implemented inside `Projects/geomind/chat.cl`. Promoting these into clean, decoupled CARTAN standard library modules eliminates code duplication, provides foundational capabilities for all CARTAN developers, and strengthens self-hosting ecosystem capabilities.
