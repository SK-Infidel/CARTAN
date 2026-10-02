// src/std/gpu.cl
// CARTAN Standard Library: Pure Native Hardware GPU Acceleration Engine (Zero C / Zero Rust Dependency)
// Drives physical GPU compute via Windows native OpenCL driver (NVIDIA Ada / Intel GPU).

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/string.cl";
include "src/std/wgpu.cl";

extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr);
extern fn memcpy(dest: ptr, src: ptr, count: float) -> ptr;
extern fn printf(fmt: string, val: string) -> float;
extern fn cartan_flush(f: float) -> float;

extern fn cartan_byte_at(p: ptr, offset: float) -> float;
extern fn cartan_f32_at(p: ptr, offset: float) -> float;
extern fn cartan_set_f32(p: ptr, offset: float, val: float) -> void;
extern fn cartan_i32_at(p: ptr, offset: float) -> float;
extern fn cartan_set_i32(p: ptr, offset: float, val: float) -> void;
extern fn cartan_i64_at(p: ptr, offset: float) -> float;
extern fn cartan_set_i64(p: ptr, offset: float, val: float) -> void;

extern fn clGetPlatformIDs(num_entries: float, platforms: ptr, num_platforms: ptr) -> float;
extern fn clGetPlatformInfo(platform: ptr, param_name: float, param_value_size: float, param_value: ptr, param_value_size_ret: ptr) -> float;
extern fn clGetDeviceIDs(platform: ptr, device_type: float, num_entries: float, devices: ptr, num_devices: ptr) -> float;
extern fn clGetDeviceInfo(device: ptr, param_name: float, param_value_size: float, param_value: ptr, param_value_size_ret: ptr) -> float;
extern fn clCreateContext(properties: ptr, num_devices: float, devices: ptr, pfn_notify: ptr, user_data: ptr, errcode_ret: ptr) -> ptr;
extern fn clCreateCommandQueue(context: ptr, device: ptr, properties: float, errcode_ret: ptr) -> ptr;
extern fn clCreateBuffer(context: ptr, flags: float, size: float, host_ptr: ptr, errcode_ret: ptr) -> ptr;
extern fn clCreateProgramWithSource(context: ptr, count: float, strings: ptr, lengths: ptr, errcode_ret: ptr) -> ptr;
extern fn clBuildProgram(program: ptr, num_devices: float, device_list: ptr, options: string, pfn_notify: ptr, user_data: ptr) -> float;
extern fn clGetProgramBuildInfo(program: ptr, device: ptr, param_name: float, param_value_size: float, param_value: ptr, param_value_size_ret: ptr) -> float;
extern fn clCreateKernel(program: ptr, kernel_name: string, errcode_ret: ptr) -> ptr;
extern fn clSetKernelArg(kernel: ptr, arg_index: float, arg_size: float, arg_value: ptr) -> float;
extern fn clEnqueueNDRangeKernel(command_queue: ptr, kernel: ptr, work_dim: float, global_work_offset: ptr, global_work_size: ptr, local_work_size: ptr, num_events: float, event_wait_list: ptr, event: ptr) -> float;
extern fn clEnqueueWriteBuffer(command_queue: ptr, buffer: ptr, blocking_write: float, offset: float, size: float, ptr_src: ptr, num_events: float, event_wait_list: ptr, event: ptr) -> float;
extern fn clEnqueueReadBuffer(command_queue: ptr, buffer: ptr, blocking_read: float, offset: float, size: float, ptr_dst: ptr, num_events: float, event_wait_list: ptr, event: ptr) -> float;
extern fn clReleaseMemObject(memobj: ptr) -> float;
extern fn clFinish(command_queue: ptr) -> float;


var g_gpu_initialized: float = 0.0;
var g_gpu_platform: ptr = 0.0;
var g_gpu_device: ptr = 0.0;
var g_gpu_context: ptr = 0.0;
var g_gpu_queue: ptr = 0.0;
var g_gpu_device_name: string = "";

// Persistent zero-allocation host buffers for kernel arguments and dispatch
var g_gpu_slot_buf: ptr = 0.0;
var g_gpu_slot_i32: ptr = 0.0;
var g_gpu_slot_f32: ptr = 0.0;
var g_gpu_slot_gws: ptr = 0.0;
var g_gpu_slot_lws: ptr = 0.0;

// Native hardware GPU initialization hook
fn cartan_gpu_init() -> float {
    if (g_gpu_initialized == 1.0) {
        return 1.0;
    }

    let num_plat_buf = malloc(8.0);
    let platforms_buf = malloc(64.0);
    let err1 = clGetPlatformIDs(4.0, platforms_buf, num_plat_buf);
    if (err1 != 0.0) {
        printf("[CARTAN GPU Error] clGetPlatformIDs failed: %s\n", cartan_float_to_string(err1));
        cartan_flush(0.0);
        return 0.0;
    }

    let num_platforms = cartan_byte_at(num_plat_buf, 0.0);
    var plat_idx = 0.0;
    var found_gpu = 0.0;
    let devices_buf = malloc(64.0);
    let num_dev_buf = malloc(8.0);

    var fallback_plat: ptr = 0.0;
    var fallback_dev: ptr = 0.0;
    while (plat_idx < num_platforms && found_gpu == 0.0) {
        let cur_plat = platforms_buf[plat_idx];
        let p_name = malloc(128.0);
        clGetPlatformInfo(cur_plat, 2306.0, 128.0, p_name, 0.0); // 0x0902 = CL_PLATFORM_NAME
        let err2 = clGetDeviceIDs(cur_plat, 4.0, 1.0, devices_buf, num_dev_buf); // 4.0 = CL_DEVICE_TYPE_GPU
        if (err2 == 0.0) {
            if (cartan_string_contains(p_name, "NVIDIA") == 1.0 || cartan_string_contains(p_name, "CUDA") == 1.0) {
                g_gpu_platform = cur_plat;
                g_gpu_device = devices_buf[0.0];
                found_gpu = 1.0;
            } else if (fallback_plat == 0.0) {
                fallback_plat = cur_plat;
                fallback_dev = devices_buf[0.0];
            }
        }
        free(p_name);
        plat_idx = plat_idx + 1.0;
    }

    if (found_gpu == 0.0 && fallback_plat != 0.0) {
        g_gpu_platform = fallback_plat;
        g_gpu_device = fallback_dev;
        found_gpu = 1.0;
    }

    if (found_gpu == 0.0) {
        printf("[CARTAN GPU Error] No hardware GPU device found on any OpenCL platform.\n", "");
        cartan_flush(0.0);
        return 0.0;
    }

    let dev_name = malloc(256.0);
    clGetDeviceInfo(g_gpu_device, 4139.0, 256.0, dev_name, 0.0); // 4139 = CL_DEVICE_NAME
    g_gpu_device_name = dev_name;

    let err_buf = malloc(8.0);
    let dev_arr = malloc(8.0);
    dev_arr[0.0] = g_gpu_device;
    g_gpu_context = clCreateContext(0.0, 1.0, dev_arr, 0.0, 0.0, err_buf);
    free(dev_arr);
    if (g_gpu_context == 0.0) {
        printf("[CARTAN GPU Error] clCreateContext failed.\n", "");
        cartan_flush(0.0);
        return 0.0;
    }

    g_gpu_queue = clCreateCommandQueue(g_gpu_context, g_gpu_device, 0.0, err_buf);
    if (g_gpu_queue == 0.0) {
        printf("[CARTAN GPU Error] clCreateCommandQueue failed.\n", "");
        cartan_flush(0.0);
        return 0.0;
    }

    free(num_plat_buf);
    free(platforms_buf);
    free(devices_buf);
    free(num_dev_buf);
    free(err_buf);

    if (g_gpu_slot_buf == 0.0) {
        g_gpu_slot_buf = malloc(8.0);
        g_gpu_slot_i32 = malloc(4.0);
        g_gpu_slot_f32 = malloc(4.0);
        g_gpu_slot_gws = malloc(24.0);
        g_gpu_slot_lws = malloc(24.0);
    }

    g_gpu_initialized = 1.0;
    printf("[CARTAN GPU] Bare-Metal Hardware Acceleration Engine Initialized: %s\n", dev_name);
    cartan_flush(0.0);
    return 1.0;
}

// Allocates physical device VRAM storage buffer
fn cartan_gpu_create_buffer(size_bytes: float, usage: float) -> ptr {
    if (g_gpu_initialized == 0.0) {
        let ok = cartan_gpu_init();
        if (ok != 1.0) { return 0.0; }
    }
    if (g_gpu_context == 0.0) { return 0.0; }

    var sz = size_bytes;
    if (sz < 16.0) { sz = 16.0; }

    let err_buf = malloc(8.0);
    let buf = clCreateBuffer(g_gpu_context, 1.0, sz, 0.0, err_buf); // 1.0 = CL_MEM_READ_WRITE
    free(err_buf);
    return buf;
}

// Synchronously transfers data from host memory to physical GPU VRAM
fn cartan_gpu_write_buffer(buffer: ptr, offset: float, src_data: ptr, size_bytes: float) -> float {
    if (g_gpu_queue == 0.0 || buffer == 0.0 || src_data == 0.0) { return 0.0; }
    let err = clEnqueueWriteBuffer(g_gpu_queue, buffer, 1.0, offset, size_bytes, src_data, 0.0, 0.0, 0.0);
    if (err == 0.0) { return 1.0; }
    return 0.0;
}

// Synchronously transfers data from physical GPU VRAM to host memory
fn cartan_gpu_read_buffer(buffer: ptr, offset: float, dst_data: ptr, size_bytes: float) -> float {
    if (g_gpu_queue == 0.0 || buffer == 0.0 || dst_data == 0.0) { return 0.0; }
    let err = clEnqueueReadBuffer(g_gpu_queue, buffer, 1.0, offset, size_bytes, dst_data, 0.0, 0.0, 0.0);
    if (err == 0.0) { return 1.0; }
    return 0.0;
}

// JIT-compiles GPU kernel on hardware adapter
fn cartan_gpu_create_pipeline(source: string, entry_point: string) -> ptr {
    if (g_gpu_initialized == 0.0) {
        let ok = cartan_gpu_init();
        if (ok != 1.0) { return 0.0; }
    }
    if (g_gpu_context == 0.0) { return 0.0; }

    var kernel_cl = source;

    let src_slot = malloc(8.0);
    src_slot[0.0] = kernel_cl;
    let err_buf = malloc(8.0);
    let prog = clCreateProgramWithSource(g_gpu_context, 1.0, src_slot, 0.0, err_buf);
    free(src_slot);
    if (prog == 0.0) {
        printf("[CARTAN GPU Error] clCreateProgramWithSource failed for: %s\n", entry_point);
        cartan_flush(0.0);
        return 0.0;
    }

    let dev_slot = malloc(8.0);
    dev_slot[0.0] = g_gpu_device;
    let b_err = clBuildProgram(prog, 1.0, dev_slot, "-cl-fast-relaxed-math", 0.0, 0.0);
    free(dev_slot);
    if (b_err != 0.0) {
        let log_buf = malloc(4096.0);
        clGetProgramBuildInfo(prog, g_gpu_device, 4483.0, 4096.0, log_buf, 0.0);
        printf("[CARTAN GPU Error] Program build failed:\n%s\n", log_buf);
        cartan_flush(0.0);
        free(log_buf);
        return 0.0;
    }

    let kernel = clCreateKernel(prog, entry_point, err_buf);
    free(err_buf);
    if (kernel == 0.0) {
        printf("[CARTAN GPU Error] clCreateKernel failed for: %s\n", entry_point);
        cartan_flush(0.0);
        return 0.0;
    }
    return kernel;
}

// Dispatches hardware compute kernel across grid dimensions
fn cartan_gpu_dispatch(pipe: ptr, buffers: ptr, num_buffers: float, gx: float, gy: float, gz: float) -> float {
    if (g_gpu_queue == 0.0 || pipe == 0.0 || buffers == 0.0) { return 0.0; }

    let arg_slot = malloc(8.0);
    var b_i = 0.0;
    while (b_i < num_buffers) {
        let b = cartan_tree_get_f32(buffers, b_i);
        arg_slot[0.0] = b;
        clSetKernelArg(pipe, b_i, 8.0, arg_slot);
        b_i = b_i + 1.0;
    }
    free(arg_slot);

    let gws = malloc(24.0);
    cartan_set_i64(gws, 0.0, gx);
    cartan_set_i64(gws, 1.0, gy);
    cartan_set_i64(gws, 2.0, gz);

    var work_dim = 1.0;
    if (gy > 1.0) { work_dim = 2.0; }
    if (gz > 1.0) { work_dim = 3.0; }

    let k_err = clEnqueueNDRangeKernel(g_gpu_queue, pipe, work_dim, 0.0, gws, 0.0, 0.0, 0.0, 0.0);
    free(gws);

    if (k_err == 0.0) {
        return 1.0;
    }
    printf("[CARTAN GPU Error] clEnqueueNDRangeKernel failed with code: %s\n", cartan_float_to_string(k_err));
    cartan_flush(0.0);
    return 0.0;
}

// Sets a buffer argument on a kernel (zero-allocation)
fn cartan_gpu_set_arg_buf(kernel: ptr, arg_idx: float, buf: ptr) -> float {
    if (g_gpu_slot_buf == 0.0) { g_gpu_slot_buf = malloc(8.0); }
    g_gpu_slot_buf[0.0] = buf;
    return clSetKernelArg(kernel, arg_idx, 8.0, g_gpu_slot_buf);
}

// Sets a 32-bit integer scalar argument on a kernel (zero-allocation)
fn cartan_gpu_set_arg_i32(kernel: ptr, arg_idx: float, val: float) -> float {
    if (g_gpu_slot_i32 == 0.0) { g_gpu_slot_i32 = malloc(4.0); }
    cartan_set_i32(g_gpu_slot_i32, 0.0, val);
    return clSetKernelArg(kernel, arg_idx, 4.0, g_gpu_slot_i32);
}

// Sets a 32-bit float scalar argument on a kernel (zero-allocation)
fn cartan_gpu_set_arg_f32(kernel: ptr, arg_idx: float, val: float) -> float {
    if (g_gpu_slot_f32 == 0.0) { g_gpu_slot_f32 = malloc(4.0); }
    cartan_set_f32(g_gpu_slot_f32, 0.0, val);
    return clSetKernelArg(kernel, arg_idx, 4.0, g_gpu_slot_f32);
}

// Dispatches a pre-configured kernel directly (zero-allocation)
fn cartan_gpu_launch(kernel: ptr, gx: float, gy: float, gz: float) -> float {
    if (g_gpu_queue == 0.0 || kernel == 0.0) { return 0.0; }
    if (g_gpu_slot_gws == 0.0) { g_gpu_slot_gws = malloc(24.0); }
    cartan_set_i64(g_gpu_slot_gws, 0.0, gx);
    cartan_set_i64(g_gpu_slot_gws, 1.0, gy);
    cartan_set_i64(g_gpu_slot_gws, 2.0, gz);

    var work_dim = 1.0;
    if (gy > 1.0) { work_dim = 2.0; }
    if (gz > 1.0) { work_dim = 3.0; }

    let k_err = clEnqueueNDRangeKernel(g_gpu_queue, kernel, work_dim, 0.0, g_gpu_slot_gws, 0.0, 0.0, 0.0, 0.0);
    if (k_err == 0.0) { return 1.0; }
    return 0.0;
}

// Dispatches a pre-configured kernel directly with explicit global and local workgroup sizes (zero-allocation)
fn cartan_gpu_launch_local(kernel: ptr, gx: float, gy: float, gz: float, lx: float, ly: float, lz: float) -> float {
    if (g_gpu_queue == 0.0 || kernel == 0.0) { return 0.0; }
    if (g_gpu_slot_gws == 0.0) { g_gpu_slot_gws = malloc(24.0); }
    if (g_gpu_slot_lws == 0.0) { g_gpu_slot_lws = malloc(24.0); }
    cartan_set_i64(g_gpu_slot_gws, 0.0, gx);
    cartan_set_i64(g_gpu_slot_gws, 1.0, gy);
    cartan_set_i64(g_gpu_slot_gws, 2.0, gz);

    cartan_set_i64(g_gpu_slot_lws, 0.0, lx);
    cartan_set_i64(g_gpu_slot_lws, 1.0, ly);
    cartan_set_i64(g_gpu_slot_lws, 2.0, lz);

    var work_dim = 1.0;
    if (gy > 1.0) { work_dim = 2.0; }
    if (gz > 1.0) { work_dim = 3.0; }

    let k_err = clEnqueueNDRangeKernel(g_gpu_queue, kernel, work_dim, 0.0, g_gpu_slot_gws, g_gpu_slot_lws, 0.0, 0.0, 0.0);
    if (k_err == 0.0) { return 1.0; }
    return 0.0;
}

// Synchronizes GPU command execution
fn cartan_gpu_sync() -> float {
    if (g_gpu_queue == 0.0) { return 0.0; }
    let err = clFinish(g_gpu_queue);
    if (err == 0.0) { return 1.0; }
    return 0.0;
}

// Allocates contiguous 32-bit float host buffer
fn cartan_f32_buffer_alloc(count: float) -> ptr {
    var c = count;
    if (c < 1.0) { c = 1.0; }
    return malloc(c * 4.0);
}

// Sets 32-bit float in host buffer
fn cartan_f32_buffer_set(buf: ptr, idx: float, val: float) -> float {
    if (buf == 0.0) { return 0.0; }
    cartan_set_f32(buf, idx, val);
    return 1.0;
}

// Gets 32-bit float from host buffer
fn cartan_f32_buffer_get(buf: ptr, idx: float) -> float {
    if (buf == 0.0) { return 0.0; }
    return cartan_f32_at(buf, idx);
}

// Frees host buffer
fn cartan_f32_buffer_free(buf: ptr) -> float {
    if (buf != 0.0) {
        free(buf);
    }
    return 1.0;
}

// --- Unified Hardware GPU Acceleration Engine (WebGPU Native WGSL) ---

fn gpu_init() -> float {
    return cartan_wgpu_init();
}

fn gpu_alloc(size_bytes: float) -> ptr {
    return cartan_wgpu_create_buffer(size_bytes, 140.0);
}

fn gpu_write(buf: ptr, data: ptr, size_bytes: float) -> float {
    return cartan_wgpu_write_buffer(buf, 0.0, data, size_bytes);
}

fn gpu_read(buf: ptr, data: ptr, size_bytes: float) -> float {
    return cartan_wgpu_read_buffer(buf, 0.0, data, size_bytes);
}

fn gpu_create_pipeline(wgsl_source: string, entry_point: string) -> ptr {
    return cartan_wgpu_create_pipeline(wgsl_source, entry_point);
}

fn gpu_dispatch(pipe: ptr, buffers: ptr, num_buffers: float, gx: float, gy: float, gz: float) -> float {
    return cartan_wgpu_dispatch(pipe, buffers, num_buffers, gx, gy, gz);
}

fn gpu_launch_local(kernel: ptr, gx: float, gy: float, gz: float, lx: float, ly: float, lz: float) -> float {
    return cartan_gpu_launch_local(kernel, gx, gy, gz, lx, ly, lz);
}

fn gpu_sync() -> float {
    return cartan_wgpu_sync();
}

fn cartan_gpu_free_buffer(buf: ptr) -> float {
    if (buf == 0.0) { return 0.0; }
    let err = clReleaseMemObject(buf);
    if (err == 0.0) { return 1.0; }
    return 0.0;
}

fn gpu_free(buf: ptr) -> float {
    return cartan_wgpu_free_buffer(buf);
}

fn gpu_create_bind_group(pipe: ptr, buffers: ptr, num_buffers: float) -> ptr {
    return cartan_wgpu_create_bind_group(pipe, buffers, num_buffers);
}

fn gpu_free_bind_group(bg: ptr) -> float {
    return cartan_wgpu_free_bind_group(bg);
}

fn gpu_dispatch_fused_geglu_down(pipe_geglu: ptr, bg_geglu: ptr, pipe_down: ptr, bg_down: ptr, gx_geglu: float, gx_down: float) -> float {
    return cartan_wgpu_dispatch_fused_geglu_down(pipe_geglu, bg_geglu, pipe_down, bg_down, gx_geglu, gx_down);
}

fn gpu_dispatch_fused_geglu_down_read(pipe_geglu: ptr, bg_geglu: ptr, pipe_down: ptr, bg_down: ptr, gx_geglu: float, gx_down: float, gpu_out: ptr, dst_data: ptr, size_bytes: float) -> float {
    return cartan_wgpu_dispatch_fused_geglu_down_read(pipe_geglu, bg_geglu, pipe_down, bg_down, gx_geglu, gx_down, gpu_out, dst_data, size_bytes);
}



