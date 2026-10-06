# Startup Code Review: Sprint 543 - Standard Library Promotion (JSON, Process, XML) & Orphaned Geometry Cleanup

## 1. Executive Summary & Context
In accordance with user rules and architectural guidelines, Sprint 543 promotes critical system-level utilities from `Projects/geomind/` into the CARTAN standard library (`src/std/`):
- A pure-CARTAN JSON parser and serializer standard library ([`src/std/json.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/json.cl)).
- A sandboxed process execution engine ([`src/std/process.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/process.cl)).
- Fast lightweight string extraction routines in [`src/std/xml.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/xml.cl).
- Pruning the orphaned duplicate file [`Projects/geomind/geom.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/geom.cl).

---

## 2. Code Review Discoveries & Technical Debt Findings

### Finding 1: Absence of Standard JSON Library & O(N^2) Manifest Parsing
- **Location**: [`Projects/geomind/chat.cl:2417-2432`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/chat.cl#L2417) and [`Projects/geomind/train.cl:1461-1730`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/train.cl#L1461)
- **Problem**: CARTAN had no `src/std/json.cl`. Both `chat.cl` and `train.cl` implemented private substring search loops for JSON fields and arrays. In `train.cl`, loops iterated using `cartan_string_get_char`, which executes `strlen()` on every single call, degrading large manifest parsing to $O(N^2)$.
- **Solution**: Implement `src/std/json.cl` utilizing $O(N)$ linear scans via `cartan_byte_at`, supporting strings (with escape handling), floats, booleans, and arrays (parsing numeric vectors into `cartan_vec` and string vectors into lists).

### Finding 2: Monolithic Agentic Process Execution in Chat Subsystem
- **Location**: [`Projects/geomind/chat.cl:2083-2104`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/chat.cl#L2083) (`geomind_internal_exec_to_scratch`)
- **Problem**: Executing shell commands with captured stdout/stderr, non-zero exit code tagging, and scratch file unlinking was bound privately inside GeoMind's chat module. Any other CARTAN application requiring process execution would have to reinvent this logic.
- **Solution**: Create `src/std/process.cl` providing `process_exec(cmd)`, `process_exec_to_file(cmd, out_file)`, and path-traversal safety validation (`process_is_path_safe`).

### Finding 3: Heavy XML DOM vs Missing Lightweight Substring Extractors
- **Location**: [`src/std/xml.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/xml.cl) vs [`Projects/geomind/chat.cl:2384-2415`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/chat.cl#L2384)
- **Problem**: `src/std/xml.cl` only provides recursive tree-node DOM allocations (`xml_create_node`, `xml_parse_children`). Extracting a single attribute or tag body from a small slice (such as `<tool_call:NAME .../>`) forced `chat.cl` to write private string extractors.
- **Solution**: Add lightweight `xml_extract_attribute(tag, attr_name)` and `xml_extract_tag_body(tag_str)` directly to `src/std/xml.cl`.

### Finding 4: Orphaned Duplicate File `Projects/geomind/geom.cl`
- **Location**: [`Projects/geomind/geom.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/geom.cl)
- **Problem**: This file is an exact duplicate of an earlier version of [`src/std/geom.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/geom.cl). Zero files in the repository include it; all models and tests include `src/std/geom.cl` directly.
- **Solution**: Permanently remove `Projects/geomind/geom.cl`.

---

## 3. Logical Dependency Tree

```
  src/std/string.cl (Linear scans via cartan_byte_at, string_trim, string_index_of)
         │
         ├──► src/std/json.cl (json_get_string, json_get_float, json_get_bool, json_parse_float_array, json_parse_string_array)
         │           │
         │           ├──► Projects/geomind/chat.cl (Tool call parsing, JSON schema interpretation)
         │           └──► Projects/geomind/train.cl (Manifest ingestion, dataset lists, float offset arrays)
         │
         ├──► src/std/process.cl (process_exec, process_exec_to_file, process_is_path_safe)
         │           │
         │           └──► Projects/geomind/chat.cl (Tool execution: exec_command, list_dir, read_screen)
         │
         └──► src/std/xml.cl (xml_extract_attribute, xml_extract_tag_body + existing DOM tree)
                     │
                     └──► Projects/geomind/chat.cl (XML tool call tag & attribute parsing)

  Projects/geomind/Testing-scratch/test_stdlib_json_process_xml.car (Target 90)
         │
         └──► Verified by tools/run_affected_tests.ps1 -Sprint 543
```

---

## 4. Pre-Sprint Scrum Focus Areas
1. **Memory Safety**: Ensure all JSON and process strings are cleanly allocated and freed, avoiding memory leaks in long-running training loops.
2. **Escaping**: Handle escaped quotes (`\"`) and escaped newlines (`\n`) properly in JSON string extractions.
3. **Zero-Mock Integrity**: Genuine shell process execution and genuine JSON parsing only.
