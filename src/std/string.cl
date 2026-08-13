// src/std/string.cl
// CARTAN Standard Library: Comprehensive String Manipulation Module

extern fn cartan_string_length(s: string) -> float;
extern fn cartan_string_replace(s: string, f: string, r: string) -> string;
extern fn cartan_string_starts_with(s: string, prefix: string) -> float;
extern fn c_cartan_string_concat(s1: string, s2: string) -> string;
extern fn cartan_float_to_string(val: float) -> string;

fn string_len(s: string) -> float {
    return cartan_string_length(s);
}

fn string_concat(s1: string, s2: string) -> string {
    return c_cartan_string_concat(s1, s2);
}

fn string_replace(s: string, target: string, replacement: string) -> string {
    return cartan_string_replace(s, target, replacement);
}

fn string_starts_with(s: string, prefix: string) -> float {
    return cartan_string_starts_with(s, prefix);
}

fn string_contains(s: string, target: string) -> float {
    return cartan_string_starts_with(s, target);
}
