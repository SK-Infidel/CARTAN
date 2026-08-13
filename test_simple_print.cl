// test/geomind/test_simple_print.cl

extern fn printf(fmt: string) -> i32;
extern fn cartan_flush(v: float) -> float;

fn main(argc: float, argv: ptr) -> float {
    printf("Hello from CARTAN test_simple_print!\n");
    cartan_flush(0.0);
    return 0.0;
}
