# Startup Code Review: Sprint 531 — Agentic Tool Execution Engine

**Date**: 2026-10-05  
**Reviewer**: Antigravity / CARTAN Core Team  
**Interlocutor**: Rick (Richard Weber)  
**Focus**: File System I/O, Command-Line Subshell Execution, Security Permission Model, Autoregressive Decode Tool Interception.

---

## 1. Executive Summary & Objective

In Sprint 530, we finalized canonical interlocutor attribute discovery, normalized dynamic attributes, and bound Rick's verified profile into cognitive memory.
The primary directive for Sprint 531 is equipping GeoMind with native tool execution capabilities:
1. File System Access: Checking file existence and directory listing (`list_dir`, `file_exists`).
2. File I/O: Reading and writing files on the local filesystem (`read_file`, `write_file`).
3. Command Execution: Genuine execution of command-line operations with real stdout/stderr capture (`exec_command`).
4. Reactive Agentic Loop: Intercepting `<tool_call>` tags during token generation, executing tools without mocks, feeding `<tool_response>` back into the KV cache and autoregressive context, and continuing generation.
5. Interactive REPL Commands: Exposing direct slash commands (`/read`, `/write`, `/exec`, `/ls`) for interactive use.

---

## 2. Logical Dependency Tree

```
test/geomind/main.car (Interactive REPL & CLI Interface)
 │
 ├── test/geomind/chat.cl (High-Level Cognitive Engine)
 │    ├── [Preamble Assembly]
 │    │    └── System prompt with available tool schemas & syntax
 │    ├── [Decode Loop Interception]
 │    │    ├── <tool_call> tag parser
 │    │    ├── Tool execution dispatcher (geomind_tool_execute)
 │    │    ├── <tool_response> injection into KV cache
 │    │    └── Resumed token decode
 │    ├── [Agentic Tool Primitives]
 │    │    ├── geomind_tool_read_file
 │    │    ├── geomind_tool_write_file
 │    │    ├── geomind_tool_exec_command
 │    │    ├── geomind_tool_list_dir
 │    │    └── geomind_tool_file_exists
 │    └── [Security & Permissions]
 │         └── Domain 10 SQLite permission tier check (root vs guest)
 │
 ├── src/cartanc/core_runtime.car (Underlying C-ABI Runtime Primitives)
 │    ├── cartan_read_file(path)
 │    ├── cartan_write_file(path, content)
 │    ├── cartan_file_exists(path)
 │    ├── cartan_system(cmd)
 │    └── remove(path)
 │
 └── MSVC / Windows CRT (stdio.h, stdlib.h)
      ├── fopen, fread, fputs, fclose, ftell, fseek
      ├── system()
      └── remove()
```

---

## 3. Detailed Component Audit

### A. Core Runtime I/O Primitives (`src/cartanc/core_runtime.car`)
- `cartan_read_file(path: string) -> string`:
  - Opens binary mode `"rb"`, calculates length via `fseek` + `ftell`, allocates memory buffer, reads full content with null terminator. Returns `""` on missing file or zero size.
- `cartan_write_file(path: string, content: string) -> float`:
  - Opens `"w"`, writes via `fputs`, flushes and closes. Returns `1.0` on success, `0.0` on failure.
- `cartan_file_exists(path: string) -> float`:
  - Probes file existence via `fopen(path, "rb")`. Returns `1.0` if opened, `0.0` otherwise.
- `cartan_system(cmd: string) -> float`:
  - Wraps C runtime `system(cmd)`. Returns return code (0 for success).
- `remove(path: string) -> float`:
  - Unlinks specified file path.

### B. Shell Command Execution & Output Capture
- **Challenge**: Standard C CRT `system(cmd)` returns an integer exit code rather than capturing standard output and standard error strings.
- **Low-Entropy Solution**: In `geomind_tool_exec_command(cmd)`, redirect combined stdout/stderr to a temporary scratch file:
  ```cartan
  let scratch_file = "scratch/tool_cmd_out.tmp";
  let full_cmd = cartan_string_concat(cartan_string_concat(cmd, " > "), cartan_string_concat(scratch_file, " 2>&1"));
  let rc = cartan_system(full_cmd);
  let out_text = cartan_read_file(scratch_file);
  remove(scratch_file);
  ```
  This is 100% genuine, captures full stdout and stderr, leaves zero filesystem clutter, and requires no external process dependencies.

### C. Security Permission Enforcement
- **Domain 10 Permissions**: Interlocutor profiles stored in `test/geomind/trainingdata/cognitive_memory.db` define `permission_tier`.
- **Policy**:
  - `root`: Unrestricted execution of all tools (Rick / verified architect).
  - Non-root / guest: Allowed read operations (`read_file`, `list_dir`, `file_exists`), but restricted from executing arbitrary shell commands (`exec_command`) or writing outside `scratch/`.

### D. Autoregressive Reactive Tool Calling
- When the model generates a tool call tag (e.g. `<tool_call:exec_command cmd="git status -s"/>` or `<tool_call:read_file path="foo.txt"/>`):
  1. The decode loop catches the closing delimiter `/>` or `</tool_call>`.
  2. The tool dispatcher executes the real operation (Zero-Mock Rule: real I/O and process execution).
  3. The result is formatted: `\n<tool_response>\n[result]\n</tool_response>\n`.
  4. The response tokens are fed into the transformer KV cache sequentially via `geomind_execute_manifold_decode_step`.
  5. Decoding resumes with full contextual attention on the tool's output.

---

## 4. Issues & Technical Debt

- **[ISSUE-389]** [OPEN]: `Agentic Tool Execution Engine (File System & Command-Line Operations)`.
- **Zero-Mock Adherence**: Under no circumstances shall mock outputs or simulated outputs be returned. Genuine files and genuine system command output must be inspected.

---

## 5. Architectural Recommendations

1. Provide both inline self-terminating tags (`<tool_call:read_file path="..."/>`) and block tags (`<tool_call:write_file path="...">...</tool_call:write_file>`).
2. Implement robust string slicing helpers in `test/geomind/chat.cl` for parameter extraction.
3. Integrate REPL slash commands (`/read`, `/write`, `/exec`, `/ls`) into `test/geomind/main.car` so Rick can invoke tools manually during interactive chat.
