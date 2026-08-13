// src/std/io.cl
// CARTAN Standard Library: System Input/Output Module

extern fn printf(fmt: string, val: string) -> float;
extern fn cartan_flush(v: float) -> float;
extern fn cartan_system(cmd: string) -> float;

fn io_print(val: string) -> float {
    printf("%s", val);
    return cartan_flush(0.0);
}

fn io_println(val: string) -> float {
    printf("%s\n", val);
    return cartan_flush(0.0);
}

fn io_exec(cmd: string) -> float {
    return cartan_system(cmd);
}

fn io_flush() -> float {
    return cartan_flush(0.0);
}
