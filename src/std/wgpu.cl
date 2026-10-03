// src/std/wgpu.cl
// CARTAN Standard Library: Pure Native Hardware WebGPU Engine (Zero C / Zero Rust Dependency)
// Drives physical GPU compute via wgpu-native C-ABI (NVIDIA RTX Ada / Direct3D 12 / Vulkan).

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/string.cl";

extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr) -> void;
extern fn memcpy(dest: ptr, src: ptr, count: float) -> ptr;
extern fn printf(fmt: string, val: ptr) -> float;
extern fn cartan_flush(f: float) -> float;

extern fn cartan_byte_at(p: ptr, offset: float) -> float;
extern fn cartan_set_byte(p: ptr, offset: float, val: float) -> void;
extern fn cartan_f32_at(p: ptr, offset: float) -> float;
extern fn cartan_set_f32(p: ptr, offset: float, val: float) -> void;
extern fn cartan_i32_at(p: ptr, offset: float) -> float;
extern fn cartan_set_i32(p: ptr, offset: float, val: float) -> void;
extern fn cartan_i64_at(p: ptr, offset: float) -> float;
extern fn cartan_set_i64(p: ptr, offset: float, val: float) -> void;

extern fn wgpuCreateInstance(desc: ptr) -> ptr;
extern fn wgpuInstanceRelease(instance: ptr) -> void;
extern fn wgpuInstanceProcessEvents(instance: ptr) -> void;
extern fn wgpuInstanceEnumerateAdapters(instance: ptr, options: ptr, adapters: ptr) -> float;
extern fn wgpuInstanceRequestAdapter(instance: ptr, options: ptr, callback_info: ptr) -> ptr;
extern fn wgpuAdapterRequestDevice(adapter: ptr, descriptor: ptr, callback_info: ptr) -> ptr;
extern fn wgpuAdapterRelease(adapter: ptr) -> void;
extern fn wgpuAdapterGetInfo(adapter: ptr, info: ptr) -> void;
extern fn wgpuAdapterGetLimits(adapter: ptr, limits: ptr) -> void;
extern fn wgpuDeviceGetQueue(device: ptr) -> ptr;
extern fn wgpuDeviceCreateBuffer(device: ptr, descriptor: ptr) -> ptr;
extern fn wgpuDeviceCreateShaderModule(device: ptr, descriptor: ptr) -> ptr;
extern fn wgpuDeviceCreateComputePipeline(device: ptr, descriptor: ptr) -> ptr;
extern fn wgpuComputePipelineGetBindGroupLayout(pipe: ptr, group_idx: float) -> ptr;
extern fn wgpuDeviceCreateBindGroup(device: ptr, descriptor: ptr) -> ptr;
extern fn wgpuBindGroupRelease(bind_group: ptr) -> void;
extern fn wgpuDeviceCreateCommandEncoder(device: ptr, descriptor: ptr) -> ptr;
extern fn wgpuCommandEncoderBeginComputePass(encoder: ptr, descriptor: ptr) -> ptr;
extern fn wgpuComputePassEncoderSetPipeline(pass: ptr, pipe: ptr) -> void;
extern fn wgpuComputePassEncoderSetBindGroup(pass: ptr, group_idx: float, group: ptr, dynamic_offset_count: float, dynamic_offsets: ptr) -> void;
extern fn wgpuComputePassEncoderDispatchWorkgroups(pass: ptr, workgroup_count_x: float, workgroup_count_y: float, workgroup_count_z: float) -> void;
extern fn wgpuComputePassEncoderEnd(pass: ptr) -> void;
extern fn wgpuComputePassEncoderRelease(pass: ptr) -> void;
extern fn wgpuCommandEncoderCopyBufferToBuffer(encoder: ptr, src: ptr, src_offset: float, dst: ptr, dst_offset: float, size: float) -> void;
extern fn wgpuCommandEncoderFinish(encoder: ptr, descriptor: ptr) -> ptr;
extern fn wgpuCommandEncoderRelease(encoder: ptr) -> void;
extern fn wgpuCommandBufferRelease(command_buffer: ptr) -> void;
extern fn wgpuQueueWriteBuffer(queue: ptr, buffer: ptr, offset: float, data: ptr, size: float) -> void;
extern fn wgpuQueueSubmit(queue: ptr, command_count: float, commands: ptr) -> void;
extern fn wgpuQueueRelease(queue: ptr) -> void;
extern fn wgpuBufferMapAsync(buffer: ptr, mode: float, offset: float, size: float, callback_info: ptr) -> ptr;
extern fn wgpuBufferGetMappedRange(buffer: ptr, offset: float, size: float) -> ptr;
extern fn wgpuBufferUnmap(buffer: ptr) -> void;
extern fn wgpuBufferDestroy(buffer: ptr) -> void;
extern fn wgpuBufferRelease(buffer: ptr) -> void;
extern fn wgpuDevicePoll(device: ptr, wait: float, wrapped_submission_index: ptr) -> float;
extern fn wgpuDeviceRelease(device: ptr) -> void;

var g_wgpu_initialized: float = 0.0;
var g_wgpu_instance: ptr = 0.0;
var g_wgpu_adapter: ptr = 0.0;
var g_wgpu_device: ptr = 0.0;
var g_wgpu_queue: ptr = 0.0;
var g_wgpu_map_done: float = 0.0;

var g_wgpu_adapter_name: ptr = 0.0;
var g_wgpu_vendor_id: float = 0.0;
var g_wgpu_adapter_type: float = 0.0;
var g_wgpu_backend_type: float = 0.0;
var g_wgpu_adapter_info: ptr = 0.0;

fn cartan_wgpu_get_device_name() -> ptr {
    return g_wgpu_adapter_name;
}

fn cartan_wgpu_get_vendor_id() -> float {
    return g_wgpu_vendor_id;
}

fn cartan_wgpu_get_adapter_type() -> float {
    return g_wgpu_adapter_type;
}

fn cartan_wgpu_get_backend_type() -> float {
    return g_wgpu_backend_type;
}

fn cartan_wgpu_on_adapter(status: ptr, adapter: ptr, message: ptr, ud1: ptr, ud2: ptr) -> void {
    g_wgpu_adapter = adapter;
}

fn cartan_wgpu_on_device(status: ptr, device: ptr, message: ptr, ud1: ptr, ud2: ptr) -> void {
    g_wgpu_device = device;
}

fn cartan_wgpu_on_map(status: ptr, message: ptr, ud1: ptr, ud2: ptr) -> void {
    g_wgpu_map_done = 1.0;
}

var g_wgpu_map_done_0: float = 0.0;
var g_wgpu_map_done_1: float = 0.0;
var g_wgpu_staging_buf_0: ptr = 0.0;
var g_wgpu_staging_buf_1: ptr = 0.0;
var g_wgpu_staging_size: float = 0.0;
var g_wgpu_staging_idx: float = 0.0;
var g_wgpu_map_cb_0: ptr = 0.0;
var g_wgpu_map_cb_1: ptr = 0.0;

fn cartan_wgpu_on_map_0(status: ptr, message: ptr, ud1: ptr, ud2: ptr) -> void {
    g_wgpu_map_done_0 = 1.0;
}

fn cartan_wgpu_on_map_1(status: ptr, message: ptr, ud1: ptr, ud2: ptr) -> void {
    g_wgpu_map_done_1 = 1.0;
}

// Native hardware WebGPU initialization hook
fn cartan_wgpu_init() -> float {
    if (g_wgpu_initialized == 1.0) {
        return 1.0;
    }

    g_wgpu_instance = wgpuCreateInstance(0.0);
    if (g_wgpu_instance == 0.0) {
        printf("[CARTAN WebGPU Error] wgpuCreateInstance failed.\n", 0.0);
        cartan_flush(0.0);
        return 0.0;
    }

    // Deterministic Hardware Adapter Enumeration & Priority Selection
    // Directly enumerates physical GPUs and prioritizes discrete NVIDIA RTX Ada on Direct3D 12
    let total_adapters = wgpuInstanceEnumerateAdapters(g_wgpu_instance, 0.0, 0.0);
    var chosen_adapter: ptr = 0.0;
    if (total_adapters > 0.0) {
        let adapters_arr = malloc(total_adapters * 8.0);
        wgpuInstanceEnumerateAdapters(g_wgpu_instance, 0.0, adapters_arr);

        // Pass 1: Prioritize discrete NVIDIA GPU with Direct3D 12 (VendorID == 4318.0 && BackendType == 4.0)
        var i = 0.0;
        while (i < total_adapters && chosen_adapter == 0.0) {
            let adp = adapters_arr[i];
            let info = malloc(96.0);
            var k = 0.0; while (k < 12.0) { info[k] = 0.0; k = k + 1.0; }
            wgpuAdapterGetInfo(adp, info);
            let vendor = cartan_i32_at(info, 20.0);
            let backend = cartan_i32_at(info, 18.0);
            if (vendor == 4318.0 && backend == 4.0) {
                chosen_adapter = adp;
            }
            free(info);
            i = i + 1.0;
        }

        // Pass 2: Fallback to discrete NVIDIA GPU on any backend (e.g. Vulkan)
        if (chosen_adapter == 0.0) {
            i = 0.0;
            while (i < total_adapters && chosen_adapter == 0.0) {
                let adp = adapters_arr[i];
                let info = malloc(96.0);
                var k = 0.0; while (k < 12.0) { info[k] = 0.0; k = k + 1.0; }
                wgpuAdapterGetInfo(adp, info);
                let vendor = cartan_i32_at(info, 20.0);
                if (vendor == 4318.0) {
                    chosen_adapter = adp;
                }
                free(info);
                i = i + 1.0;
            }
        }

        // Pass 3: Fallback to any discrete GPU (AdapterType == 1.0)
        if (chosen_adapter == 0.0) {
            i = 0.0;
            while (i < total_adapters && chosen_adapter == 0.0) {
                let adp = adapters_arr[i];
                let info = malloc(96.0);
                var k = 0.0; while (k < 12.0) { info[k] = 0.0; k = k + 1.0; }
                wgpuAdapterGetInfo(adp, info);
                let atype = cartan_i32_at(info, 19.0);
                if (atype == 1.0) {
                    chosen_adapter = adp;
                }
                free(info);
                i = i + 1.0;
            }
        }

        // Pass 4: Fallback to first available adapter
        if (chosen_adapter == 0.0) {
            chosen_adapter = adapters_arr[0.0];
        }

        free(adapters_arr);
    }

    g_wgpu_adapter = chosen_adapter;

    if (g_wgpu_adapter == 0.0) {
        printf("[CARTAN WebGPU Error] No hardware WebGPU adapter returned.\n", 0.0);
        cartan_flush(0.0);
        return 0.0;
    }

    // Inspect physical GPU hardware info
    if (g_wgpu_adapter_info == 0.0) {
        g_wgpu_adapter_info = malloc(96.0);
    }
    var ii = 0.0;
    while (ii < 12.0) {
        g_wgpu_adapter_info[ii] = 0.0;
        ii = ii + 1.0;
    }
    wgpuAdapterGetInfo(g_wgpu_adapter, g_wgpu_adapter_info);
    g_wgpu_adapter_name = g_wgpu_adapter_info[5.0];
    g_wgpu_vendor_id = cartan_i32_at(g_wgpu_adapter_info, 20.0);
    g_wgpu_adapter_type = cartan_i32_at(g_wgpu_adapter_info, 19.0);
    g_wgpu_backend_type = cartan_i32_at(g_wgpu_adapter_info, 18.0);

    // Query physical adapter limits to unlock maximum VRAM buffer binding size (2 GB on RTX 2000 Ada)
    let limits_buf = malloc(152.0);
    var li = 0.0;
    while (li < 19.0) { limits_buf[li] = 0.0; li = li + 1.0; }
    wgpuAdapterGetLimits(g_wgpu_adapter, limits_buf);

    let dev_desc = malloc(144.0);
    var di = 0.0;
    while (di < 18.0) { dev_desc[di] = 0.0; di = di + 1.0; }
    dev_desc[5.0] = limits_buf; // offset 40 = requiredLimits

    // Request Device
    let cb_device = malloc(64.0);
    cb_device[0.0] = 0.0;
    cb_device[1.0] = 2.0; // AllowProcessEvents
    cb_device[2.0] = cartan_wgpu_on_device;
    cb_device[3.0] = 0.0;
    cb_device[4.0] = 0.0;
    wgpuAdapterRequestDevice(g_wgpu_adapter, dev_desc, cb_device);
    wgpuInstanceProcessEvents(g_wgpu_instance);
    free(cb_device);
    free(dev_desc);
    free(limits_buf);

    if (g_wgpu_device == 0.0) {
        printf("[CARTAN WebGPU Error] No hardware WebGPU device returned.\n", 0.0);
        cartan_flush(0.0);
        return 0.0;
    }

    g_wgpu_queue = wgpuDeviceGetQueue(g_wgpu_device);
    if (g_wgpu_queue == 0.0) {
        printf("[CARTAN WebGPU Error] Failed to get device queue.\n", 0.0);
        cartan_flush(0.0);
        return 0.0;
    }

    g_wgpu_initialized = 1.0;
    if (g_wgpu_adapter_name != 0.0) {
        printf("[CARTAN WebGPU] Hardware Acceleration Engine Initialized on Physical GPU: %s\n", g_wgpu_adapter_name);
    } else {
        printf("[CARTAN WebGPU] Hardware Acceleration Engine Initialized on Physical GPU.\n", 0.0);
    }
    cartan_flush(0.0);
    return 1.0;
}

// Allocates physical device VRAM storage buffer
fn cartan_wgpu_create_buffer(size_bytes: float, usage: float) -> ptr {
    if (g_wgpu_initialized == 0.0) {
        let ok = cartan_wgpu_init();
        if (ok != 1.0) { return 0.0; }
    }
    if (g_wgpu_device == 0.0) { return 0.0; }

    var sz = size_bytes;
    if (sz < 16.0) { sz = 16.0; }

    // WGPUBufferDescriptor:
    // slot 0 (0..7): nextInChain = 0
    // slot 1 (8..15): label.data = 0
    // slot 2 (16..23): label.length = 0
    // slot 3 (24..31): usage
    // slot 4 (32..39): size
    // slot 5 (40..47): mappedAtCreation = 0
    let buf_desc = malloc(64.0);
    buf_desc[0.0] = 0.0;
    buf_desc[1.0] = 0.0;
    buf_desc[2.0] = 0.0;
    cartan_set_i64(buf_desc, 3.0, usage);
    cartan_set_i64(buf_desc, 4.0, sz);
    buf_desc[5.0] = 0.0;

    let buf = wgpuDeviceCreateBuffer(g_wgpu_device, buf_desc);
    free(buf_desc);
    return buf;
}

// Synchronously transfers data from host memory to physical GPU VRAM
fn cartan_wgpu_write_buffer(buffer: ptr, offset: float, src_data: ptr, size_bytes: float) -> float {
    if (g_wgpu_queue == 0.0 || buffer == 0.0 || src_data == 0.0) { return 0.0; }
    wgpuQueueWriteBuffer(g_wgpu_queue, buffer, offset, src_data, size_bytes);
    return 1.0;
}

var g_wgpu_persistent_staging_buf: ptr = 0.0;
var g_wgpu_persistent_staging_size: float = 0.0;
var g_wgpu_persistent_map_cb: ptr = 0.0;
var g_wgpu_persistent_cmd_list: ptr = 0.0;

// Synchronously transfers data from physical GPU VRAM to host memory via persistent staging buffer
fn cartan_wgpu_read_buffer(buffer: ptr, offset: float, dst_data: ptr, size_bytes: float) -> float {
    if (g_wgpu_device == 0.0 || g_wgpu_queue == 0.0 || buffer == 0.0 || dst_data == 0.0) { return 0.0; }

    // 1. Maintain persistent reusable staging buffer (MapRead | CopyDst = 1 | 8 = 9)
    if (g_wgpu_persistent_staging_buf == 0.0 || size_bytes > g_wgpu_persistent_staging_size) {
        if (g_wgpu_persistent_staging_buf != 0.0) {
            wgpuBufferDestroy(g_wgpu_persistent_staging_buf);
            wgpuBufferRelease(g_wgpu_persistent_staging_buf);
        }
        var alloc_sz = size_bytes;
        if (alloc_sz < 1048576.0) { alloc_sz = 1048576.0; }
        g_wgpu_persistent_staging_buf = cartan_wgpu_create_buffer(alloc_sz, 9.0);
        g_wgpu_persistent_staging_size = alloc_sz;
    }
    let staging_buf = g_wgpu_persistent_staging_buf;
    if (staging_buf == 0.0) { return 0.0; }

    // 2. Encode buffer copy
    let cmd_encoder = wgpuDeviceCreateCommandEncoder(g_wgpu_device, 0.0);
    wgpuCommandEncoderCopyBufferToBuffer(cmd_encoder, buffer, offset, staging_buf, 0.0, size_bytes);
    let cmd_buf = wgpuCommandEncoderFinish(cmd_encoder, 0.0);
    wgpuCommandEncoderRelease(cmd_encoder);

    // 3. Submit copy via persistent command list
    if (g_wgpu_persistent_cmd_list == 0.0) {
        g_wgpu_persistent_cmd_list = malloc(8.0);
    }
    g_wgpu_persistent_cmd_list[0.0] = cmd_buf;
    wgpuQueueSubmit(g_wgpu_queue, 1.0, g_wgpu_persistent_cmd_list);
    wgpuCommandBufferRelease(cmd_buf);

    // 4. Map staging buffer asynchronously via persistent callback struct
    g_wgpu_map_done = 0.0;
    if (g_wgpu_persistent_map_cb == 0.0) {
        g_wgpu_persistent_map_cb = malloc(64.0);
        g_wgpu_persistent_map_cb[0.0] = 0.0;
        g_wgpu_persistent_map_cb[1.0] = 2.0; // AllowProcessEvents
        g_wgpu_persistent_map_cb[2.0] = cartan_wgpu_on_map;
        g_wgpu_persistent_map_cb[3.0] = 0.0;
        g_wgpu_persistent_map_cb[4.0] = 0.0;
    }

    wgpuBufferMapAsync(staging_buf, 1.0, 0.0, size_bytes, g_wgpu_persistent_map_cb);

    // 5. Poll device events until mapped
    var poll_loop = 0.0;
    while (g_wgpu_map_done == 0.0 && poll_loop < 200.0) {
        wgpuDevicePoll(g_wgpu_device, 1.0, 0.0);
        wgpuInstanceProcessEvents(g_wgpu_instance);
        poll_loop = poll_loop + 1.0;
    }

    if (g_wgpu_map_done == 0.0) {
        printf("[CARTAN WebGPU Error] Buffer mapping timed out.\n", 0.0);
        cartan_flush(0.0);
        return 0.0;
    }

    // 6. Copy mapped memory to destination host buffer
    let mapped_ptr = wgpuBufferGetMappedRange(staging_buf, 0.0, size_bytes);
    if (mapped_ptr != 0.0) {
        memcpy(dst_data, mapped_ptr, size_bytes);
    }
    wgpuBufferUnmap(staging_buf);

    return 1.0;
}

// JIT-compiles WGSL GPU compute pipeline on hardware adapter
fn cartan_wgpu_create_pipeline(source: string, entry_point: string) -> ptr {
    if (g_wgpu_initialized == 0.0) {
        let ok = cartan_wgpu_init();
        if (ok != 1.0) { return 0.0; }
    }
    if (g_wgpu_device == 0.0) { return 0.0; }

    var wgsl_code = source;

    // Authentic WGSL source matching for standard kernels if empty source passed
    if (cartan_string_length(source) > 0.0 && cartan_string_contains(source, "@compute") != 0.0) {
        wgsl_code = source;
    } else if (cartan_string_eq(entry_point, "vec_fma") != 0.0) {
        wgsl_code = "@group(0) @binding(0) var<storage, read_write> in_a: array<f32>;\n@group(0) @binding(1) var<storage, read_write> in_b: array<f32>;\n@group(0) @binding(2) var<storage, read_write> out_c: array<f32>;\n\n@compute @workgroup_size(64, 1, 1)\nfn vec_fma(@builtin(global_invocation_id) gid: vec3<u32>) {\n    let idx = gid.x;\n    out_c[idx] = in_a[idx] * in_b[idx] + 5.0;\n}\n";
    } else if (cartan_string_eq(entry_point, "causal_attn_fwd") != 0.0) {
        wgsl_code = "@group(0) @binding(0) var<storage, read_write> in_x: array<f32>;\n@group(0) @binding(1) var<storage, read_write> out_attn: array<f32>;\n\n@compute @workgroup_size(32, 1, 1)\nfn causal_attn_fwd(@builtin(global_invocation_id) gid: vec3<u32>) {\n    let t_idx = i32(gid.x);\n    let T = 32;\n    let D = 2560;\n    if (t_idx >= T) { return; }\n    let scale = 0.125;\n    var total_w = 0.0;\n    for (var j = 0; j <= t_idx; j++) {\n        var dot = 0.0;\n        for (var d = 0; d < D; d++) {\n            dot += in_x[t_idx * D + d] * in_x[j * D + d];\n        }\n        total_w += exp(dot * scale);\n    }\n    var inv_w = 1.0 / max(total_w, 0.0001);\n    for (var d = 0; d < D; d++) {\n        var accum = 0.0;\n        for (var j = 0; j <= t_idx; j++) {\n            var dot = 0.0;\n            for (var k = 0; k < D; k++) {\n                dot += in_x[t_idx * D + k] * in_x[j * D + k];\n            }\n            accum += exp(dot * scale) * inv_w * in_x[j * D + d];\n        }\n        out_attn[t_idx * D + d] = in_x[t_idx * D + d] + accum * 0.1;\n    }\n}\n";
    } else if (cartan_string_eq(entry_point, "lie_streams_fwd") != 0.0) {
        wgsl_code = "@group(0) @binding(0) var<storage, read_write> in_h: array<f32>;\n@group(0) @binding(1) var<storage, read_write> out_h: array<f32>;\n\n@compute @workgroup_size(32, 1, 1)\nfn lie_streams_fwd(@builtin(global_invocation_id) gid: vec3<u32>) {\n    let t_idx = i32(gid.x);\n    if (t_idx >= 32) { return; }\n    let base = t_idx * 2560;\n    for (var i = 0; i < 320; i++) { let v = in_h[base + i]; out_h[base + i] = v * (cos(f32(i) * 0.05) * 0.25 + 0.75); }\n    var ssm = 0.0; for (var i = 320; i < 640; i++) { let v = in_h[base + i]; ssm = ssm * 0.85 + v * 0.15; out_h[base + i] = ssm * 1.1 + v * 0.5; }\n    for (var i = 640; i < 960; i++) { let v = in_h[base + i]; out_h[base + i] = v * sin(f32(i + 1) * 0.1) * 0.7071 + v * 0.5; }\n    for (var i = 960; i < 1280; i++) { let v = in_h[base + i]; out_h[base + i] = tanh(v * 0.5) * 1.2; }\n    for (var i = 1280; i < 1600; i++) { let v = in_h[base + i]; out_h[base + i] = v * 0.9 + sin(v * 2.0) * 0.1; }\n    for (var i = 1600; i < 1920; i++) { let v = in_h[base + i]; let a = v * v + 0.1; out_h[base + i] = sqrt(max(a, 0.001)) * 0.8 + v * 0.2; }\n    for (var i = 1920; i < 2240; i++) { let v = in_h[base + i]; out_h[base + i] = v * 0.95 + 0.05 * sin(f32(i) * 0.314); }\n    for (var i = 2240; i < 2560; i++) { let v = in_h[base + i]; out_h[base + i] = v * (1.0 + cos(f32(i) * 1.047) * 0.3); }\n}\n";
    } else if (cartan_string_eq(entry_point, "causal_loss_fwd") != 0.0) {
        wgsl_code = "@group(0) @binding(0) var<storage, read_write> logits: array<f32>;\n@group(0) @binding(1) var<storage, read_write> targets: array<f32>;\n@group(0) @binding(2) var<storage, read_write> ic_weights: array<f32>;\n@group(0) @binding(3) var<storage, read_write> loss_out: array<f32>;\n\n@compute @workgroup_size(32, 1, 1)\nfn causal_loss_fwd(@builtin(global_invocation_id) gid: vec3<u32>) {\n    let t_idx = i32(gid.x);\n    let T = 31;\n    let V = 2560;\n    if (t_idx >= T) { return; }\n    let base = t_idx * V;\n    let k = i32(targets[t_idx]);\n    if (k < 0 || k >= V) { return; }\n    let ic = ic_weights[t_idx];\n    var max_l = -10000.0;\n    for (var d = 0; d < V; d++) { let l = logits[base + d]; if (l > max_l) { max_l = l; } }\n    var sum_exp = 0.0;\n    for (var d = 0; d < V; d++) { sum_exp += exp(logits[base + d] - max_l); }\n    let log_z = max_l + log(max(sum_exp, 0.00001));\n    let tgt_l = logits[base + k];\n    loss_out[t_idx] = (log_z - tgt_l) * ic;\n}\n";
    }

    // 1. WGPUShaderSourceWGSL
    let wgsl_source = malloc(48.0);
    wgsl_source[0.0] = 0.0;
    cartan_set_i32(wgsl_source, 2.0, 2.0); // WGPUSType_ShaderSourceWGSL = 2
    cartan_set_i32(wgsl_source, 3.0, 0.0);
    wgsl_source[2.0] = wgsl_code;
    cartan_set_i64(wgsl_source, 3.0, cartan_string_length(wgsl_code));

    // 2. WGPUShaderModuleDescriptor
    let sm_desc = malloc(32.0);
    sm_desc[0.0] = wgsl_source;
    sm_desc[1.0] = 0.0;
    sm_desc[2.0] = 0.0;

    let shader_module = wgpuDeviceCreateShaderModule(g_wgpu_device, sm_desc);
    free(sm_desc);
    free(wgsl_source);

    if (shader_module == 0.0) {
        printf("[CARTAN WebGPU Error] wgpuDeviceCreateShaderModule failed for: %s\n", entry_point);
        cartan_flush(0.0);
        return 0.0;
    }

    // 3. WGPUComputePipelineDescriptor
    let cp_desc = malloc(96.0);
    cp_desc[0.0] = 0.0;
    cp_desc[1.0] = 0.0;
    cp_desc[2.0] = 0.0;
    cp_desc[3.0] = 0.0; // auto-layout
    cp_desc[4.0] = 0.0; // compute.nextInChain
    cp_desc[5.0] = shader_module;
    cp_desc[6.0] = entry_point;
    cartan_set_i64(cp_desc, 7.0, cartan_string_length(entry_point));
    cp_desc[8.0] = 0.0;
    cp_desc[9.0] = 0.0;

    let pipe = wgpuDeviceCreateComputePipeline(g_wgpu_device, cp_desc);
    free(cp_desc);

    if (pipe == 0.0) {
        printf("[CARTAN WebGPU Error] wgpuDeviceCreateComputePipeline failed for: %s\n", entry_point);
        cartan_flush(0.0);
        return 0.0;
    }

    return pipe;
}

// Dispatches hardware compute pipeline across grid dimensions
fn cartan_wgpu_dispatch(pipe: ptr, buffers: ptr, num_buffers: float, gx: float, gy: float, gz: float) -> float {
    if (g_wgpu_device == 0.0 || g_wgpu_queue == 0.0 || pipe == 0.0 || buffers == 0.0) { return 0.0; }

    // 1. Get bind group layout from pipeline
    let bg_layout = wgpuComputePipelineGetBindGroupLayout(pipe, 0.0);

    // 2. Build WGPUBindGroupEntry array (num_buffers entries, each 56 bytes = 7 slots of 8 bytes)
    let total_bytes = num_buffers * 56.0;
    let entries = malloc(total_bytes);

    var b_i = 0.0;
    while (b_i < num_buffers) {
        let b = cartan_tree_get_f32(buffers, b_i);
        let base_slot = b_i * 7.0;
        let base_i32 = b_i * 14.0;
        let base_i64 = b_i * 7.0;

        entries[base_slot] = 0.0; // nextInChain
        cartan_set_i32(entries, base_i32 + 2.0, b_i); // binding index
        cartan_set_i32(entries, base_i32 + 3.0, 0.0);
        entries[base_slot + 2.0] = b; // buffer
        cartan_set_i64(entries, base_i64 + 3.0, 0.0); // offset = 0
        
        // WGPU_WHOLE_SIZE (UINT64_MAX: 8 bytes of 0xFF)
        var bi = 0.0;
        let size_byte_offset = (base_i64 + 4.0) * 8.0;
        while (bi < 8.0) {
            cartan_set_byte(entries, size_byte_offset + bi, 255.0);
            bi = bi + 1.0;
        }

        entries[base_slot + 5.0] = 0.0; // sampler
        entries[base_slot + 6.0] = 0.0; // textureView

        b_i = b_i + 1.0;
    }

    // 3. Create Bind Group
    let bg_desc = malloc(48.0);
    bg_desc[0.0] = 0.0;
    bg_desc[1.0] = 0.0;
    bg_desc[2.0] = 0.0;
    bg_desc[3.0] = bg_layout;
    cartan_set_i64(bg_desc, 4.0, num_buffers);
    bg_desc[5.0] = entries;

    let bind_group = wgpuDeviceCreateBindGroup(g_wgpu_device, bg_desc);
    free(bg_desc);
    free(entries);

    if (bind_group == 0.0) {
        printf("[CARTAN WebGPU Error] wgpuDeviceCreateBindGroup failed.\n", 0.0);
        cartan_flush(0.0);
        return 0.0;
    }

    // 4. Encode Compute Pass
    let cmd_encoder = wgpuDeviceCreateCommandEncoder(g_wgpu_device, 0.0);
    let compute_pass = wgpuCommandEncoderBeginComputePass(cmd_encoder, 0.0);

    wgpuComputePassEncoderSetPipeline(compute_pass, pipe);
    wgpuComputePassEncoderSetBindGroup(compute_pass, 0.0, bind_group, 0.0, 0.0);

    // Compute workgroup counts:
    var wx = gx;
    if (wx > 1.0 && wx <= 64.0) {
        wx = 1.0;
    } else if (wx > 64.0) {
        wx = floor((wx + 63.0) / 64.0);
    }
    var wy = gy;
    if (wy > 1.0 && wy <= 64.0) {
        wy = 1.0;
    } else if (wy > 64.0) {
        wy = floor((wy + 63.0) / 64.0);
    }
    var wz = gz;
    if (wz > 1.0 && wz <= 64.0) {
        wz = 1.0;
    } else if (wz > 64.0) {
        wz = floor((wz + 63.0) / 64.0);
    }

    wgpuComputePassEncoderDispatchWorkgroups(compute_pass, wx, wy, wz);
    wgpuComputePassEncoderEnd(compute_pass);
    wgpuComputePassEncoderRelease(compute_pass);

    let cmd_buffer = wgpuCommandEncoderFinish(cmd_encoder, 0.0);
    wgpuCommandEncoderRelease(cmd_encoder);

    // 5. Submit to GPU Queue
    let cmd_list = malloc(8.0);
    cmd_list[0.0] = cmd_buffer;
    wgpuQueueSubmit(g_wgpu_queue, 1.0, cmd_list);
    free(cmd_list);
    wgpuCommandBufferRelease(cmd_buffer);
    wgpuBindGroupRelease(bind_group);

    return 1.0;
}

// Synchronizes GPU command execution
fn cartan_wgpu_sync() -> float {
    if (g_wgpu_device == 0.0) { return 0.0; }
    wgpuDevicePoll(g_wgpu_device, 1.0, 0.0);
    wgpuInstanceProcessEvents(g_wgpu_instance);
    return 1.0;
}

// Releases a VRAM storage buffer
fn cartan_wgpu_free_buffer(buf: ptr) -> float {
    if (buf != 0.0) {
        wgpuBufferDestroy(buf);
        wgpuBufferRelease(buf);
        return 1.0;
    }
    return 0.0;
}

// Pre-creates a persistent hardware Bind Group to eliminate descriptor table allocation churn
fn cartan_wgpu_create_bind_group(pipe: ptr, buffers: ptr, num_buffers: float) -> ptr {
    if (g_wgpu_device == 0.0 || pipe == 0.0 || buffers == 0.0) { return 0.0; }

    let bg_layout = wgpuComputePipelineGetBindGroupLayout(pipe, 0.0);
    let total_bytes = num_buffers * 56.0;
    let entries = malloc(total_bytes);

    var b_i = 0.0;
    while (b_i < num_buffers) {
        let b = cartan_tree_get_f32(buffers, b_i);
        let base_slot = b_i * 7.0;
        let base_i32 = b_i * 14.0;
        let base_i64 = b_i * 7.0;

        entries[base_slot] = 0.0; // nextInChain
        cartan_set_i32(entries, base_i32 + 2.0, b_i); // binding index
        cartan_set_i32(entries, base_i32 + 3.0, 0.0);
        entries[base_slot + 2.0] = b; // buffer
        cartan_set_i64(entries, base_i64 + 3.0, 0.0); // offset = 0
        
        // WGPU_WHOLE_SIZE (UINT64_MAX: 8 bytes of 0xFF)
        var bi = 0.0;
        let size_byte_offset = (base_i64 + 4.0) * 8.0;
        while (bi < 8.0) {
            cartan_set_byte(entries, size_byte_offset + bi, 255.0);
            bi = bi + 1.0;
        }

        entries[base_slot + 5.0] = 0.0; // sampler
        entries[base_slot + 6.0] = 0.0; // textureView
        b_i = b_i + 1.0;
    }

    let bg_desc = malloc(48.0);
    bg_desc[0.0] = 0.0;
    bg_desc[1.0] = 0.0;
    bg_desc[2.0] = 0.0;
    bg_desc[3.0] = bg_layout;
    cartan_set_i64(bg_desc, 4.0, num_buffers);
    bg_desc[5.0] = entries;

    let bind_group = wgpuDeviceCreateBindGroup(g_wgpu_device, bg_desc);
    free(bg_desc);
    free(entries);
    return bind_group;
}

// Releases a persistent hardware Bind Group
fn cartan_wgpu_free_bind_group(bg: ptr) -> float {
    if (bg != 0.0) {
        wgpuBindGroupRelease(bg);
        return 1.0;
    }
    return 0.0;
}

// Dispatches fused GeGLU and Down passes in a single command buffer with ONE queue submission
fn cartan_wgpu_dispatch_fused_geglu_down(pipe_geglu: ptr, bg_geglu: ptr, pipe_down: ptr, bg_down: ptr, gx_geglu: float, gx_down: float) -> float {
    if (g_wgpu_device == 0.0 || g_wgpu_queue == 0.0 || pipe_geglu == 0.0 || bg_geglu == 0.0 || pipe_down == 0.0 || bg_down == 0.0) {
        return 0.0;
    }

    var wx_geglu = gx_geglu;
    if (wx_geglu > 64.0) { wx_geglu = floor((wx_geglu + 63.0) / 64.0); } else { wx_geglu = 1.0; }

    var wx_down = gx_down;
    if (wx_down > 64.0) { wx_down = floor((wx_down + 63.0) / 64.0); } else { wx_down = 1.0; }

    let cmd_encoder = wgpuDeviceCreateCommandEncoder(g_wgpu_device, 0.0);

    // Pass 1: GeGLU (writes to out_act)
    let pass1 = wgpuCommandEncoderBeginComputePass(cmd_encoder, 0.0);
    wgpuComputePassEncoderSetPipeline(pass1, pipe_geglu);
    wgpuComputePassEncoderSetBindGroup(pass1, 0.0, bg_geglu, 0.0, 0.0);
    wgpuComputePassEncoderDispatchWorkgroups(pass1, wx_geglu, 1.0, 1.0);
    wgpuComputePassEncoderEnd(pass1);
    wgpuComputePassEncoderRelease(pass1);

    // Pass 2: Down projection (reads out_act, writes out_ffn)
    let pass2 = wgpuCommandEncoderBeginComputePass(cmd_encoder, 0.0);
    wgpuComputePassEncoderSetPipeline(pass2, pipe_down);
    wgpuComputePassEncoderSetBindGroup(pass2, 0.0, bg_down, 0.0, 0.0);
    wgpuComputePassEncoderDispatchWorkgroups(pass2, wx_down, 1.0, 1.0);
    wgpuComputePassEncoderEnd(pass2);
    wgpuComputePassEncoderRelease(pass2);

    let cmd_buffer = wgpuCommandEncoderFinish(cmd_encoder, 0.0);
    wgpuCommandEncoderRelease(cmd_encoder);

    // Submit ONCE to GPU Queue
    if (g_wgpu_persistent_cmd_list == 0.0) {
        g_wgpu_persistent_cmd_list = malloc(8.0);
    }
    g_wgpu_persistent_cmd_list[0.0] = cmd_buffer;
    wgpuQueueSubmit(g_wgpu_queue, 1.0, g_wgpu_persistent_cmd_list);
    wgpuCommandBufferRelease(cmd_buffer);

    return 1.0;
}

// Dispatches fused GeGLU, Down passes AND copies result to staging buffer in ONE single command submission
fn cartan_wgpu_dispatch_fused_geglu_down_read(
    pipe_geglu: ptr,
    bg_geglu: ptr,
    pipe_down: ptr,
    bg_down: ptr,
    gx_geglu: float,
    gx_down: float,
    gpu_out: ptr,
    dst_data: ptr,
    size_bytes: float
) -> float {
    if (g_wgpu_device == 0.0 || g_wgpu_queue == 0.0 || pipe_geglu == 0.0 || bg_geglu == 0.0 || pipe_down == 0.0 || bg_down == 0.0 || gpu_out == 0.0 || dst_data == 0.0) {
        return 0.0;
    }

    var wx_geglu = gx_geglu;
    if (wx_geglu > 64.0) { wx_geglu = floor((wx_geglu + 63.0) / 64.0); } else { wx_geglu = 1.0; }

    var wx_down = gx_down;
    if (wx_down > 64.0) { wx_down = floor((wx_down + 63.0) / 64.0); } else { wx_down = 1.0; }

    // Double-buffered staging buffer management (1MB minimum per staging buffer)
    var alloc_sz = size_bytes;
    if (alloc_sz < 1048576.0) { alloc_sz = 1048576.0; }
    if (g_wgpu_staging_buf_0 == 0.0 || alloc_sz > g_wgpu_staging_size) {
        if (g_wgpu_staging_buf_0 != 0.0) {
            wgpuBufferDestroy(g_wgpu_staging_buf_0);
            wgpuBufferRelease(g_wgpu_staging_buf_0);
        }
        if (g_wgpu_staging_buf_1 != 0.0) {
            wgpuBufferDestroy(g_wgpu_staging_buf_1);
            wgpuBufferRelease(g_wgpu_staging_buf_1);
        }
        g_wgpu_staging_buf_0 = cartan_wgpu_create_buffer(alloc_sz, 9.0);
        g_wgpu_staging_buf_1 = cartan_wgpu_create_buffer(alloc_sz, 9.0);
        g_wgpu_staging_size = alloc_sz;
        g_wgpu_staging_idx = 0.0;
        g_wgpu_map_done_0 = 0.0;
        g_wgpu_map_done_1 = 0.0;
    }

    if (g_wgpu_map_cb_0 == 0.0) {
        g_wgpu_map_cb_0 = malloc(64.0);
        g_wgpu_map_cb_0[0.0] = 0.0;
        g_wgpu_map_cb_0[1.0] = 2.0; // AllowProcessEvents
        g_wgpu_map_cb_0[2.0] = cartan_wgpu_on_map_0;
        g_wgpu_map_cb_0[3.0] = 0.0;
        g_wgpu_map_cb_0[4.0] = 0.0;

        g_wgpu_map_cb_1 = malloc(64.0);
        g_wgpu_map_cb_1[0.0] = 0.0;
        g_wgpu_map_cb_1[1.0] = 2.0; // AllowProcessEvents
        g_wgpu_map_cb_1[2.0] = cartan_wgpu_on_map_1;
        g_wgpu_map_cb_1[3.0] = 0.0;
        g_wgpu_map_cb_1[4.0] = 0.0;
    }

    // Ping-pong buffer selection
    var staging_buf = g_wgpu_staging_buf_0;
    var map_cb = g_wgpu_map_cb_0;
    let cur_idx = g_wgpu_staging_idx;
    if (cur_idx == 1.0) {
        staging_buf = g_wgpu_staging_buf_1;
        map_cb = g_wgpu_map_cb_1;
        if (g_wgpu_map_done_1 == 1.0) {
            wgpuBufferUnmap(staging_buf);
            g_wgpu_map_done_1 = 0.0;
        }
    } else {
        if (g_wgpu_map_done_0 == 1.0) {
            wgpuBufferUnmap(staging_buf);
            g_wgpu_map_done_0 = 0.0;
        }
    }
    if (staging_buf == 0.0) { return 0.0; }

    let cmd_encoder = wgpuDeviceCreateCommandEncoder(g_wgpu_device, 0.0);

    // Pass 1: GeGLU (writes to out_act)
    let pass1 = wgpuCommandEncoderBeginComputePass(cmd_encoder, 0.0);
    wgpuComputePassEncoderSetPipeline(pass1, pipe_geglu);
    wgpuComputePassEncoderSetBindGroup(pass1, 0.0, bg_geglu, 0.0, 0.0);
    wgpuComputePassEncoderDispatchWorkgroups(pass1, wx_geglu, 1.0, 1.0);
    wgpuComputePassEncoderEnd(pass1);
    wgpuComputePassEncoderRelease(pass1);

    // Pass 2: Down projection (reads out_act, writes out_ffn / gpu_out)
    let pass2 = wgpuCommandEncoderBeginComputePass(cmd_encoder, 0.0);
    wgpuComputePassEncoderSetPipeline(pass2, pipe_down);
    wgpuComputePassEncoderSetBindGroup(pass2, 0.0, bg_down, 0.0, 0.0);
    wgpuComputePassEncoderDispatchWorkgroups(pass2, wx_down, 1.0, 1.0);
    wgpuComputePassEncoderEnd(pass2);
    wgpuComputePassEncoderRelease(pass2);

    // Fused Buffer Copy: gpu_out -> staging_buf (ZERO extra queue submission!)
    wgpuCommandEncoderCopyBufferToBuffer(cmd_encoder, gpu_out, 0.0, staging_buf, 0.0, size_bytes);

    let cmd_buf = wgpuCommandEncoderFinish(cmd_encoder, 0.0);
    wgpuCommandEncoderRelease(cmd_encoder);

    // ONE SINGLE Queue Submission!
    if (g_wgpu_persistent_cmd_list == 0.0) {
        g_wgpu_persistent_cmd_list = malloc(8.0);
    }
    g_wgpu_persistent_cmd_list[0.0] = cmd_buf;
    wgpuQueueSubmit(g_wgpu_queue, 1.0, g_wgpu_persistent_cmd_list);
    wgpuCommandBufferRelease(cmd_buf);

    // Map staging buffer asynchronously
    if (cur_idx == 0.0) {
        g_wgpu_map_done_0 = 0.0;
    } else {
        g_wgpu_map_done_1 = 0.0;
    }
    wgpuBufferMapAsync(staging_buf, 1.0, 0.0, size_bytes, map_cb);

    // Poll until mapped
    var poll_loop = 0.0;
    var done = 0.0;
    if (cur_idx == 0.0) { done = g_wgpu_map_done_0; } else { done = g_wgpu_map_done_1; }
    while (done == 0.0 && poll_loop < 200.0) {
        wgpuDevicePoll(g_wgpu_device, 1.0, 0.0);
        wgpuInstanceProcessEvents(g_wgpu_instance);
        if (cur_idx == 0.0) { done = g_wgpu_map_done_0; } else { done = g_wgpu_map_done_1; }
        poll_loop = poll_loop + 1.0;
    }

    if (done == 0.0) {
        return 0.0;
    }

    let mapped_ptr = wgpuBufferGetMappedRange(staging_buf, 0.0, size_bytes);
    if (mapped_ptr != 0.0) {
        memcpy(dst_data, mapped_ptr, size_bytes);
        wgpuBufferUnmap(staging_buf);
        if (cur_idx == 0.0) { g_wgpu_map_done_0 = 0.0; } else { g_wgpu_map_done_1 = 0.0; }
        g_wgpu_staging_idx = 1.0 - cur_idx;
        return 1.0;
    }

    wgpuBufferUnmap(staging_buf);
    if (cur_idx == 0.0) { g_wgpu_map_done_0 = 0.0; } else { g_wgpu_map_done_1 = 0.0; }
    g_wgpu_staging_idx = 1.0 - cur_idx;
    return 0.0;
}

// Dispatches batched GeGLU and Down passes across N tokens and reads result back to dst_data
fn cartan_wgpu_dispatch_fused_geglu_down_batch_read(
    pipe_geglu: ptr,
    bg_geglu: ptr,
    pipe_down: ptr,
    bg_down: ptr,
    wx_geglu: float,
    wx_down: float,
    num_tokens: float,
    gpu_out: ptr,
    dst_data: ptr,
    size_bytes: float
) -> float {
    if (g_wgpu_device == 0.0 || g_wgpu_queue == 0.0 || pipe_geglu == 0.0 || bg_geglu == 0.0 || pipe_down == 0.0 || bg_down == 0.0 || gpu_out == 0.0 || dst_data == 0.0 || num_tokens <= 0.0) {
        return 0.0;
    }

    var alloc_sz = size_bytes;
    if (alloc_sz < 1048576.0) { alloc_sz = 1048576.0; }
    if (g_wgpu_staging_buf_0 == 0.0 || alloc_sz > g_wgpu_staging_size) {
        if (g_wgpu_staging_buf_0 != 0.0) {
            wgpuBufferDestroy(g_wgpu_staging_buf_0);
            wgpuBufferRelease(g_wgpu_staging_buf_0);
        }
        if (g_wgpu_staging_buf_1 != 0.0) {
            wgpuBufferDestroy(g_wgpu_staging_buf_1);
            wgpuBufferRelease(g_wgpu_staging_buf_1);
        }
        g_wgpu_staging_buf_0 = cartan_wgpu_create_buffer(alloc_sz, 9.0);
        g_wgpu_staging_buf_1 = cartan_wgpu_create_buffer(alloc_sz, 9.0);
        g_wgpu_staging_size = alloc_sz;
        g_wgpu_staging_idx = 0.0;
        g_wgpu_map_done_0 = 0.0;
        g_wgpu_map_done_1 = 0.0;
    }

    if (g_wgpu_map_cb_0 == 0.0) {
        g_wgpu_map_cb_0 = malloc(64.0);
        g_wgpu_map_cb_0[0.0] = 0.0;
        g_wgpu_map_cb_0[1.0] = 2.0; // AllowProcessEvents
        g_wgpu_map_cb_0[2.0] = cartan_wgpu_on_map_0;
        g_wgpu_map_cb_0[3.0] = 0.0;
        g_wgpu_map_cb_0[4.0] = 0.0;

        g_wgpu_map_cb_1 = malloc(64.0);
        g_wgpu_map_cb_1[0.0] = 0.0;
        g_wgpu_map_cb_1[1.0] = 2.0; // AllowProcessEvents
        g_wgpu_map_cb_1[2.0] = cartan_wgpu_on_map_1;
        g_wgpu_map_cb_1[3.0] = 0.0;
        g_wgpu_map_cb_1[4.0] = 0.0;
    }

    var staging_buf = g_wgpu_staging_buf_0;
    var map_cb = g_wgpu_map_cb_0;
    let cur_idx = g_wgpu_staging_idx;
    if (cur_idx == 1.0) {
        staging_buf = g_wgpu_staging_buf_1;
        map_cb = g_wgpu_map_cb_1;
        if (g_wgpu_map_done_1 == 1.0) {
            wgpuBufferUnmap(staging_buf);
            g_wgpu_map_done_1 = 0.0;
        }
    } else {
        if (g_wgpu_map_done_0 == 1.0) {
            wgpuBufferUnmap(staging_buf);
            g_wgpu_map_done_0 = 0.0;
        }
    }
    if (staging_buf == 0.0) { return 0.0; }

    let cmd_encoder = wgpuDeviceCreateCommandEncoder(g_wgpu_device, 0.0);

    // Pass 1: Batched GeGLU across N tokens
    let pass1 = wgpuCommandEncoderBeginComputePass(cmd_encoder, 0.0);
    wgpuComputePassEncoderSetPipeline(pass1, pipe_geglu);
    wgpuComputePassEncoderSetBindGroup(pass1, 0.0, bg_geglu, 0.0, 0.0);
    wgpuComputePassEncoderDispatchWorkgroups(pass1, wx_geglu, num_tokens, 1.0);
    wgpuComputePassEncoderEnd(pass1);
    wgpuComputePassEncoderRelease(pass1);

    // Pass 2: Batched Down projection across N tokens
    let pass2 = wgpuCommandEncoderBeginComputePass(cmd_encoder, 0.0);
    wgpuComputePassEncoderSetPipeline(pass2, pipe_down);
    wgpuComputePassEncoderSetBindGroup(pass2, 0.0, bg_down, 0.0, 0.0);
    wgpuComputePassEncoderDispatchWorkgroups(pass2, wx_down, num_tokens, 1.0);
    wgpuComputePassEncoderEnd(pass2);
    wgpuComputePassEncoderRelease(pass2);

    // Pass 3: Copy gpu_out to host-visible staging buffer
    wgpuCommandEncoderCopyBufferToBuffer(cmd_encoder, gpu_out, 0.0, staging_buf, 0.0, size_bytes);

    let cmd_buffer = wgpuCommandEncoderFinish(cmd_encoder, 0.0);
    wgpuCommandEncoderRelease(cmd_encoder);

    if (g_wgpu_persistent_cmd_list == 0.0) {
        g_wgpu_persistent_cmd_list = malloc(8.0);
    }
    g_wgpu_persistent_cmd_list[0.0] = cmd_buffer;
    wgpuQueueSubmit(g_wgpu_queue, 1.0, g_wgpu_persistent_cmd_list);
    wgpuCommandBufferRelease(cmd_buffer);

    // Request asynchronous buffer mapping
    if (cur_idx == 0.0) {
        g_wgpu_map_done_0 = 0.0;
    } else {
        g_wgpu_map_done_1 = 0.0;
    }
    wgpuBufferMapAsync(staging_buf, 1.0, 0.0, size_bytes, map_cb);

    // Poll until mapped
    var poll_loop = 0.0;
    var done = 0.0;
    if (cur_idx == 0.0) { done = g_wgpu_map_done_0; } else { done = g_wgpu_map_done_1; }
    while (done == 0.0 && poll_loop < 200.0) {
        wgpuDevicePoll(g_wgpu_device, 1.0, 0.0);
        wgpuInstanceProcessEvents(g_wgpu_instance);
        if (cur_idx == 0.0) { done = g_wgpu_map_done_0; } else { done = g_wgpu_map_done_1; }
        poll_loop = poll_loop + 1.0;
    }

    if (done == 0.0) {
        return 0.0;
    }

    let mapped_ptr = wgpuBufferGetMappedRange(staging_buf, 0.0, size_bytes);
    if (mapped_ptr != 0.0) {
        memcpy(dst_data, mapped_ptr, size_bytes);
        wgpuBufferUnmap(staging_buf);
        if (cur_idx == 0.0) { g_wgpu_map_done_0 = 0.0; } else { g_wgpu_map_done_1 = 0.0; }
        g_wgpu_staging_idx = 1.0 - cur_idx;
        return 1.0;
    }

    wgpuBufferUnmap(staging_buf);
    if (cur_idx == 0.0) { g_wgpu_map_done_0 = 0.0; } else { g_wgpu_map_done_1 = 0.0; }
    g_wgpu_staging_idx = 1.0 - cur_idx;
    return 0.0;
}


