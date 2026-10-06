# Sprint 532 Task List: Agentic Web Browsing, Link Traversal & Screen OCR Text Recognition

- [x] **1. Screen Capture & WinRT OCR Utility (`tools/read_screen_ocr.cs`)**
  - [x] Write `tools/read_screen_ocr.cs` with GDI screen capture, `winsta0\default` attachment, and `Windows.Media.Ocr.OcrEngine`.
  - [x] Compile to `tools/read_screen_ocr.exe` using `csc.exe`.
  - [x] Verify standalone execution and on-screen text extraction.

- [x] **2. Web Browsing & HTML Parsing Engine (`test/geomind/chat.cl`)**
  - [x] Implement `geomind_tool_browse_web(url: string) -> string`.
  - [x] Implement HTML tag stripping, `<script>`/`<style>` removal, and entity decoding.
  - [x] Implement `<a href="...">` link extraction and relative URL resolution.
  - [x] Implement SSRF sandboxing for non-root users.

- [x] **3. Screen Reading Primitive (`test/geomind/chat.cl`)**
  - [x] Implement `geomind_tool_read_screen() -> string` interfacing with `tools/read_screen_ocr.exe`.
  - [x] Enforce interlocutor verification checks.

- [x] **4. Tool Dispatcher & Cognitive Preamble (`test/geomind/chat.cl`)**
  - [x] Update `geomind_tool_execute` to handle `browse_web` and `read_screen`.
  - [x] Update `geomind_parse_and_dispatch_tool_call` for `<tool_call:browse_web>` and `<tool_call:read_screen/>`.
  - [x] Update `geomind_chat_build_cognitive_preamble` to advertise new tools.

- [x] **5. Interactive REPL Slash Commands (`test/geomind/main.car`)**
  - [x] Implement `/browse <url>` and `/screen` in `geomind_chat_interactive_loop`.
  - [x] Update `/help` dialog.

- [x] **6. Build, Verification & Regression Testing**
  - [x] Create and run `test/geomind/test_agentic_web_and_screen.car`.
  - [x] Rebuild native `bin/geomind.exe` with `cartanc.exe`.
  - [x] Register preset 532 in `tools/run_affected_tests.ps1` and run regression suite (16/16 PASS).
  - [x] Test live autonomous prompt tool calling with web browsing and screen reading.

- [x] **7. Documentation & Closure**
  - [x] Record and close `[ISSUE-390]` in `ISSUES.md`.
  - [x] Update `CHANGELOG.md` to `[8.488.0]`.
  - [x] Update Phase 25 (Item 14) in `docs/ROADMAP.md`.
  - [x] Save walkthrough to `docs/archive/sprint_532_walkthrough.md`.
