# Sprint 543 Plan: Standard Library Promotion (JSON, Process & XML) & Orphan Cleanup

## 1. Goal
Promote general-purpose JSON parsing/serialization, sandboxed process execution, and lightweight XML extraction into canonical CARTAN standard libraries, eliminating duplicate private routines in `Projects/geomind/` and pruning orphaned technical debt.

## 2. Scope & Deliverables
1. **[`src/std/json.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/json.cl)**:
   - `json_get_string(json_str: string, key: string) -> string` (with escape resolution)
   - `json_get_float(json_str: string, key: string, default_val: float) -> float`
   - `json_get_bool(json_str: string, key: string) -> float`
   - `json_get_array(json_str: string, key: string) -> string`
   - `json_parse_float_array(array_str: string, default_val: float) -> ptr` (returns `cartan_vec`)
   - `json_parse_string_array(array_str: string) -> ptr` (returns `cartan_tree` string list)
   - `json_escape_string(s: string) -> string`
2. **[`src/std/process.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/process.cl)**:
   - `process_exec(cmd: string) -> string`: Shell execution with captured output and exit code.
   - `process_exec_to_file(cmd: string, out_path: string) -> float`: Execution with stdout redirection.
   - `process_is_path_safe(path: string, allowed_root: string) -> float`: Traversal guard (`..` rejection).
3. **[`src/std/xml.cl`](file:///C:/Users/rich-/source/repos/CARTAN/src/std/xml.cl)**:
   - `xml_extract_attribute(tag_header: string, attr_name: string) -> string`
   - `xml_extract_tag_body(tag_str: string) -> string`
   - `xml_extract_tag_body_by_name(xml_str: string, tag_name: string) -> string`
4. **Orphan Cleanup**:
   - Remove `Projects/geomind/geom.cl`.
5. **Consumer Refactoring**:
   - Refactor [`Projects/geomind/chat.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/chat.cl) to import `src/std/json.cl`, `src/std/process.cl`, and `src/std/xml.cl`.
   - Refactor [`Projects/geomind/train.cl`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/train.cl) to delegate manifest parsing to `src/std/json.cl`.
6. **Regression Verification**:
   - Author [`Projects/geomind/Testing-scratch/test_stdlib_json_process_xml.car`](file:///C:/Users/rich-/source/repos/CARTAN/Projects/geomind/Testing-scratch/test_stdlib_json_process_xml.car) (Target 90).
   - Register in `tools/run_affected_tests.ps1` under Preset 543.
   - Recompile `bin/geomind.exe` and verify zero regressions.
