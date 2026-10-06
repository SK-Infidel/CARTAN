# Sprint 532 Plan: Agentic Web Browsing, Link Traversal & Screen OCR Text Recognition

## 1. Goal
Equip GeoMind with autonomous agentic web browsing capabilities (page retrieval, content parsing, link extraction, and link following) and on-screen text recognition (desktop GDI frame acquisition + Windows WinRT hardware-accelerated OCR), fully integrated into both the autoregressive decoding loop and the interactive REPL.

## 2. Scope & Technical Architecture

### Component 1: Screen OCR Tool (`tools/read_screen_ocr.exe`)
- Written in C# (`tools/read_screen_ocr.cs`) and compiled using built-in Windows .NET `csc.exe`.
- Attaches to `winsta0\default` interactive window station.
- Captures primary screen using Win32 GDI `GetDC`, `CreateCompatibleBitmap`, `BitBlt(SRCCOPY)`.
- Passes in-memory frame to `Windows.Media.Ocr.OcrEngine`.
- Formats recognized text line-by-line to stdout with clean exit codes.

### Component 2: Web Browsing & Link Extraction (`test/geomind/chat.cl`)
- `geomind_tool_browse_web(url: string) -> string`:
  - Enforces SSRF guardrails (blocks private IP ranges `127.0.0.1`, `localhost`, `10.*`, `192.168.*`, `172.16.*` for non-root).
  - Fetches page via `curl.exe -s -L -A "Mozilla/5.0 ..."` into `scratch/web_cache.html`.
  - Extracts `<title>`.
  - Strips `<script>`, `<style>`, `<svg>`, `<head>`, and comments.
  - Strips HTML markup tags while retaining paragraph and list structure.
  - Decodes HTML entities (`&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`, `&nbsp;`).
  - Extracts hyperlinks `<a href="...">text</a>`, resolves relative paths against base URL, and formats an enumerated followable link registry.
  - Returns structured markdown view capped at 3,500 characters.

### Component 3: Screen Reading Primitive (`test/geomind/chat.cl`)
- `geomind_tool_read_screen() -> string`:
  - Invokes `tools/read_screen_ocr.exe` via `geomind_internal_exec_to_scratch`.
  - Reads output and wraps in structured result block.
  - Enforces verified interlocutor permission checks.

### Component 4: Unified Tool Dispatcher & Cognitive Preamble (`test/geomind/chat.cl`)
- Register `browse_web(url)` and `read_screen()` in `geomind_tool_execute`.
- Add XML tag matching: `<tool_call:browse_web url="..."/>` and `<tool_call:read_screen/>`.
- Register tool signatures in `geomind_chat_build_cognitive_preamble`.

### Component 5: Interactive REPL Commands (`test/geomind/main.car`)
- `/browse <url>`: fetches and displays web page with followable links.
- `/screen`: captures active desktop and prints recognized text.
- Update `/help` dialog.

### Component 6: Empirical Verification & Regression Testing
- Create `test/geomind/test_agentic_web_and_screen.car` covering:
  - Phase 1: Screen OCR execution & text extraction.
  - Phase 2: Live Web page retrieval & title extraction.
  - Phase 3: HTML entity decoding & tag stripping.
  - Phase 4: Hyperlink extraction & relative URL resolution.
  - Phase 5: SSRF security sandboxing.
  - Phase 6: Reactive tag dispatch `<tool_call:browse_web>` and `<tool_call:read_screen/>`.
- Rebuild `bin/geomind.exe`.
- Run regression suite (`tools/run_affected_tests.ps1 -Sprint 532`).
