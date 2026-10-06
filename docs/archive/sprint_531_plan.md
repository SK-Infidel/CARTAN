# Sprint 531 Plan: Agentic Tool Execution Engine (File System & Command-Line Operations)

**Sprint**: 531  
**Target Version**: `8.487.0`  
**Primary Issue**: [`[ISSUE-389]`](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md)  
**Goal**: Equip GeoMind with native tool execution capabilities to access the file system, read/write files, and execute command-line operations with real stdout/stderr capture, bound to a reactive agentic decode loop and interactive REPL commands.

---

## 1. Architecture & Design

### 1.1 Tool Runtime Primitives (`test/geomind/chat.cl`)
Implement bare-metal tool functions leveraging CARTAN runtime primitives:
1. `geomind_tool_read_file(path: string) -> string`:
   - Checks file existence with `cartan_file_exists`.
   - Reads file contents using `cartan_read_file`.
   - Returns content or clear error string.
2. `geomind_tool_write_file(path: string, content: string) -> string`:
   - Writes content to target file using `cartan_write_file`.
   - Returns byte count confirmation or error string.
3. `geomind_tool_exec_command(cmd: string) -> string`:
   - Enforces user permission verification (`permission_tier == 'root'` for unrestricted execution).
   - Redirects command output to temporary scratch file: `cmd > scratch/tool_cmd_out.tmp 2>&1`.
   - Executes via `cartan_system(full_cmd)`.
   - Reads captured output via `cartan_read_file` and deletes temporary scratch file with `remove()`.
4. `geomind_tool_list_dir(path: string) -> string`:
   - Executes `dir /B "<path>"` via `geomind_tool_exec_command`.
5. `geomind_tool_file_exists(path: string) -> string`:
   - Checks existence and returns `"true"` or `"false"`.

### 1.2 Tool Calling Syntax & Preamble Registration
In `geomind_chat_build_cognitive_preamble`:
- Append system tool definitions to the instruction prefix:
  ```text
  [Available Tools:
   - read_file(path): Read file contents. Syntax: <tool_call:read_file path="..."/>
   - write_file(path, content): Write content to file. Syntax: <tool_call:write_file path="...">CONTENT</tool_call:write_file>
   - exec_command(cmd): Execute shell command. Syntax: <tool_call:exec_command cmd="..."/>
   - list_dir(path): List directory contents. Syntax: <tool_call:list_dir path="..."/>
  ]
  ```

### 1.3 Reactive Agentic Tool Loop in Decode
In `geomind_chat_generate_reply_multimodal`:
- When the decode loop detects a closing `</tool_call>` or `/>` for a tool tag:
  1. Parse tool name and parameters.
  2. Execute genuine tool function.
  3. Format output: `\n<tool_response>\n[output]\n</tool_response>\n`.
  4. Append tool response to sequence history / KV cache.
  5. Continue generation so the model incorporates tool output into its response.

### 1.4 Interactive REPL Slash Commands (`test/geomind/main.car`)
Support direct manual tool execution in interactive REPL:
- `/read <path>`: Read and print file contents.
- `/write <path> <content>`: Write content to file.
- `/exec <cmd>`: Execute command and display output.
- `/ls [path]`: List directory contents.

---

## 2. Verification Criteria
1. **File Operations**: Genuine reading and writing of physical files on disk without placeholders or mocks.
2. **Command Execution**: Real command-line execution (`dir`, `git status`, `python --version`) with stdout/stderr capture.
3. **Reactive Agentic Generation**: Model invokes tool during prompt generation, receives genuine `<tool_response>`, and completes answer.
4. **Compiler Suite**: 16/16 compiler regression suite targets PASS in `tools/run_affected_tests.ps1 -Sprint 531`.
