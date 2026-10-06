# Sprint 532 Walkthrough: Agentic Web Browsing & Desktop Screen OCR Perceptual Engine

## 1. Overview
In Sprint 532, we expanded GeoMind's agentic multimodal architecture with two foundational real-world perceptual capabilities:
1. **Agentic Web Browsing & Hyperlink Traversal**: The capability to query public web URLs, parse HTML documents, strip markup and scripts, decode HTML entities, extract hyperlinks, resolve relative paths against base URLs, and format followable link registries so the model can navigate the web.
2. **Desktop Screen OCR Text Recognition**: The capability to inspect the active Windows desktop display in real time, capturing screen frames via Win32 GDI and extracting on-screen text lines via hardware-accelerated WinRT `Windows.Media.Ocr.OcrEngine`.

All operations adhere to the **Strict Zero-Mock Rule**—every test and inference pass performs real network requests via `curl.exe` and genuine Windows API screen capture and OCR.

---

## 2. Architecture & Technical Implementation

### A. Screen Capture & WinRT OCR Utility (`tools/read_screen_ocr.cs` & `tools/read_screen_ocr.exe`)
- **Compilation**: Built using .NET Framework 4.8 `csc.exe` referencing the Windows 10 SDK unified contract `Windows.winmd` (`10.0.22621.0`).
- **Session & Desktop Attachment**: P/Invokes `OpenWindowStation("winsta0")`, `SetProcessWindowStation`, `OpenDesktop("default")`, and `SetThreadDesktop` to grant reliable interactive display access across both console and background sessions.
- **DPI Scaling Awareness**: Calls `SetProcessDPIAware()` to disable GDI bitmap virtualization blur, ensuring pixel-crisp font rendering for the OCR engine.
- **GDI Lifecycle**: Explicitly tracks device contexts to delete `CreateDC("DISPLAY")` with `DeleteDC` and release `GetDC(IntPtr.Zero)` with `ReleaseDC`, preventing GDI object leaks.
- **Hardware-Accelerated OCR**: Pipes captured bitmaps into WinRT `Windows.Graphics.Imaging.BitmapDecoder` and `Windows.Media.Ocr.OcrEngine`, extracting text lines across the 1536x960 desktop in under 0.4 seconds.

### B. HTML Parsing & Link Extraction Engine (`test/geomind/chat.cl`)
- `geomind_html_decode_entities(html: string) -> string`: Decodes standard named entities (`&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`, `&nbsp;`) and decimal numeric entities.
- `geomind_url_resolve(base_url: string, href: string) -> string`: Resolves relative URLs (absolute `http[s]://`, scheme-relative `//`, root-relative `/`, and directory-relative paths).
- `geomind_html_remove_tag_block(html, open_tag, close_tag)`: Purges `<script>`, `<style>`, `<svg>`, `<head>`, and `<!-- -->` comment blocks.
- `geomind_html_extract_title(html: string) -> string`: Extracts `<title>` tag content.
- `geomind_html_strip_tags(html: string) -> string`: Linear $O(N)$ tag stripper with paragraph/header/list newline formatting and explicit heap duplication (`cartan_string_concat(raw_res, "")`) before freeing the scaffold buffer, permanently preventing use-after-free corruption.
- `geomind_html_extract_links(html: string, base_url: string, max_links: float) -> string`: Discovers `<a href="...">` anchor tags, extracts and cleans link labels, resolves targets against `base_url`, and constructs an enumerated followable link registry.

### C. Security Sandboxing
- **SSRF Protection (`geomind_is_ssrf_blacklisted`)**: Blocks non-root interlocutors from issuing requests to private or loopback subnets (`localhost`, `127.*`, `10.*`, `192.168.*`, `172.16-31.*`, `169.254.*`, `0.0.0.0`, `[::1]`).
- **Biometric Perceptual Sandboxing**: Desktop screen capture strictly requires verified biometric authentication (`g_active_user_verified == 1.0`).

### D. Tool Dispatch & REPL Slash Commands
- **Tool Dispatcher (`geomind_parse_and_dispatch_tool_call`)**:
  - Handles XML tags (`<tool_call:browse_web url="..."/>`, `<tool_call:read_screen/>`) and JSON schemas.
  - Expanded response truncation ceiling from 2,000 to 3,500 characters for rich web content.
- **Interactive REPL (`test/geomind/main.car`)**:
  - Added `/browse <url>` and `/screen` commands to the interactive REPL loop with `/help` documentation.

---

## 3. Empirical Verification Results

### 1. Dedicated Verification Suite (`test/geomind/test_agentic_web_and_screen.car`)
Compiled and executed natively via `./cartanc.exe`:
- **Phase 1 (Screen OCR Execution & Sandboxing)**:
  - `[PASS]` `geomind_tool_read_screen` captures desktop successfully.
  - `[PASS]` Extracted authentic on-screen text (>50 chars).
  - `[PASS]` Guest screen capture blocked without biometric authentication.
- **Phase 2 (HTML Entity Decoding & Tag Stripping)**:
  - `[PASS]` Named entities decoded correctly (`& < > " '`).
  - `[PASS]` `<title>` extracted cleanly (`Test Page`).
  - `[PASS]` CSS style blocks excluded from stripped text.
  - `[PASS]` Main title preserved.
  - `[PASS]` Paragraph text preserved with inline tags stripped.
- **Phase 3 (URL Resolution & Link Extraction)**:
  - `[PASS]` Directory-relative URL resolved (`https://example.com/docs/guide.html`).
  - `[PASS]` Root-relative URL resolved (`https://example.com/about`).
  - `[PASS]` Absolute URL preserved (`https://other.com/api`).
  - `[PASS]` Followable links correctly resolved and formatted.
- **Phase 4 (SSRF Security Sandboxing)**:
  - `[PASS]` `localhost`, `127.*`, `192.168.*`, `10.*`, `169.254.*` flagged.
  - `[PASS]` Public URL `example.com` permitted.
  - `[PASS]` Guest SSRF attempt rejected with permission error.
- **Phase 5 (Live Web Browsing)**:
  - `[PASS]` Real HTTP wire request to CERN (`http://info.cern.ch`) containing `'first website'`.
  - `[PASS]` Followable links section extracted and formatted.
  - `[PASS]` Genuine link to `TheProject.html` indexed.
  - `[PASS]` Temporary cache file `scratch/web_cache.html` unlinked cleanly.
- **Phase 6 (Agentic Tool Tag Parsing & Dispatch)**:
  - `[PASS]` `<tool_call:read_screen/>` dispatches and formats `<tool_response>` block.
  - `[PASS]` `<tool_call:browse_web url="..."/>` dispatches and formats `<tool_response>` block.
  - `[PASS]` JSON schema tool call dispatches successfully.
- **Result: 21 / 21 PASS (100% Zero-Mock Verification)**.

### 2. Live Interactive REPL Verification (`bin/geomind.exe --chat`)
- Rebuilt native `bin/geomind.exe` with Clang `-O2` AVX2/FMA MSVC.
- Tested `/help`: `/browse` and `/screen` advertised in menu.
- Tested `/browse http://info.cern.ch`: Successfully retrieved and formatted the home of the first website, listing all 4 followable CERN links.
- Tested `/screen`: Biometrically verified Rick (cosine similarity 0.9670), captured active 1536x960 desktop, and accurately extracted IDE text ("CARTAN - Antigravity IDE", open files, terminal text) via WinRT OCR.

### 3. Compiler Regression Suite
- Executed `tools/run_affected_tests.ps1 -Sprint 532`:
  - 16/16 affected targets passed cleanly in 111.67s with 0 regressions.
