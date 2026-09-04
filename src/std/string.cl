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


