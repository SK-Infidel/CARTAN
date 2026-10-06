# Startup Code Review: Sprint 532 (Agentic Web Browsing, Link Traversal & Screen OCR Text Recognition)

## 1. Context & Objectives
- **Interlocutor**: Rick (Richard Weber).
- **Goal**: Implement authentic web browsing with hyperlink extraction/following and real-time on-screen text recognition (OCR) for GeoMind.
- **Strict Invariants**:
  - **Zero-Mock Rule**: Absolutely no placeholder, simulated, or mocked responses. All HTTP queries must hit live networks via `curl.exe` with real HTML parsing. All screen text must be acquired via genuine Win32 GDI desktop capture and authentic WinRT `Windows.Media.Ocr.OcrEngine` hardware-accelerated OCR.
  - **Security Sandboxing**: Non-root interlocutors restricted from accessing local intranet addresses (`localhost`, `127.0.0.1`, `10.*`, `192.168.*`, `172.16.*`) and restricted from screen capture if not authenticated.
  - **KV Cache / Context Safety**: Web pages and OCR dumps capped at 3,500 characters to prevent context buffer saturation while providing maximum semantic density.

## 2. Logical Dependency Tree
```
[User Request: Web Browsing & Screen Reading]
       │
       ├──> [tools/read_screen_ocr.exe] (Win32 GDI + WinRT OcrEngine)
       │         │
       │         └──> geomind_tool_read_screen() [test/geomind/chat.cl]
       │
       ├──> [curl.exe / OS Network Stack]
       │         │
       │         └──> geomind_tool_browse_web() [test/geomind/chat.cl]
       │                   ├── HTML Sanitization & Tag Stripping
       │                   ├── Hyperlink Extraction (<a href="...">)
       │                   ├── Relative URL Resolution
       │                   └── Entity Decoding (&amp;, &lt;, &gt;, &quot;)
       │
       ├──> [Reactive Tool Dispatcher] geomind_parse_and_dispatch_tool_call()
       │         ├── <tool_call:browse_web url="..."/>
       │         └── <tool_call:read_screen/>
       │
       ├──> [Cognitive Preamble Registration] geomind_chat_build_cognitive_preamble()
       │
       ├──> [Interactive REPL] geomind_chat_interactive_loop [test/geomind/main.car]
       │         ├── /browse <url>
       │         └── /screen
       │
       └──> [Empirical Verification] test/geomind/test_agentic_web_and_screen.car
```

## 3. Discovered Technical Debt & Issues
- **[ISSUE-390]**: GeoMind has no mechanisms to browse the internet, follow hyperlinks, or observe text displayed on the user's active computer monitor.
- **HTML Bloat Hazard**: Raw HTML web pages frequently exceed 200 KB with minified JavaScript and CSS, which would instantly overflow the transformer context horizon if not cleanly parsed and filtered down to text and links.
- **Non-Interactive Desktop Station Hazard**: Win32 background processes cannot capture `GetDC(NULL)` without explicitly attaching to `winsta0\default` via `SetProcessWindowStation` and `SetThreadDesktop`. Our standalone helper `tools/read_screen_ocr.exe` solves this cleanly.
