include "src/std/fs.cl";
include "src/std/string.cl";

extern fn getenv(name: string) -> string;
extern fn strncpy(dst: ptr, src: ptr, n: float) -> ptr;
extern fn cartan_detect_hardware() -> float;
extern fn cartan_mount_backend(id: float) -> float;
extern fn cartan_get_arg_int(key: string, default_val: float) -> float;
extern fn cartan_get_arg_float(key: string, default_val: float) -> float;
extern fn cartan_get_arg_string(key: string, default_val: string) -> string;
extern fn cartan_has_arg(key: string) -> float;

struct ArgParser {
    dummy: float;
}

fn env_get(var_name: string) -> string {
    let val = getenv(var_name);
    if (val == 0.0) { return ""; }
    return val;
}

fn cartan_get_env(key: string) -> string {
    return env_get(key);
}

fn cartan_read_config(filepath: string, key: string) -> string {
    if (cartan_file_exists(filepath) == 0.0) { return ""; }
    let content = cartan_read_file(filepath);
    if (content == 0.0) { return ""; }
    let search_key = cartan_string_concat(key, "=");
    let pos = strstr(content, search_key);
    if (pos == 0.0) { return ""; }
    let val_start = pos + cartan_string_length(search_key);
    let nl_pos = strstr(val_start, "\n");
    if (nl_pos != 0.0) {
        let val_len = nl_pos - val_start;
        let buf = malloc(val_len + 1.0);
        strncpy(buf, val_start, val_len);
        return buf;
    }
    return val_start;
}

fn env_detect_hardware() -> float {
    return cartan_detect_hardware();
}

fn env_mount_backend(backend_id: float) -> float {
    return cartan_mount_backend(backend_id);
}

