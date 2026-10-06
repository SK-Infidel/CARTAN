// src/std/string.cl
// CARTAN Standard Library: Pure Native String Manipulation Module

extern fn c_cartan_string_length(s: string) -> float;
extern fn c_cartan_string_eq(s1: string, s2: string) -> float;
extern fn c_cartan_string_contains(s1: string, target: string) -> float;
extern fn c_cartan_string_concat(s1: string, s2: string) -> string;
extern fn strstr(haystack: string, needle: string) -> ptr;
extern fn strcpy(dst: ptr, src: string) -> ptr;
extern fn strcat(dst: ptr, src: string) -> ptr;
extern fn c_cartan_float_to_string(val: float) -> string;
extern fn c_cartan_string_char_at(s: string, idx: float) -> float;
extern fn c_cartan_string_replace(s: string, old_sub: string, new_sub: string) -> string;
extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr);

extern fn cartan_string_length(s: string) -> float;
extern fn cartan_string_eq(s1: string, s2: string) -> float;
extern fn cartan_string_contains(s1: string, target: string) -> float;
extern fn cartan_string_concat(s1: string, s2: string) -> string;
extern fn cartan_float_to_string(val: float) -> string;
extern fn cartan_string_starts_with(s: string, prefix: string) -> float;
extern fn cartan_string_get_char(s: string, idx: float) -> float;
extern fn cartan_string_replace(s: string, old_sub: string, new_sub: string) -> string;
extern fn cartan_string_substring(s: string, start: float, end_idx: float) -> string;
extern fn cartan_hash_string(s: string) -> float;
extern fn cartan_set_byte(buf: ptr, offset: float, val: float);
extern fn cartan_byte_at(buf: ptr, offset: float) -> float;

fn string_len(s: string) -> float {
    return cartan_string_length(s);
}

fn string_concat(s1: string, s2: string) -> string {
    return cartan_string_concat(s1, s2);
}

fn string_starts_with(s: string, prefix: string) -> float {
    return cartan_string_starts_with(s, prefix);
}

fn string_contains(s: string, target: string) -> float {
    return cartan_string_contains(s, target);
}

fn string_replace(s: string, old_sub: string, new_sub: string) -> string {
    return cartan_string_replace(s, old_sub, new_sub);
}

fn string_substring(s: string, start: float, end_idx: float) -> string {
    return cartan_string_substring(s, start, end_idx);
}

fn string_split(s: string, delim: string) -> ptr {
    let result = cartan_tree_create();
    if (s == 0.0) { return result; }
    let s_len = cartan_string_length(s);
    if (s_len == 0.0) { return result; }
    if (delim == 0.0) {
        cartan_tree_push(result, s);
        return result;
    }
    let d_len = cartan_string_length(delim);
    if (d_len == 0.0) {
        cartan_tree_push(result, s);
        return result;
    }
    var i = 0.0;
    var start = 0.0;
    let limit = s_len - d_len;
    while (i <= limit) {
        if (cartan_c_strncmp(cartan_c_ptr_add(s, i), delim, d_len) == 0.0) {
            let part = cartan_string_substring(s, start, i);
            cartan_tree_push(result, part);
            i = i + d_len;
            start = i;
        } else {
            i = i + 1.0;
        }
    }
    let last_part = cartan_string_substring(s, start, s_len);
    cartan_tree_push(result, last_part);
    return result;
}

fn cartan_string_ends_with(s: string, suffix: string) -> float {
    let s_len = cartan_string_length(s);
    let suf_len = cartan_string_length(suffix);
    if (suf_len > s_len || suf_len == 0.0) { return 0.0; }
    let sub = cartan_string_substring(s, s_len - suf_len, s_len);
    return cartan_string_eq(sub, suffix);
}

fn string_ends_with(s: string, suffix: string) -> float {
    return cartan_string_ends_with(s, suffix);
}

fn cartan_string_to_lower(s: string) -> string {
    if (s == 0.0) { return ""; }
    let len = cartan_string_length(s);
    if (len == 0.0) { return ""; }
    let res = malloc(len + 1.0);
    var i = 0.0;
    while (i < len) {
        var c = cartan_string_get_char(s, i);
        if (c >= 65.0 && c <= 90.0) {
            c = c + 32.0;
        }
        cartan_set_byte(res, i, c);
        i = i + 1.0;
    }
    cartan_set_byte(res, len, 0.0);
    return res;
}

fn string_to_lower(s: string) -> string {
    return cartan_string_to_lower(s);
}

// Converts an ASCII character code to lowercase
fn string_char_to_lower(c: float) -> float {
    if (c >= 65.0 && c <= 90.0) {
        return c + 32.0;
    }
    return c;
}

// Checks if character code is whitespace (space, tab, newline, CR)
fn string_char_is_space(c: float) -> float {
    if (c == 32.0 || c == 9.0 || c == 10.0 || c == 13.0) {
        return 1.0;
    }
    return 0.0;
}

// Trims leading and trailing whitespace from a string
fn string_trim(s: string) -> string {
    if (s == 0.0) { return ""; }
    let len = cartan_string_length(s);
    if (len == 0.0) { return ""; }
    var start = 0.0;
    while (start < len) {
        let c = cartan_byte_at(s, start);
        if (string_char_is_space(c) == 0.0) {
            break;
        }
        start = start + 1.0;
    }
    if (start >= len) { return ""; }
    var end = len - 1.0;
    while (end >= start) {
        let c = cartan_byte_at(s, end);
        if (string_char_is_space(c) == 0.0) {
            break;
        }
        end = end - 1.0;
    }
    return cartan_string_substring(s, start, end + 1.0);
}

fn cartan_string_trim(s: string) -> string {
    return string_trim(s);
}

// Checks if haystack starts with needle starting at offset without allocating substrings
fn string_starts_with_offset(haystack: string, needle: string, offset: float) -> float {
    if (haystack == 0.0 || needle == 0.0) { return 0.0; }
    let h_len = cartan_string_length(haystack);
    let n_len = cartan_string_length(needle);
    if (offset < 0.0 || offset + n_len > h_len) { return 0.0; }
    var i = 0.0;
    while (i < n_len) {
        let ch = cartan_byte_at(haystack, offset + i);
        let cn = cartan_byte_at(needle, i);
        if (ch != cn) { return 0.0; }
        i = i + 1.0;
    }
    return 1.0;
}

fn cartan_string_starts_with_offset(haystack: string, needle: string, offset: float) -> float {
    return string_starts_with_offset(haystack, needle, offset);
}

// Searches for needle in haystack starting from start_offset, returning 0-based index or -1.0
fn string_index_of_offset(haystack: string, needle: string, start_offset: float) -> float {
    if (haystack == 0.0 || needle == 0.0) { return -1.0; }
    let h_len = cartan_string_length(haystack);
    let n_len = cartan_string_length(needle);
    if (n_len == 0.0) { return start_offset; }
    if (start_offset < 0.0 || start_offset + n_len > h_len) { return -1.0; }
    var i = start_offset;
    let limit = h_len - n_len;
    while (i <= limit) {
        if (string_starts_with_offset(haystack, needle, i) == 1.0) {
            return i;
        }
        i = i + 1.0;
    }
    return -1.0;
}

fn cartan_string_index_of_offset(haystack: string, needle: string, start_offset: float) -> float {
    return string_index_of_offset(haystack, needle, start_offset);
}

// Searches for needle in haystack from the beginning, returning 0-based index or -1.0
fn string_index_of(haystack: string, needle: string) -> float {
    return string_index_of_offset(haystack, needle, 0.0);
}

fn cartan_string_index_of(haystack: string, needle: string) -> float {
    return string_index_of(haystack, needle);
}

// Case-insensitively checks if haystack matches needle starting at offset
fn string_starts_with_offset_ignore_case(haystack: string, needle: string, offset: float) -> float {
    if (haystack == 0.0 || needle == 0.0) { return 0.0; }
    let h_len = cartan_string_length(haystack);
    let n_len = cartan_string_length(needle);
    if (offset < 0.0 || offset + n_len > h_len) { return 0.0; }
    var i = 0.0;
    while (i < n_len) {
        let ch = string_char_to_lower(cartan_byte_at(haystack, offset + i));
        let cn = string_char_to_lower(cartan_byte_at(needle, i));
        if (ch != cn) { return 0.0; }
        i = i + 1.0;
    }
    return 1.0;
}

fn cartan_string_starts_with_offset_ignore_case(haystack: string, needle: string, offset: float) -> float {
    return string_starts_with_offset_ignore_case(haystack, needle, offset);
}

// Case-insensitively searches for needle in haystack starting from start_offset
fn string_index_of_offset_ignore_case(haystack: string, needle: string, start_offset: float) -> float {
    if (haystack == 0.0 || needle == 0.0) { return -1.0; }
    let h_len = cartan_string_length(haystack);
    let n_len = cartan_string_length(needle);
    if (n_len == 0.0) { return start_offset; }
    if (start_offset < 0.0 || start_offset + n_len > h_len) { return -1.0; }
    var i = start_offset;
    let limit = h_len - n_len;
    while (i <= limit) {
        if (string_starts_with_offset_ignore_case(haystack, needle, i) == 1.0) {
            return i;
        }
        i = i + 1.0;
    }
    return -1.0;
}

fn cartan_string_index_of_offset_ignore_case(haystack: string, needle: string, start_offset: float) -> float {
    return string_index_of_offset_ignore_case(haystack, needle, start_offset);
}

// Case-insensitively searches for needle in haystack from the beginning
fn string_index_of_ignore_case(haystack: string, needle: string) -> float {
    return string_index_of_offset_ignore_case(haystack, needle, 0.0);
}

fn cartan_string_index_of_ignore_case(haystack: string, needle: string) -> float {
    return string_index_of_ignore_case(haystack, needle);
}


