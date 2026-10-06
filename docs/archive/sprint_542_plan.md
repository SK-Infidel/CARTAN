# Sprint 542 Implementation Plan: Standard Library Promotion (String, Terminal & HTML)

## Sprint Goal
Promote high-utility text processing, terminal UI, and HTML parsing capabilities into first-class CARTAN standard libraries (`src/std/string.cl`, `src/std/terminal.cl`, `src/std/html.cl`), refactor `Projects/geomind/chat.cl` to consume them, and empirically verify all functionality via a dedicated regression test suite.

---

## Architecture & Module Specifications

### 1. `src/std/string.cl` Enhancements
Add the following native string manipulation functions:
- `string_char_to_lower(c: float) -> float`: ASCII lowercase converter.
- `string_trim(s: string) -> string`: Pure native string trimming removing leading and trailing spaces (32), tabs (9), newlines (10), and carriage returns (13).
- `string_index_of(haystack: string, needle: string) -> float`: Returns 0-based offset or -1.0.
- `string_index_of_offset(haystack: string, needle: string, start_offset: float) -> float`: Substring search starting at specific offset.
- `string_index_of_ignore_case(haystack: string, needle: string) -> float`: Case-insensitive substring search.
- `string_index_of_offset_ignore_case(haystack: string, needle: string, start_offset: float) -> float`: Case-insensitive search starting at specific offset.
- `string_starts_with_offset(haystack: string, needle: string, offset: float) -> float`: Prefix check starting at offset without allocating substrings.

### 2. `src/std/terminal.cl` (New Standard Library Module)
- Global color state: `var g_terminal_color_enabled: float = 1.0;`
- Toggles: `terminal_set_color_enabled(flag: float)`, `terminal_get_color_enabled() -> float`
- ANSI Escapes:
  - `terminal_ansi_esc() -> string`
  - `terminal_col_reset() -> string` (`\e[0m`)
  - `terminal_col_bold() -> string` (`\e[1m`), `terminal_col_dim() -> string` (`\e[2m`)
  - `terminal_col_green() -> string` (`\e[1;32m`), `terminal_col_cyan() -> string` (`\e[1;36m`), `terminal_col_yellow() -> string` (`\e[1;33m`), `terminal_col_amber() -> string` (`\e[33m`), `terminal_col_magenta() -> string` (`\e[1;35m`), `terminal_col_red() -> string` (`\e[1;31m`), `terminal_col_gray() -> string` (`\e[90m`), `terminal_col_blue() -> string` (`\e[1;34m`)
  - `terminal_erase_line() -> string` (`\e[2K\r` when color enabled, spaces fallback)
- Animation:
  - `terminal_spinner_braille(idx: float) -> string` (10-frame braille sequence)
  - `terminal_spinner_ascii(idx: float) -> string` (4-frame `| / - \` sequence)
- CRT Non-blocking Polling:
  - `terminal_kbhit() -> float` (wraps compiler builtin `_kbhit()`)
  - `terminal_getch() -> float` (wraps compiler builtin `_getch()`)

### 3. `src/std/html.cl` (New Standard Library Module)
- `html_decode_entities(text: string) -> string`: Decodes `&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`, `&apos;`, `&nbsp;`, `&mdash;`, `&ndash;`.
- `html_strip_tags(html: string) -> string`: Converts HTML documents to clean plaintext, adding newlines for block elements (`<p>`, `<div>`, `<br>`, `<h1>`-`<h3>`, `<li>`).
- `html_remove_tag_block(html: string, open_tag: string, close_tag: string) -> string`: Excises `<script>...</script>` and `<style>...</style>` blocks.
- `html_extract_title(html: string) -> string`: Extracts decoded page title.
- `html_extract_links(html: string, base_url: string, max_links: float) -> string`: Parses `<a href="...">` links and resolves relative targets.
- `url_resolve(base_url: string, link_url: string) -> string`: Resolves protocol-relative, absolute-path, and relative-directory URLs against a base URL.
- `url_is_ssrf_blacklisted(url: string) -> float`: Validates whether a URL targets loopback (`127.*`, `localhost`, `[::1]`) or private IP ranges (`10.*`, `172.16-31.*`, `192.168.*`, `169.254.*`).

### 4. Consumer Integration: `Projects/geomind/chat.cl`
- Include `src/std/terminal.cl` and `src/std/html.cl`.
- Re-wire `geomind_col_*`, `geomind_get_spinner_*`, `geomind_html_*`, and string helpers to delegate cleanly to standard library functions.
- Verify zero regressions and identical behavior.

### 5. Empirical Verification Suite: Target 89
- Author `Projects/geomind/Testing-scratch/test_stdlib_string_terminal_html.car`.
- Register Target 89 in `tools/run_affected_tests.ps1`.
- Execute test runner preset `542` and verify 100% PASS rate.
