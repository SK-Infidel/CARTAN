include "src/std/fs.cl";
include "src/std/string.cl";

extern fn getenv(name: string) -> string;
extern fn strncpy(dst: ptr, src: ptr, n: float) -> ptr;
extern fn sys_get_arg(idx: float) -> string;
extern fn sys_get_arg_count() -> float;
extern fn atof(s: string) -> float;
extern fn floor(x: float) -> float;
extern fn cartan_string_substring(s: string, start: float, end_idx: float) -> string;

struct ArgParser {
    dummy: float;
}

fn cartan_has_arg(key: string) -> float {
    let argc = sys_get_arg_count();
    var i = 1.0;
    let prefix = cartan_string_concat(key, "=");
    while (i < argc) {
        let arg = sys_get_arg(i);
        if (cartan_string_eq(arg, key) == 1.0) {
            return 1.0;
        }
        if (cartan_string_starts_with(arg, prefix) == 1.0) {
            return 1.0;
        }
        i = i + 1.0;
    }
    return 0.0;
}

fn cartan_get_arg_string(key: string, default_val: string) -> string {
    let argc = sys_get_arg_count();
    var i = 1.0;
    let prefix = cartan_string_concat(key, "=");
    let p_len = cartan_string_length(prefix);
    while (i < argc) {
        let arg = sys_get_arg(i);
        if (cartan_string_eq(arg, key) == 1.0) {
            if (i + 1.0 < argc) {
                return sys_get_arg(i + 1.0);
            }
            return default_val;
        }
        if (cartan_string_starts_with(arg, prefix) == 1.0) {
            let arg_len = cartan_string_length(arg);
            return cartan_string_substring(arg, p_len, arg_len);
        }
        i = i + 1.0;
    }
    return default_val;
}

fn cartan_get_arg_float(key: string, default_val: float) -> float {
    let val_str = cartan_get_arg_string(key, "");
    if (cartan_string_length(val_str) == 0.0) {
        return default_val;
    }
    return atof(val_str);
}

fn cartan_get_arg_int(key: string, default_val: float) -> float {
    let f = cartan_get_arg_float(key, default_val);
    return floor(f);
}

// Hardware detection: 1.0 = CPU/Host, 2.0 = WebGPU, 3.0 = CUDA
fn cartan_detect_hardware() -> float {
    let cuda_env = env_get("CUDA_VISIBLE_DEVICES");
    if (cartan_string_length(cuda_env) > 0.0) {
        return 3.0;
    }
    let backend_env = env_get("CARTAN_BACKEND");
    if (cartan_string_eq(backend_env, "cuda") == 1.0 || cartan_string_eq(backend_env, "CUDA") == 1.0) {
        return 3.0;
    }
    if (cartan_string_eq(backend_env, "webgpu") == 1.0 || cartan_string_eq(backend_env, "WEBGPU") == 1.0) {
        return 2.0;
    }
    let webgpu_adapter = env_get("WEBGPU_ADAPTER");
    if (cartan_string_length(webgpu_adapter) > 0.0) {
        return 2.0;
    }
    return 1.0;
}

fn cartan_mount_backend(id: float) -> float {
    if (id < 1.0 || id > 3.0) {
        return 0.0;
    }
    return 1.0;
}

fn env_get(var_name: string) -> string {
    let val = getenv(var_name);
    if (val == 0.0) { return ""; }
    return val;
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

