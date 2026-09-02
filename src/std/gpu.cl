// src/std/gpu.cl
// Standard Library WebGPU Native Compute Interface for CARTAN

extern fn cartan_gpu_init() -> float;
extern fn cartan_gpu_create_buffer(size_bytes: float, usage: float) -> ptr;
extern fn cartan_gpu_write_buffer(buffer: ptr, offset: float, src_data: ptr, size_bytes: float) -> float;
extern fn cartan_gpu_read_buffer(buffer: ptr, offset: float, dst_data: ptr, size_bytes: float) -> float;
extern fn cartan_gpu_create_pipeline(wgsl_source: string, entry_point: string) -> ptr;
extern fn cartan_gpu_dispatch(pipe: ptr, buffers: ptr, num_buffers: float, gx: float, gy: float, gz: float) -> float;
extern fn cartan_gpu_sync() -> float;
extern fn cartan_f32_buffer_alloc(count: float) -> ptr;
extern fn cartan_f32_buffer_set(buf: ptr, idx: float, val: float) -> float;
extern fn cartan_f32_buffer_get(buf: ptr, idx: float) -> float;
extern fn cartan_f32_buffer_free(buf: ptr) -> float;

fn gpu_init() -> float {
    return cartan_gpu_init();
}

fn gpu_alloc(size_bytes: float) -> ptr {
    return cartan_gpu_create_buffer(size_bytes, 1.0);
}

fn gpu_write(buf: ptr, data: ptr, size_bytes: float) -> float {
    return cartan_gpu_write_buffer(buf, 0.0, data, size_bytes);
}

fn gpu_read(buf: ptr, data: ptr, size_bytes: float) -> float {
    return cartan_gpu_read_buffer(buf, 0.0, data, size_bytes);
}

fn gpu_create_pipeline(wgsl_source: string, entry_point: string) -> ptr {
    return cartan_gpu_create_pipeline(wgsl_source, entry_point);
}

fn gpu_dispatch(pipe: ptr, buffers: ptr, num_buffers: float, gx: float, gy: float, gz: float) -> float {
    return cartan_gpu_dispatch(pipe, buffers, num_buffers, gx, gy, gz);
}

fn gpu_sync() -> float {
    return cartan_gpu_sync();
}
