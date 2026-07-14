extern fn malloc();
extern fn free();

fn alloc_array(size: float) -> ptr {
    // malloc takes size in bytes. We allocate size * 4 (since floats are 4 bytes, wait actually we use doubles mostly?)
    // In Cartan, LLVM passes floats as f32 in pointers, but f64 in printf. Wait, variables are `alloca float` in LLVM, so 4 bytes!
    return malloc(size * 4.0);
}
