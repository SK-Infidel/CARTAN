// src/std/env.cl
// CARTAN Standard Library: Hardware Acceleration, Environment & Command-Line Arguments Module

extern fn cartan_getenv(name: string) -> string;
extern fn cartan_get_arg_int(key: ptr, default_val: float) -> float;
extern fn cartan_get_arg_float(key: ptr, default_val: float) -> float;
extern fn cartan_get_arg_string(key: ptr, default_val: ptr) -> ptr;
extern fn cartan_has_arg(key: ptr) -> float;
extern fn cartan_detect_hardware() -> float;
extern fn cartan_mount_backend(id: float) -> float;

struct ArgParser {
    dummy: float;
}

fn env_get(var_name: string) -> string {
    return cartan_getenv(var_name);
}

fn env_detect_hardware() -> float {
    return cartan_detect_hardware();
}

fn env_mount_backend(backend_id: float) -> float {
    return cartan_mount_backend(backend_id);
}
