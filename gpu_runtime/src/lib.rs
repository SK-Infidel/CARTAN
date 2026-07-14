#![allow(static_mut_refs)]
#![allow(unused)]
use rayon::prelude::*;
use std::os::raw::c_void;
use std::ptr;
use std::sync::atomic::{AtomicUsize, Ordering};
use rayon::prelude::*;

// Simple global registry to keep tensors alive for backward pass
static mut TENSOR_REGISTRY: Vec<*mut Tensor> = Vec::new();

#[repr(C)]
pub struct Tensor {
    pub data: *mut f32,
    pub grad: *mut f32,
    pub size: usize,
    pub rank: u32,
    pub shape: [u32; 4],
    pub id: usize,
    pub requires_grad: bool,
    // Graph pointers (for backward pass)
    // For simplicity, we assume up to 2 parents (binary ops)
    pub parent_a: *mut Tensor,
    pub parent_b: *mut Tensor,
    pub op: i32, // 0=Leaf, 1=Add, 2=Sub, 3=Mul, 4=MatMul
}

static ID_COUNTER: AtomicUsize = AtomicUsize::new(1);

fn alloc_tensor(size: usize, randomize: bool) -> *mut Tensor {
    let id = ID_COUNTER.fetch_add(1, Ordering::SeqCst);
    
    // Allocate data array
    let size_bytes = (size as usize) * 4;
    if size_bytes > 1000_000_000 {
        println!("[DEBUG] alloc_tensor called with size: {} ({} bytes)", size, size_bytes);
    }
    let mut data_vec = if randomize {
        vec![0.0f32; size]
    } else {
        let mut v = Vec::with_capacity(size);
        unsafe { v.set_len(size); }
        v
    };
    
    if randomize {
        // Initialize with a simple deterministic PRNG based on tensor ID and index
        // to break symmetry during training
        let mut state = (id as u64).wrapping_mul(6364136223846793005).wrapping_add(1);
        for i in 0..size {
            state ^= state << 13;
            state ^= state >> 7;
            state ^= state << 17;
            // Map to roughly -0.05 to 0.05
            let float_val = ((state & 0xFFFFFF) as f32 / 16777215.0) * 0.1 - 0.05;
            data_vec[i] = float_val;
        }
    }
    
    let data = data_vec.as_mut_ptr();
    std::mem::forget(data_vec);
    
    // Allocate grad array (starts at zero, can use with_capacity if we manually zero it where needed, but let's keep it safe for now, or just use with_capacity since it's overwritten by loss/matmul backward!)
    let mut grad_vec = if randomize {
        vec![0.0f32; size]
    } else {
        let mut v = Vec::with_capacity(size);
        unsafe { v.set_len(size); }
        // We must zero grad_vec because gradients accumulate!
        // Wait, par_iter_mut() could zero it much faster!
        use rayon::prelude::*;
        v.par_iter_mut().for_each(|x| *x = 0.0);
        v
    };
    let grad = grad_vec.as_mut_ptr();
    std::mem::forget(grad_vec);

    let t = Box::new(Tensor {
        data,
        grad,
        size,
        rank: 1,
        shape: [1, 1, 1, size as u32],
        id,
        requires_grad: true,
        parent_a: ptr::null_mut(),
        parent_b: ptr::null_mut(),
        op: 0,
    });
    
    let t_ptr = Box::into_raw(t);
    unsafe {
        TENSOR_REGISTRY.push(t_ptr);
    }
    t_ptr
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_tensor_alloc(size: u32) -> *mut Tensor {
    let ptr = alloc_tensor(size as usize, true);
    ptr
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_tensor_alloc_nd(rank: u32, d0: u32, d1: u32, d2: u32, d3: u32) -> *mut Tensor {
    let size = (if rank > 0 { d0 } else { 1 })
             * (if rank > 1 { d1 } else { 1 })
             * (if rank > 2 { d2 } else { 1 })
             * (if rank > 3 { d3 } else { 1 });
             
    let ptr = alloc_tensor(size as usize, true);
    unsafe {
        (*ptr).rank = rank;
        let mut s = [1; 4];
        if rank == 1 { s[3] = d0; }
        else if rank == 2 { s[2] = d0; s[3] = d1; }
        else if rank == 3 { s[1] = d0; s[2] = d1; s[3] = d2; }
        else if rank == 4 { s[0] = d0; s[1] = d1; s[2] = d2; s[3] = d3; }
        (*ptr).shape = s;
        if size > 250_000_000 {
            println!("[DEBUG] alloc_nd returned shape: {:?}", s);
        }
    }
    ptr
}

fn get_broadcast_strides(shape: &[u32; 4]) -> [usize; 4] {
    let mut strides = [0; 4];
    let mut current_stride = 1;
    for i in (0..4).rev() {
        if shape[i] > 1 {
            strides[i] = current_stride;
            current_stride *= shape[i] as usize;
        } else {
            strides[i] = 0; // Broadcast this dimension
        }
    }
    strides
}

fn get_target_shape(a: &Tensor, b: &Tensor) -> [u32; 4] {
    let mut target = [1; 4];
    for i in 0..4 {
        target[i] = std::cmp::max(a.shape[i], b.shape[i]);
    }
    target
}

fn get_target_size(target_shape: &[u32; 4]) -> usize {
    (target_shape[0] * target_shape[1] * target_shape[2] * target_shape[3]) as usize
}

fn get_tensor_index(i: usize, target_shape: &[u32; 4], strides: &[usize; 4], actual_shape: &[u32; 4]) -> usize {
    let mut temp = i;
    let i3 = (temp % (target_shape[3] as usize)) % (actual_shape[3] as usize); temp /= target_shape[3] as usize;
    let i2 = (temp % (target_shape[2] as usize)) % (actual_shape[2] as usize); temp /= target_shape[2] as usize;
    let i1 = (temp % (target_shape[1] as usize)) % (actual_shape[1] as usize); temp /= target_shape[1] as usize;
    let i0 = (temp % (target_shape[0] as usize)) % (actual_shape[0] as usize);
    
    (i0 * strides[0]) + (i1 * strides[1]) + (i2 * strides[2]) + (i3 * strides[3])
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_tensor_add(a: *mut Tensor, b: *mut Tensor) -> *mut Tensor {
    unsafe {
        if a.is_null() || b.is_null() { return ptr::null_mut(); }
        let target_shape = get_target_shape(&*a, &*b);
        let size = get_target_size(&target_shape);
        if size > 1000000000 { println!("[DEBUG] Huge alloc! a: {:?}, b: {:?}, size: {}", (*a).shape, (*b).shape, size); } let out = alloc_tensor(size, false);
        (*out).rank = 4;
        (*out).shape = target_shape;
        (*out).parent_a = a;
        (*out).parent_b = b;
        (*out).op = 1;
        
        let a_strides = get_broadcast_strides(&(*a).shape);
        let b_strides = get_broadcast_strides(&(*b).shape);
        let a_data = std::slice::from_raw_parts((*a).data, (*a).size);
        let b_data = std::slice::from_raw_parts((*b).data, (*b).size);
        let out_data = std::slice::from_raw_parts_mut((*out).data, size);
        
        let a_shape = (*a).shape;
        let b_shape = (*b).shape;
        out_data.par_iter_mut().enumerate().for_each(|(i, val)| {
            let idx_a = get_tensor_index(i, &target_shape, &a_strides, &a_shape);
            let idx_b = get_tensor_index(i, &target_shape, &b_strides, &b_shape);
            *val = a_data[idx_a] + b_data[idx_b];
        });
        
        out
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_tensor_sub(a: *mut Tensor, b: *mut Tensor) -> *mut Tensor {
    unsafe {
        if a.is_null() || b.is_null() { return ptr::null_mut(); }
        let target_shape = get_target_shape(&*a, &*b);
        let size = get_target_size(&target_shape);
        if size > 1000000000 { println!("[DEBUG] Huge alloc! a: {:?}, b: {:?}, size: {}", (*a).shape, (*b).shape, size); } let out = alloc_tensor(size, false);
        (*out).rank = 4;
        (*out).shape = target_shape;
        (*out).parent_a = a;
        (*out).parent_b = b;
        (*out).op = 2;
        
        let a_strides = get_broadcast_strides(&(*a).shape);
        let b_strides = get_broadcast_strides(&(*b).shape);
        let a_data = std::slice::from_raw_parts((*a).data, (*a).size);
        let b_data = std::slice::from_raw_parts((*b).data, (*b).size);
        let out_data = std::slice::from_raw_parts_mut((*out).data, size);
        
        let a_shape = (*a).shape;
        let b_shape = (*b).shape;
        out_data.par_iter_mut().enumerate().for_each(|(i, val)| {
            let idx_a = get_tensor_index(i, &target_shape, &a_strides, &a_shape);
            let idx_b = get_tensor_index(i, &target_shape, &b_strides, &b_shape);
            *val = a_data[idx_a] - b_data[idx_b];
        });
        
        out
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_tensor_mul(a: *mut Tensor, b: *mut Tensor) -> *mut Tensor {
    unsafe {
        if a.is_null() || b.is_null() { return ptr::null_mut(); }
        let target_shape = get_target_shape(&*a, &*b);
        let size = get_target_size(&target_shape);
        if size > 1000000000 { println!("[DEBUG] Huge alloc! a: {:?}, b: {:?}, size: {}", (*a).shape, (*b).shape, size); } let out = alloc_tensor(size, false);
        (*out).rank = 4;
        (*out).shape = target_shape;
        (*out).parent_a = a;
        (*out).parent_b = b;
        (*out).op = 3;
        
        let a_strides = get_broadcast_strides(&(*a).shape);
        let b_strides = get_broadcast_strides(&(*b).shape);
        let a_data = std::slice::from_raw_parts((*a).data, (*a).size);
        let b_data = std::slice::from_raw_parts((*b).data, (*b).size);
        let out_data = std::slice::from_raw_parts_mut((*out).data, size);
        
        let a_shape = (*a).shape;
        let b_shape = (*b).shape;
        out_data.par_iter_mut().enumerate().for_each(|(i, val)| {
            let idx_a = get_tensor_index(i, &target_shape, &a_strides, &a_shape);
            let idx_b = get_tensor_index(i, &target_shape, &b_strides, &b_shape);
            *val = a_data[idx_a] * b_data[idx_b];
        });
        
        out
    }
}


use std::collections::HashMap;
use std::sync::Mutex;
use wgpu::util::DeviceExt;
use lazy_static::lazy_static;

struct GpuContext {
    device: wgpu::Device,
    queue: wgpu::Queue,
    shader: wgpu::ShaderModule,
    matmul_pipeline: wgpu::ComputePipeline,
}

lazy_static! {
    static ref GPU_CTX: Mutex<GpuContext> = Mutex::new(init_wgpu());
}

fn init_wgpu() -> GpuContext {
    let instance = wgpu::Instance::new(wgpu::InstanceDescriptor { backends: wgpu::Backends::VULKAN, ..Default::default() });
    let adapter = pollster::block_on(instance.request_adapter(&wgpu::RequestAdapterOptions {
        power_preference: wgpu::PowerPreference::HighPerformance,
        force_fallback_adapter: false,
        ..Default::default()
    })).unwrap();
    println!("Selected Adapter: {:#?}", adapter.get_info());
    println!("Adapter Limits: {:#?}", adapter.limits());
    let (device, queue) = pollster::block_on(adapter.request_device(&wgpu::DeviceDescriptor {
        label: None,
        required_features: wgpu::Features::empty(),
        required_limits: adapter.limits(),
        ..Default::default()
    }, None)).unwrap();
    
    let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
        label: Some("Kernels"),
        source: wgpu::ShaderSource::Wgsl(include_str!("kernels.wgsl").into()),
    });

    let matmul_pipeline = device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
        label: Some("Matmul Pipeline"),
        layout: None,
        module: &shader,
        entry_point: "matmul",
        compilation_options: Default::default(),
        cache: None,
    });

    GpuContext {
        device, queue, shader, matmul_pipeline
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_tensor_matmul(a: *mut Tensor, b: *mut Tensor) -> *mut Tensor {
    unsafe {
        let m = (*a).shape[3];
        let k = (*b).shape[2];
        let n = (*b).shape[3];
        
        let out = alloc_tensor((m * n) as usize, false);
        (*out).shape = [1, 1, m, n];
        
        let ctx = GPU_CTX.lock().unwrap();
        let a_slice = std::slice::from_raw_parts((*a).data, (*a).size);
        let b_slice = std::slice::from_raw_parts((*b).data, (*b).size);
        
        let a_buf = ctx.device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("a"),
            contents: bytemuck::cast_slice(a_slice),
            usage: wgpu::BufferUsages::STORAGE,
        });
        
        let b_buf = ctx.device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("b"),
            contents: bytemuck::cast_slice(b_slice),
            usage: wgpu::BufferUsages::STORAGE,
        });
        
        let out_buf = ctx.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("out"),
            size: (m * n * 4) as u64,
            usage: wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_SRC,
            mapped_at_creation: false,
        });
        
        let shape_data: [u32; 3] = [m, k, n];
        let shape_buffer = ctx.device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("shape"),
            contents: bytemuck::cast_slice(&shape_data),
            usage: wgpu::BufferUsages::UNIFORM,
        });
        
        let bind_group_layout = ctx.matmul_pipeline.get_bind_group_layout(0);
        let bind_group = ctx.device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: None,
            layout: &bind_group_layout,
            entries: &[
                wgpu::BindGroupEntry { binding: 0, resource: a_buf.as_entire_binding() },
                wgpu::BindGroupEntry { binding: 1, resource: b_buf.as_entire_binding() },
                wgpu::BindGroupEntry { binding: 2, resource: out_buf.as_entire_binding() },
                wgpu::BindGroupEntry { binding: 3, resource: shape_buffer.as_entire_binding() }
            ],
        });
        
        let mut encoder = ctx.device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });
        {
            let mut cpass = encoder.begin_compute_pass(&wgpu::ComputePassDescriptor {
                label: None,
                timestamp_writes: None,
            });
            cpass.set_pipeline(&ctx.matmul_pipeline);
            cpass.set_bind_group(0, &bind_group, &[]);
            cpass.dispatch_workgroups((n + 15) / 16, (m + 15) / 16, 1);
        }
        
        let staging = ctx.device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("staging"),
            size: (m * n * 4) as u64,
            usage: wgpu::BufferUsages::MAP_READ | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        encoder.copy_buffer_to_buffer(&out_buf, 0, &staging, 0, (m * n * 4) as u64);
        
        ctx.queue.submit(Some(encoder.finish()));
        
        let buffer_slice = staging.slice(..);
        let (sender, receiver) = std::sync::mpsc::channel();
        buffer_slice.map_async(wgpu::MapMode::Read, move |v| sender.send(v).unwrap());
        
        ctx.device.poll(wgpu::Maintain::wait());
        receiver.recv().unwrap().unwrap();
        
        let data = buffer_slice.get_mapped_range();
        let result: &[f32] = bytemuck::cast_slice(&*data);
        let out_slice = std::slice::from_raw_parts_mut((*out).data, (*out).size);
        out_slice.copy_from_slice(result);
        drop(data);
        staging.unmap();
        
        (*out).parent_a = a;
        (*out).parent_b = b;
        (*out).op = 4;
        
        out
    }
}


#[unsafe(no_mangle)]
pub extern "C" fn cartan_tensor_backward(loss: *mut Tensor) {
    unsafe {
        let loss_size = (*loss).size;
        let loss_grad = std::slice::from_raw_parts_mut((*loss).grad, loss_size);
        for i in 0..loss_size {
            loss_grad[i] = 1.0;
        }
        
        for i in (0..TENSOR_REGISTRY.len()).rev() {
            let t = TENSOR_REGISTRY[i];
            let op = (*t).op;
            if op == 0 { continue; }
            
            let parent_a = (*t).parent_a;
            let parent_b = (*t).parent_b;
            
            let size = (*t).size;
            let t_grad = std::slice::from_raw_parts((*t).grad, size);
            
            if op == 4 {
                if !parent_a.is_null() && !parent_b.is_null() {
                    let a_shape = (*parent_a).shape;
                    let b_shape = (*parent_b).shape;
                    let m = a_shape[2] as usize;
                    let k_dim = a_shape[3] as usize;
                    let n = b_shape[3] as usize;
                    let batch_a = (a_shape[0] * a_shape[1]) as usize;
                    let batch_b = (b_shape[0] * b_shape[1]) as usize;
                    let batch = std::cmp::max(batch_a, batch_b);
                    
                    let a_grad = std::slice::from_raw_parts_mut((*parent_a).grad, (*parent_a).size);
                    let b_grad = std::slice::from_raw_parts_mut((*parent_b).grad, (*parent_b).size);
                    let a_data = std::slice::from_raw_parts((*parent_a).data, (*parent_a).size);
                    let b_data = std::slice::from_raw_parts((*parent_b).data, (*parent_b).size);
                    
                    for b_idx in 0..batch {
                        let a_b_idx = if batch_a == 1 { 0 } else { b_idx };
                        let b_b_idx = if batch_b == 1 { 0 } else { b_idx };
                        let a_ptr = a_data[a_b_idx * (m * k_dim)..].as_ptr();
                        let b_ptr = b_data[b_b_idx * (k_dim * n)..].as_ptr();
                        let a_grad_ptr = a_grad[a_b_idx * (m * k_dim)..].as_mut_ptr();
                        let b_grad_ptr = b_grad[b_b_idx * (k_dim * n)..].as_mut_ptr();
                        let t_grad_ptr = t_grad[b_idx * (m * n)..].as_ptr();
                        
                        unsafe {
                            // a_grad += dL/dY * B^T
                            matrixmultiply::sgemm(
                                m, n, k_dim,
                                1.0,
                                t_grad_ptr, n as isize, 1,
                                b_ptr, 1, n as isize,
                                1.0,
                                a_grad_ptr, k_dim as isize, 1,
                            );
                            
                            // b_grad += A^T * dL/dY
                            matrixmultiply::sgemm(
                                k_dim, m, n,
                                1.0,
                                a_ptr, 1, k_dim as isize,
                                t_grad_ptr, n as isize, 1,
                                1.0,
                                b_grad_ptr, n as isize, 1,
                            );
                        }
                    }
                }
                continue;
            }
            
            if op == 6 {
                if !parent_a.is_null() && !parent_b.is_null() {
                    let tokens = &*parent_a;
                    let weights = &*parent_b;
                    let embed_dim = weights.shape[3] as usize;
                    let num_tokens = tokens.size;
                    let vocab_size = weights.shape[2] as usize;
                    
                    let tokens_data = std::slice::from_raw_parts(tokens.data, num_tokens);
                    let weights_grad = std::slice::from_raw_parts_mut(weights.grad, weights.size);
                    
                    for k in 0..num_tokens {
                        let token_id = tokens_data[k] as usize;
                        if token_id < vocab_size {
                            for j in 0..embed_dim {
                                weights_grad[token_id * embed_dim + j] += t_grad[k * embed_dim + j];
                            }
                        }
                    }
                }
                continue;
            }
            
            if !parent_a.is_null() && op != 0 {
                let a_grad = std::slice::from_raw_parts_mut((*parent_a).grad, (*parent_a).size);
                let a_strides = get_broadcast_strides(&(*parent_a).shape);
                
                let b_data_opt = if !parent_b.is_null() {
                    Some(std::slice::from_raw_parts((*parent_b).data, (*parent_b).size))
                } else { None };
                let b_strides = if !parent_b.is_null() { get_broadcast_strides(&(*parent_b).shape) } else { [0;4] };
                let b_shape = if !parent_b.is_null() { (*parent_b).shape } else { [1;4] };
                
                for j in 0..size {
                    let idx_a = get_tensor_index(j, &(*t).shape, &a_strides, &(*parent_a).shape);
                    if op == 3 || op == 5 {
                        let idx_b = get_tensor_index(j, &(*t).shape, &b_strides, &b_shape);
                        a_grad[idx_a] += t_grad[j] * b_data_opt.unwrap()[idx_b];
                    } else {
                        a_grad[idx_a] += t_grad[j]; // add / sub
                    }
                }
            }
            if !parent_b.is_null() && op != 0 {
                let b_grad = std::slice::from_raw_parts_mut((*parent_b).grad, (*parent_b).size);
                let a_data = std::slice::from_raw_parts((*parent_a).data, (*parent_a).size);
                let b_strides = get_broadcast_strides(&(*parent_b).shape);
                let a_strides = get_broadcast_strides(&(*parent_a).shape);
                
                for j in 0..size {
                    let idx_b = get_tensor_index(j, &(*t).shape, &b_strides, &(*parent_b).shape);
                    if op == 2 {
                        b_grad[idx_b] -= t_grad[j]; // sub
                    } else if op == 3 || op == 5 {
                        let idx_a = get_tensor_index(j, &(*t).shape, &a_strides, &(*parent_a).shape);
                        b_grad[idx_b] += t_grad[j] * a_data[idx_a];
                    } else {
                        b_grad[idx_b] += t_grad[j]; // add
                    }
                }
            }
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_tensor_step(lr: f32) {
    unsafe {
        for &t in &TENSOR_REGISTRY {
            if (*t).requires_grad && (*t).op == 0 {
                let size = (*t).size;
                let data = std::slice::from_raw_parts_mut((*t).data, size);
                let grad = std::slice::from_raw_parts_mut((*t).grad, size);
                for j in 0..size {
                    data[j] -= lr * grad[j];
                    grad[j] = 0.0; // zero grad
                }
            } else {
                // zero grad for non-leaves too
                let size = (*t).size;
                let grad = std::slice::from_raw_parts_mut((*t).grad, size);
                for j in 0..size {
                    grad[j] = 0.0;
                }
            }
        }
        
        // Free intermediate tensors to prevent OOM
        let mut new_registry = Vec::new();
        for &t in &TENSOR_REGISTRY {
            if (*t).op == 0 {
                new_registry.push(t);
            } else {
                let _ = Vec::from_raw_parts((*t).data, (*t).size, (*t).size);
                let _ = Vec::from_raw_parts((*t).grad, (*t).size, (*t).size);
                let _ = Box::from_raw(t);
            }
        }
        TENSOR_REGISTRY = new_registry;
        
        static mut STEP_COUNT: usize = 0;
        STEP_COUNT += 1;
        if STEP_COUNT % 10 == 0 {
            println!("Step {} completed, TENSOR_REGISTRY size: {}", STEP_COUNT, TENSOR_REGISTRY.len());
        }
    }
}

// Float fallbacks for Cartan primitives interoperability
#[unsafe(no_mangle)]
pub extern "C" fn cartan_float_to_tensor(val: f32) -> *mut Tensor {
    let t = alloc_tensor(1, true);
    unsafe {
        let data = std::slice::from_raw_parts_mut((*t).data, 1);
        data[0] = val;
    }
    t
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_tensor_to_float(t: *mut Tensor) -> f32 {
    unsafe {
        let data = std::slice::from_raw_parts((*t).data, 1);
        data[0]
    }
}

// Native VM Hooks Stubs
#[unsafe(no_mangle)]
pub extern "C" fn cartan_init_elastic_vocabulary() -> *mut Tensor { alloc_tensor(256, true) }
#[unsafe(no_mangle)]
pub extern "C" fn cartan_init_sieving_cache() -> *mut Tensor { alloc_tensor(256, true) }
#[unsafe(no_mangle)]
pub extern "C" fn cartan_init_fractal_attention() -> *mut Tensor { alloc_tensor(256, true) }
#[unsafe(no_mangle)]
pub extern "C" fn cartan_stream_init(_modalities: *const std::ffi::c_char, _uri: *const std::ffi::c_char) -> *mut Tensor { alloc_tensor(1, true) }
#[unsafe(no_mangle)]
pub extern "C" fn cartan_init_spike() -> *mut Tensor { alloc_tensor(256, true) }
#[unsafe(no_mangle)]
pub extern "C" fn cartan_init_neuron() -> *mut Tensor { alloc_tensor(256, true) }
#[unsafe(no_mangle)]
pub extern "C" fn cartan_emit_spike(_intensity: f32) {}
#[unsafe(no_mangle)]
pub extern "C" fn cartan_prune_graph(_threshold: f32) {}
#[unsafe(no_mangle)]
pub extern "C" fn cartan_poll_stream(_obj: *mut Tensor) -> *mut Tensor { alloc_tensor(256, true) }
#[unsafe(no_mangle)]
pub extern "C" fn cartan_load_dma() -> *mut Tensor { alloc_tensor(1, true) }

#[unsafe(no_mangle)]
pub extern "C" fn cartan_file_read_tokens(tensor_ptr: *mut Tensor, count: f32, file_ptr: *mut std::os::raw::c_void) -> f32 {
    unsafe {
        if tensor_ptr.is_null() || file_ptr.is_null() { return 0.0; }
        let t = &mut *tensor_ptr;
        let num_tokens = count as usize;
        let read_count = std::cmp::min(t.size, num_tokens);
        
        let mut buffer: Vec<i32> = vec![0; read_count];
        let items_read = libc::fread(
            buffer.as_mut_ptr() as *mut libc::c_void,
            4,
            read_count,
            file_ptr as *mut libc::FILE
        );
        
        let data_slice = std::slice::from_raw_parts_mut(t.data, t.size);
        for i in 0..items_read {
            data_slice[i] = buffer[i] as f32;
        }
        
        items_read as f32
    }
}

static mut CURRENT_FILE: *mut libc::FILE = std::ptr::null_mut();
static mut CURRENT_FILENAME: String = String::new();

#[unsafe(no_mangle)]
pub extern "C" fn cartan_file_read_batch(context_ptr: *mut Tensor, target_ptr: *mut Tensor, count: f32, file_ptr: *mut std::os::raw::c_void) -> f32 {
    unsafe {
        if context_ptr.is_null() || target_ptr.is_null() || file_ptr.is_null() { return 0.0; }
        
        let filename = std::ffi::CStr::from_ptr(file_ptr as *const i8).to_string_lossy().into_owned();
        
        if CURRENT_FILE.is_null() || filename != CURRENT_FILENAME {
            if !CURRENT_FILE.is_null() {
                libc::fclose(CURRENT_FILE);
            }
            CURRENT_FILENAME = filename.clone();
            let c_mode = std::ffi::CString::new("rb").unwrap();
            let c_name = std::ffi::CString::new(filename.clone()).unwrap();
            CURRENT_FILE = libc::fopen(c_name.as_ptr(), c_mode.as_ptr());
            if CURRENT_FILE.is_null() {
                println!("[GEOMIND FS] Error: Could not open dataset {}", filename);
                return 0.0;
            }
            println!("[GEOMIND FS] Dataset opened successfully. Ready to stream raw binary tokens...");
        }

        let c = &mut *context_ptr;
        let t = &mut *target_ptr;
        let num_tokens = count as usize;
        let read_count = std::cmp::min(c.size, num_tokens);
        
        let mut buffer: Vec<i32> = vec![0; read_count + 1];
        let items_read = libc::fread(
            buffer.as_mut_ptr() as *mut libc::c_void,
            4,
            read_count + 1,
            CURRENT_FILE
        );
        
        if items_read < read_count + 1 {
            libc::fseek(CURRENT_FILE, 0, libc::SEEK_SET); // Loop dataset
            return items_read as f32;
        }
        
        let c_data = std::slice::from_raw_parts_mut(c.data, c.size);
        let t_data = std::slice::from_raw_parts_mut(t.data, t.size);
        
        for i in 0..read_count {
            c_data[i] = buffer[i] as f32;
            t_data[i] = buffer[i + 1] as f32;
        }
        
        libc::fseek(CURRENT_FILE, -4, libc::SEEK_CUR);
        
        return read_count as f32;
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_tensor_embed(tokens_ptr: *mut Tensor, weights_ptr: *mut Tensor) -> *mut Tensor {
    unsafe {
        if tokens_ptr.is_null() || weights_ptr.is_null() { return std::ptr::null_mut(); }
        let tokens = &*tokens_ptr;
        let weights = &*weights_ptr;
        
        let vocab_size = weights.shape[2] as usize;
        let embed_dim = weights.shape[3] as usize;
        
        let num_tokens = tokens.size;
        let out_size = num_tokens * embed_dim;
        let out_t = alloc_tensor(out_size, false);
        let out = &mut *out_t;
        
        out.shape = [1, tokens.shape[2], tokens.shape[3], embed_dim as u32];
        out.rank = 3;
        out.parent_a = tokens_ptr;
        out.parent_b = weights_ptr;
        out.op = 6;
        
        let tokens_data = std::slice::from_raw_parts(tokens.data, num_tokens);
        let weights_data = std::slice::from_raw_parts(weights.data, vocab_size * embed_dim);
        let out_data = std::slice::from_raw_parts_mut(out.data, out_size);
        
        for i in 0..num_tokens {
            let token_id = tokens_data[i] as usize;
            if token_id < vocab_size {
                for j in 0..embed_dim {
                    out_data[i * embed_dim + j] = weights_data[token_id * embed_dim + j];
                }
            } else {
                for j in 0..embed_dim {
                    out_data[i * embed_dim + j] = 0.0;
                }
            }
        }
        
        out_t
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_tensor_cross_entropy_loss(logits_ptr: *mut Tensor, targets_ptr: *mut Tensor) -> f32 {
    unsafe {
        if logits_ptr.is_null() || targets_ptr.is_null() { return 0.0; }
        let logits = &mut *logits_ptr;
        let targets = &*targets_ptr;
        
        let num_tokens = targets.size;
        let vocab_size = logits.shape[3] as usize;
        
        let logits_data = std::slice::from_raw_parts(logits.data, num_tokens * vocab_size);
        let targets_data = std::slice::from_raw_parts(targets.data, num_tokens);
        
        let grad_t = alloc_tensor(logits.size, false);
        let g = &mut *grad_t;
        g.rank = logits.rank;
        g.shape = logits.shape;
        let g_data = std::slice::from_raw_parts_mut(g.data, g.size);
        
        let total_loss: f32 = g_data
            .par_chunks_exact_mut(vocab_size)
            .enumerate()
            .map(|(i, g_row)| {
                let target_id = targets_data[i] as usize;
                let row_start = i * vocab_size;
                let row_end = row_start + vocab_size;
                let row = &logits_data[row_start..row_end];
                
                let mut max_val = row[0];
                for j in 1..vocab_size {
                    if row[j] > max_val { max_val = row[j]; }
                }
                
                let mut sum_exp = 0.0;
                for j in 0..vocab_size {
                    sum_exp += (row[j] - max_val).exp();
                }
                
                let target_prob = if target_id < vocab_size {
                    (row[target_id] - max_val).exp() / sum_exp
                } else { 0.0001 };
                
                let loss = -target_prob.max(1e-7).ln();
                
                for j in 0..vocab_size {
                    let prob = (row[j] - max_val).exp() / sum_exp;
                    let grad_val = if j == target_id { prob - 1.0 } else { prob };
                    g_row[j] = grad_val / (num_tokens as f32);
                }
                
                loss
            })
            .sum();
        
        let out_grad = std::slice::from_raw_parts_mut(logits.grad, logits.size);
        out_grad.par_iter_mut().enumerate().for_each(|(i, v)| {
            *v += g_data[i];
        });
        
        libc::fflush(std::ptr::null_mut());
        
        total_loss / (num_tokens as f32)
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_tensor_mse_loss(output_ptr: *mut Tensor, target_ptr: *mut Tensor) -> f32 {
    unsafe {
        if output_ptr.is_null() || target_ptr.is_null() { return 0.0; }
        let output = &mut *output_ptr;
        let target = &*target_ptr;
        
        let size = std::cmp::min(output.size, target.size);
        if size == 0 { return 0.0; }
        
        let out_data = std::slice::from_raw_parts(output.data, size);
        let tgt_data = std::slice::from_raw_parts(target.data, size);
        
        let mut sum_sq_err = 0.0;
        for i in 0..size {
            let err = out_data[i] - tgt_data[i];
            sum_sq_err += err * err;
        }
        
        let loss = sum_sq_err / (size as f32);
        
        // Setup backward pass for MSE
        // dL/dy = 2 * (y - t) / N
        let mut grad_t = alloc_tensor(size, false);
        let g = &mut *grad_t;
        g.rank = output.rank;
        g.shape = output.shape;
        let g_data = std::slice::from_raw_parts_mut(g.data, size);
        for i in 0..size {
            g_data[i] = 2.0 * (out_data[i] - tgt_data[i]) / (size as f32);
        }
        
        // Emulate backprop graph connection by injecting the gradient directly into the output tensor
        let out_grad = std::slice::from_raw_parts_mut(output.grad, size);
        for i in 0..size {
            out_grad[i] += g_data[i];
        }
        
        loss
    }
}
#[unsafe(no_mangle)]
pub extern "C" fn cartan_alloc_sequence(size: i32) -> *mut Tensor {
    cartan_tensor_alloc(size as u32)
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_detect_hardware() -> f32 {
    println!("[GPU RUNTIME] Detecting hardware... WGPU backend active.");
    1.0
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_get_arg_float(key_ptr: *const std::ffi::c_char, default_val: f32) -> f32 {
    unsafe {
        if key_ptr.is_null() { return default_val; }
        let key = std::ffi::CStr::from_ptr(key_ptr).to_string_lossy().to_string();
        let mut iter = std::env::args();
        while let Some(arg) = iter.next() {
            if arg == key {
                if let Some(val) = iter.next() {
                    if let Ok(parsed) = val.parse::<f32>() {
                        return parsed;
                    }
                }
            }
        }
        default_val
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_get_arg_int(key_ptr: *const std::ffi::c_char, default_val: f32) -> f32 {
    cartan_get_arg_float(key_ptr, default_val)
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_get_arg_string(key_ptr: *const std::ffi::c_char, default_val: *const std::ffi::c_char) -> *const std::ffi::c_char {
    unsafe {
        if key_ptr.is_null() { return default_val; }
        let key = std::ffi::CStr::from_ptr(key_ptr).to_string_lossy().to_string();
        let mut iter = std::env::args();
        while let Some(arg) = iter.next() {
            if arg == key {
                if let Some(val) = iter.next() {
                    let c_str = std::ffi::CString::new(val).unwrap();
                    return c_str.into_raw();
                }
            }
        }
        default_val
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_has_arg(key_ptr: *const std::ffi::c_char) -> f32 {
    unsafe {
        if key_ptr.is_null() { return 0.0; }
        let key = std::ffi::CStr::from_ptr(key_ptr).to_string_lossy().to_string();
        for arg in std::env::args() {
            if arg == key {
                return 1.0;
            }
        }
        0.0
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_print_string(text_ptr: *const std::ffi::c_char) -> f32 {
    unsafe {
        if text_ptr.is_null() { return 0.0; }
        let text = std::ffi::CStr::from_ptr(text_ptr).to_string_lossy();
        print!("{}", text);
        0.0
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_console_read() -> *const std::ffi::c_char {
    let mut input = String::new();
    if std::io::stdin().read_line(&mut input).is_ok() {
        if let Ok(c_str) = std::ffi::CString::new(input.trim()) {
            return c_str.into_raw();
        }
    }
    std::ptr::null()
}

#[unsafe(no_mangle)]
pub extern "C" fn cartan_net_fetch_tokens(url_ptr: *const std::ffi::c_char, target_ptr: *mut Tensor) -> f32 {
    println!("[GPU RUNTIME] Fetching tokens from network not implemented.");
    0.0
}


mod safetensors_loader;

