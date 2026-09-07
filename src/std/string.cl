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



