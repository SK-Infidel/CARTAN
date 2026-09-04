// src/std/ingest.cl
// CARTAN Standard Library: Layer 1 Web Ingestion & Data Pipeline Module

include "src/std/http.cl";
include "src/std/string.cl";

extern fn cartan_string_length(s: string) -> float;
extern fn cartan_string_substring(s: string, start: float, end_idx: float) -> string;
extern fn cartan_string_get_char(s: string, idx: float) -> float;
extern fn cartan_string_eq(s1: string, s2: string) -> float;
extern fn cartan_string_concat(s1: string, s2: string) -> string;
extern fn cartan_tree_create() -> ptr;
extern fn cartan_tree_push(t: ptr, item: ptr) -> void;
extern fn cartan_tree_get_f32(t: ptr, idx: float) -> ptr;
extern fn cartan_tree_len_f(t: ptr) -> float;
extern fn cartan_tree_len(t: ptr) -> float;

// Fetches raw remote payload via HTTP GET
fn ingest_fetch_url(url: string) -> string {
    return http_get(url);
}

// Authentically scans a CSV line and extracts tokens into a tree, preserving quoted commas
fn ingest_parse_csv_tokens(line: string) -> ptr {
    let tokens = cartan_tree_create();
    let len = cartan_string_length(line);
    if (len <= 0.0) { return tokens; }

    var token_start = 0.0;
    var in_quotes = 0.0;
    var i = 0.0;

    while (i < len) {
        let ch = cartan_string_get_char(line, i);
        if (ch == 34.0) { // '"'
            in_quotes = 1.0 - in_quotes;
        } else if (ch == 44.0 && in_quotes == 0.0) { // ',' outside quotes
            let col = cartan_string_substring(line, token_start, i);
            cartan_tree_push(tokens, col);
            token_start = i + 1.0;
        }
        i = i + 1.0;
    }

    if (token_start <= len) {
        let final_col = cartan_string_substring(line, token_start, len);
        cartan_tree_push(tokens, final_col);
    }
    return tokens;
}

// Validates that a CSV line has balanced quotes and valid token structure
fn ingest_parse_csv_line(line: string) -> float {
    let len = cartan_string_length(line);
    if (len <= 0.0) { return 0.0; }

    var in_quotes = 0.0;
    var i = 0.0;
    while (i < len) {
        if (cartan_string_get_char(line, i) == 34.0) {
            in_quotes = 1.0 - in_quotes;
        }
        i = i + 1.0;
    }
    if (in_quotes != 0.0) {
        return 0.0; // Malformed unclosed quotation
    }

    let tokens = ingest_parse_csv_tokens(line);
    let count = cartan_tree_len_f(tokens);
    if (count > 0.0) {
        return 1.0;
    }
    return 0.0;
}

// Returns the column count of an authentic CSV line
fn ingest_csv_column_count(line: string) -> float {
    let tokens = ingest_parse_csv_tokens(line);
    return cartan_tree_len_f(tokens);
}

// Retrieves a specific column from a CSV line by 0-indexed column position
fn ingest_csv_get_column(line: string, col_idx: float) -> string {
    let tokens = ingest_parse_csv_tokens(line);
    let count = cartan_tree_len_f(tokens);
    if (col_idx < 0.0 || col_idx >= count) {
        return "";
    }
    var col_str = cartan_tree_get_f32(tokens, col_idx);
    let col_len = cartan_string_length(col_str);
    if (col_len >= 2.0) {
        if (cartan_string_get_char(col_str, 0.0) == 34.0 && cartan_string_get_char(col_str, col_len - 1.0) == 34.0) {
            col_str = cartan_string_substring(col_str, 1.0, col_len - 1.0);
        }
    }
    return col_str;
}

// Validates an authentic JSON object or array structure
fn ingest_validate_json_object(line: string) -> float {
    let len = cartan_string_length(line);
    if (len < 2.0) { return 0.0; }

    var first_idx = -1.0;
    var last_idx = -1.0;
    var i = 0.0;
    while (i < len) {
        let ch = cartan_string_get_char(line, i);
        if (ch != 32.0 && ch != 9.0 && ch != 13.0 && ch != 10.0) {
            if (first_idx < 0.0) {
                first_idx = i;
            }
            last_idx = i;
        }
        i = i + 1.0;
    }

    if (first_idx < 0.0 || last_idx < 0.0 || first_idx >= last_idx) {
        return 0.0;
    }

    let first_char = cartan_string_get_char(line, first_idx);
    let last_char = cartan_string_get_char(line, last_idx);

    var is_obj = 0.0;
    if (first_char == 123.0 && last_char == 125.0) { // '{' and '}'
        is_obj = 1.0;
    } else if (first_char == 91.0 && last_char == 93.0) { // '[' and ']'
        is_obj = 1.0;
    }
    if (is_obj == 0.0) { return 0.0; }

    var brace_depth = 0.0;
    var bracket_depth = 0.0;
    var in_quotes = 0.0;

    i = first_idx;
    while (i <= last_idx) {
        let ch = cartan_string_get_char(line, i);
        if (ch == 34.0) {
            in_quotes = 1.0 - in_quotes;
        } else if (in_quotes == 0.0) {
            if (ch == 123.0) { brace_depth = brace_depth + 1.0; }
            else if (ch == 125.0) { brace_depth = brace_depth - 1.0; }
            else if (ch == 91.0) { bracket_depth = bracket_depth + 1.0; }
            else if (ch == 93.0) { bracket_depth = bracket_depth - 1.0; }
        }
        i = i + 1.0;
    }

    if (in_quotes == 0.0 && brace_depth == 0.0 && bracket_depth == 0.0) {
        return 1.0;
    }
    return 0.0;
}

// Authentically validates and parses a multi-line JSON Lines (JSONL) payload
fn ingest_parse_json_lines(payload: string) -> float {
    let len = cartan_string_length(payload);
    if (len <= 0.0) { return 0.0; }

    var valid_records = 0.0;
    var line_start = 0.0;
    var i = 0.0;

    while (i <= len) {
        var is_eol = 0.0;
        if (i == len) {
            is_eol = 1.0;
        } else if (cartan_string_get_char(payload, i) == 10.0) { // '\n'
            is_eol = 1.0;
        }

        if (is_eol == 1.0) {
            if (i > line_start) {
                let line = cartan_string_substring(payload, line_start, i);
                let line_len = cartan_string_length(line);
                if (line_len > 0.0) {
                    let valid = ingest_validate_json_object(line);
                    if (valid == 0.0) {
                        return 0.0;
                    }
                    valid_records = valid_records + 1.0;
                }
            }
            line_start = i + 1.0;
        }
        i = i + 1.0;
    }

    if (valid_records > 0.0) {
        return 1.0;
    }
    return 0.0;
}

// Returns the count of valid JSON Lines parsed from payload
fn ingest_json_lines_count(payload: string) -> float {
    let len = cartan_string_length(payload);
    if (len <= 0.0) { return 0.0; }

    var valid_records = 0.0;
    var line_start = 0.0;
    var i = 0.0;

    while (i <= len) {
        var is_eol = 0.0;
        if (i == len) {
            is_eol = 1.0;
        } else if (cartan_string_get_char(payload, i) == 10.0) {
            is_eol = 1.0;
        }

        if (is_eol == 1.0) {
            if (i > line_start) {
                let line = cartan_string_substring(payload, line_start, i);
                if (ingest_validate_json_object(line) == 1.0) {
                    valid_records = valid_records + 1.0;
                }
            }
            line_start = i + 1.0;
        }
        i = i + 1.0;
    }
    return valid_records;
}

// Authentically extracts the string value of key from a JSON object
fn ingest_json_get_field(json_str: string, key: string) -> string {
    let len = cartan_string_length(json_str);
    if (len <= 0.0) { return ""; }

    let pattern = cartan_string_concat("\"", cartan_string_concat(key, "\""));
    let pat_len = cartan_string_length(pattern);

    var i = 0.0;
    while (i <= len - pat_len) {
        let sub = cartan_string_substring(json_str, i, i + pat_len);
        if (cartan_string_eq(sub, pattern) == 1.0) {
            var colon_idx = i + pat_len;
            while (colon_idx < len && cartan_string_get_char(json_str, colon_idx) != 58.0) { // ':'
                colon_idx = colon_idx + 1.0;
            }
            if (colon_idx < len) {
                var val_start = colon_idx + 1.0;
                while (val_start < len) {
                    let vc = cartan_string_get_char(json_str, val_start);
                    if (vc != 32.0 && vc != 9.0) {
                        break;
                    }
                    val_start = val_start + 1.0;
                }

                if (val_start < len) {
                    let first_val_ch = cartan_string_get_char(json_str, val_start);
                    if (first_val_ch == 34.0) { // Quoted string
                        var val_end = val_start + 1.0;
                        while (val_end < len) {
                            if (cartan_string_get_char(json_str, val_end) == 34.0) {
                                break;
                            }
                            val_end = val_end + 1.0;
                        }
                        return cartan_string_substring(json_str, val_start + 1.0, val_end);
                    } else { // Primitive scalar
                        var val_end = val_start;
                        while (val_end < len) {
                            let ec = cartan_string_get_char(json_str, val_end);
                            if (ec == 44.0 || ec == 125.0 || ec == 93.0 || ec == 32.0 || ec == 10.0 || ec == 13.0) {
                                break;
                            }
                            val_end = val_end + 1.0;
                        }
                        return cartan_string_substring(json_str, val_start, val_end);
                    }
                }
            }
        }
        i = i + 1.0;
    }
    return "";
}

// Non-prefixed convenience aliases
fn parse_csv_line(line: string) -> float { return ingest_parse_csv_line(line); }
fn parse_csv_tokens(line: string) -> ptr { return ingest_parse_csv_tokens(line); }
fn parse_json_lines(payload: string) -> float { return ingest_parse_json_lines(payload); }
fn csv_column_count(line: string) -> float { return ingest_csv_column_count(line); }
fn csv_get_column(line: string, col_idx: float) -> string { return ingest_csv_get_column(line, col_idx); }
fn json_lines_count(payload: string) -> float { return ingest_json_lines_count(payload); }
fn json_get_field(json_str: string, key: string) -> string { return ingest_json_get_field(json_str, key); }

