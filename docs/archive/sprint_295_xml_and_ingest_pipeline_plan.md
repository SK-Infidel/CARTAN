# Sprint 295 Plan: Authentic XML Parser & Data Ingestion Pipeline (`[ISSUE-044]`)

**Sprint ID**: Sprint 295  
**Component Focus**: `src/std/xml.cl`, `src/std/ingest.cl`, `src/cartanc/main.car`  
**Issue Reference**: [[ISSUE-044]](file:///C:/Users/rich-/source/repos/CARTAN/ISSUES.md#L522-L527) — Mock XML Parser and Data Ingestion Line Validators  

---

## 1. Problem Statement & Root Cause Analysis

1. **`src/std/xml.cl` (Mock XML Parser & Stringifier)**:
   - `xml_parse(xml_text: string)` only pushes `len` into a tree and returns it.
   - `xml_get_element(root: ptr, tag_name: string)` returns hardcoded `<tag/>` without reading any elements.
   - `xml_stringify(root: ptr)` prints hardcoded `<root nodes="..."></root>`.
   - Violates the Strict Zero-Mock and Zero-Simulation Rule.

2. **`src/std/ingest.cl` (Mock CSV & JSON Lines Validators)**:
   - `ingest_parse_csv_line(line: string)` only checks `len > 0` and returns `1.0`.
   - `ingest_parse_json_lines(payload: string)` only checks `len > 0` and returns `1.0`.
   - No token extraction, delimiter splitting, quote escaping, or JSON validation.

3. **Compiler Include Fallback (`src/cartanc/main.car`)**:
   - Files included as `.car` when the stdlib source is `.cl` (e.g. `../../src/std/xml.car` vs `src/std/xml.cl`) fail resolution silently.
   - Adding bidirectional `.car` <-> `.cl` extension fallback guarantees robust standard library inclusion.

---

## 2. Technical Architecture & Implementation Plan

### A. Authentic XML Parsing Engine (`src/std/xml.cl`)
1. **Tag & Content Scanner**:
   - Implement tokenizer/scanner scanning XML string:
     - Identifies opening tags `<tag attr="val">`, self-closing tags `<tag/>`, closing tags `</tag>`, text content, and comments/declarations (`<?...?>`, `<!--...-->`).
   - Extracts tag name, attribute dictionary/tokens, and inner text content.
2. **In-Memory DOM Tree (`XmlNode`)**:
   - Each XML element is represented as a structured node containing:
     - `tag_name`: string
     - `inner_text`: string
     - `attributes`: key-value pairs
     - `children`: tree of child nodes
     - `raw`: formatted element string
3. **Element Query & Extraction**:
   - `xml_get_element(root: ptr, tag_name: string) -> string`:
     - Traverses parsed DOM tree recursively/iteratively.
     - Matches `tag_name`.
     - Returns full XML fragment string (e.g., `<data>CARTAN</data>`).
   - `xml_get_text(root: ptr, tag_name: string) -> string`:
     - Returns inner text content (e.g., `"CARTAN"`).
   - `xml_get_attribute(elem_str: string, attr_name: string) -> string`:
     - Extracts attribute value from element string.
4. **Serialization (`xml_stringify`)**:
   - Reconstructs well-formed XML from parsed DOM nodes.

### B. Authentic Ingestion Engine (`src/std/ingest.cl`)
1. **Authentic CSV Parser**:
   - `ingest_parse_csv_tokens(line: string) -> ptr`:
     - Scans line character by character.
     - Respects quoted strings `"..."` (commas inside quotes do not split fields).
     - Handles escaped quotes `""`.
     - Returns tree of extracted column strings.
   - `ingest_parse_csv_line(line: string) -> float`:
     - Validates that CSV line has balanced quotes and non-empty valid fields.
     - Returns `1.0` on valid CSV line, `0.0` on malformed/empty input.
   - `ingest_csv_column_count(line: string) -> float`:
     - Returns number of parsed columns.
   - `ingest_csv_get_column(line: string, col_idx: float) -> string`:
     - Returns specific column value at `col_idx`.
2. **Authentic JSON Lines Parser**:
   - `ingest_parse_json_lines(payload: string) -> float`:
     - Splits payload by `\n`.
     - Validates each non-empty line as well-formed JSON object (`{...}`) or array (`[...]`) with balanced braces and valid string keys.
     - Returns `1.0` if valid JSON records exist and all are well-formed; returns `0.0` otherwise.
   - `ingest_json_lines_count(payload: string) -> float`:
     - Returns count of valid JSON records.
   - `ingest_json_get_field(json_line: string, key: string) -> string`:
     - Extracts the value corresponding to `key` in a JSON object.

### C. Compiler Extension Fallback (`src/cartanc/main.car`)
- In `ast_expansion_pass`, if `cartan_file_exists(path) == 0.0`, test bidirectional extension swapping (`.car` <-> `.cl`).
- Rebuild and bootstrap `cartanc.exe`.

---

## 3. Verification Criteria
1. Test Target 20 (`test_http_xml.car`): builds and passes with authentic XML parsing and element retrieval.
2. Test Target 25 (`test_collections_ingest_env.car`): builds and passes with authentic CSV line parsing.
3. Isolated test covering:
   - Nested XML tags, text retrieval, attribute extraction, self-closing tags.
   - Multi-column CSV with quotes and commas inside quotes.
   - Multi-line JSONL with key extraction.
4. Full regression suite (`scratch/run_tests.exe`): all 47 targets pass with 100% pass rate.
5. Update `ISSUES.md`, `CHANGELOG.md`, and commit to `master`.
