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

fn cartan_string_length(s: string) -> float {
    return c_cartan_string_length(s);
}

fn cartan_string_eq(s1: string, s2: string) -> float {
    return c_cartan_string_eq(s1, s2);
}

fn cartan_string_contains(s: string, target: string) -> float {
    return c_cartan_string_contains(s, target);
}

fn cartan_string_concat(s1: string, s2: string) -> string {
    return c_cartan_string_concat(s1, s2);
}

fn cartan_float_to_string(val: float) -> string {
    return c_cartan_float_to_string(val);
}

fn string_len(s: string) -> float {
    return cartan_string_length(s);
}

fn string_concat(s1: string, s2: string) -> string {
    return cartan_string_concat(s1, s2);
}

fn string_starts_with(s: string, prefix: string) -> float {
    if (s == 0.0 || prefix == 0.0) { return 0.0; }
    let lp = cartan_string_length(prefix);
    let ls = cartan_string_length(s);
    if (lp > ls) { return 0.0; }
    let res = strstr(s, prefix);
    if (res == s) { return 1.0; }
    return 0.0;
}

fn string_contains(s: string, target: string) -> float {
    return cartan_string_contains(s, target);
}

extern fn c_cartan_string_char_at(s: string, idx: float) -> float;
extern fn c_cartan_string_replace(s: string, old_sub: string, new_sub: string) -> string;

fn cartan_string_get_char(s: string, idx: float) -> float {
    return c_cartan_string_char_at(s, idx);
}

fn cartan_string_replace(s: string, old_sub: string, new_sub: string) -> string {
    return c_cartan_string_replace(s, old_sub, new_sub);
}

fn string_replace(s: string, old_sub: string, new_sub: string) -> string {
    return cartan_string_replace(s, old_sub, new_sub);
}

fn cartan_hash_string(s: string) -> float {
    if (s == 0.0) { return 0.0; }
    var hash = 5381.0;
    let len = cartan_string_length(s);
    var i = 0.0;
    while (i < len) {
        let c = cartan_string_get_char(s, i);
        hash = (hash * 33.0) + c;
        i = i + 1.0;
    }
    return hash;
}

