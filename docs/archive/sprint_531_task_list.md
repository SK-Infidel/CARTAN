# Sprint 531 Task List: Agentic Tool Execution Engine (File System & Command-Line Operations)

- [x] **1. Tool Runtime Primitives (`test/geomind/chat.cl`)**
  - [x] Implement `geomind_tool_read_file(path: string) -> string` with existence check and genuine file reading.
  - [x] Implement `geomind_tool_write_file(path: string, content: string) -> string` with genuine file writing and verification.
  - [x] Implement `geomind_tool_exec_command(cmd: string) -> string` with security permission validation (`root` check), scratch redirection (`scratch/tool_cmd_out.tmp`), process execution via `cartan_system`, output reading, and scratch cleanup.
  - [x] Implement `geomind_tool_list_dir(path: string) -> string` with path validation and genuine directory listing.
  - [x] Implement `geomind_tool_file_exists(path: string) -> string`.
  - [x] Implement unified tool dispatcher `geomind_tool_execute(tool_name: string, arg1: string, arg2: string) -> string`.

- [x] **2. System Instruction Preamble Registration (`test/geomind/chat.cl`)**
  - [x] Update `geomind_chat_build_cognitive_preamble` to expose tool specifications, parameters, and invocation syntax to the attention heads.

- [x] **3. Reactive Agentic Decode Loop (`test/geomind/chat.cl`)**
  - [x] Detect `<tool_call...` syntax in autoregressive generation stream.
  - [x] Parse tool call, execute genuine operation via `geomind_tool_execute`.
  - [x] Format `<tool_response>` block, feed into KV cache via `geomind_execute_manifold_decode_step`, and resume generation seamlessly.

- [x] **4. Interactive REPL Slash Commands (`test/geomind/main.car`)**
  - [x] Implement `/read <path>`, `/write <path> <content>`, `/exec <cmd>`, and `/ls [path]` handlers in `geomind_chat_interactive_loop`.

- [x] **5. Build, Benchmarks & Regression Suite**
  - [x] Rebuild `bin/geomind.exe` with `cartanc.exe`.
  - [x] Add preset 531 to `tools/run_affected_tests.ps1`.
  - [x] Verify live file reading, writing, and command execution.
  - [x] Run regression suite (16/16 PASS).

- [x] **6. Review, Documentation & Closure**
  - [x] Close `[ISSUE-389]` in `ISSUES.md`.
  - [x] Update `CHANGELOG.md` to `[8.487.0]`.
  - [x] Update Phase 25 in `docs/ROADMAP.md`.
  - [x] Save walkthrough to `docs/archive/sprint_531_walkthrough.md`.
