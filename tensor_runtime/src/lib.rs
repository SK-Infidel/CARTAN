#![allow(static_mut_refs)]
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
    pub op: i32, // 0=Leaf, 1=Add, 2=Sub, 3=Mul, 4=MatMul, etc
    
    // Adam Optimizer State
    pub is_adam: bool,
    pub adam_m: *mut f32,
    pub adam_v: *mut f32,
    pub adam_t: u32,
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
        is_adam: false,
        adam_m: ptr::null_mut(),
        adam_v: ptr::null_mut(),
        adam_t: 0,
    });
    
    let t_ptr = Box::into_raw(t);
    unsafe {
        TENSOR_REGISTRY.push(t_ptr);
    }
    t_ptr
}

#[no_mangle]
pub extern "C" fn cartan_tensor_alloc(size: u32) -> *mut Tensor {
    let ptr = alloc_tensor(size as usize, true);
    ptr
}

#[no_mangle]
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

#[no_mangle]
pub extern "C" fn cartan_alloc_parameter_adam(size: u32) -> *mut Tensor {
    let ptr = cartan_tensor_alloc(size);
    unsafe {
        (*ptr).is_adam = true;
        
        let mut m_vec = vec![0.0f32; size as usize];
        let mut v_vec = vec![0.0f32; size as usize];
        (*ptr).adam_m = m_vec.as_mut_ptr();
        (*ptr).adam_v = v_vec.as_mut_ptr();
        std::mem::forget(m_vec);
        std::mem::forget(v_vec);
    }
    ptr
}

#[no_mangle]
pub extern "C" fn cartan_alloc_parameter_adam_nd(rank: u32, d0: u32, d1: u32, d2: u32, d3: u32) -> *mut Tensor {
    let ptr = cartan_tensor_alloc_nd(rank, d0, d1, d2, d3);
    unsafe {
        (*ptr).is_adam = true;
        let size = (*ptr).size;
        
        let mut m_vec = vec![0.0f32; size];
        let mut v_vec = vec![0.0f32; size];
        (*ptr).adam_m = m_vec.as_mut_ptr();
        (*ptr).adam_v = v_vec.as_mut_ptr();
        std::mem::forget(m_vec);
        std::mem::forget(v_vec);
    }
    ptr
}

#[no_mangle]
pub extern "C" fn cartan_alloc_sequence(size: u32) -> *mut Tensor {
    // A sequence is just a 1D tensor representing max length tokens/embeddings. 
    // Usually it would hold `Sequence` struct, but for now we back it as a Tensor.
    cartan_tensor_alloc(size)
}

#[no_mangle]
pub extern "C" fn cartan_alloc_block(size: u32) -> *mut Tensor {
    // Similar to sequence, block is a generic contiguous structure
    cartan_tensor_alloc(size)
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

#[no_mangle]
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

#[no_mangle]
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

#[no_mangle]
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

#[no_mangle]
pub extern "C" fn cartan_tensor_matmul(a: *mut Tensor, b: *mut Tensor) -> *mut Tensor {
    unsafe {
        if a.is_null() || b.is_null() { return ptr::null_mut(); }
        let a_shape = (*a).shape;
        let b_shape = (*b).shape;
        
        let m = a_shape[2] as usize;
        let k1 = a_shape[3] as usize;
        let k2 = b_shape[2] as usize;
        let n = b_shape[3] as usize;
        let batch_a = (a_shape[0] * a_shape[1]) as usize;
        let batch_b = (b_shape[0] * b_shape[1]) as usize;
        
        let batch = std::cmp::max(batch_a, batch_b);
        let b0 = std::cmp::max(a_shape[0], b_shape[0]);
        let b1 = std::cmp::max(a_shape[1], b_shape[1]);
        let target_shape = [b0, b1, m as u32, n as u32];
        let size = batch * m * n;
        
        if size > 1_000_000_000 {
            println!("[DEBUG MATMUL] Huge alloc detected! a_shape: {:?}, b_shape: {:?}, k1: {}, k2: {}, size: {}", a_shape, b_shape, k1, k2, size);
        }
        
        if k1 == k2 && k1 > 1 {
            if size > 1000000000 { println!("[DEBUG] Huge alloc! a: {:?}, b: {:?}, size: {}", (*a).shape, (*b).shape, size); } let out = alloc_tensor(size, false);
            (*out).rank = 4;
            (*out).shape = target_shape;
            (*out).parent_a = a;
            (*out).parent_b = b;
            (*out).op = 4;
            
            let a_data = std::slice::from_raw_parts((*a).data, (*a).size);
            let b_data = std::slice::from_raw_parts((*b).data, (*b).size);
            let out_data = std::slice::from_raw_parts_mut((*out).data, size);
            
            for b_idx in 0..batch {
                let a_b_idx = if batch_a == 1 { 0 } else { b_idx };
                let b_b_idx = if batch_b == 1 { 0 } else { b_idx };
                let a_ptr = a_data[a_b_idx * (m * k1)..].as_ptr();
                let b_ptr = b_data[b_b_idx * (k1 * n)..].as_ptr();
                let c_ptr = out_data[b_idx * (m * n)..].as_mut_ptr();
                
                    matrixmultiply::sgemm(
                        m, k1, n,
                        1.0,
                        a_ptr, k1 as isize, 1,
                        b_ptr, n as isize, 1,
                        0.0,
                        c_ptr, n as isize, 1,
                    );
            }
            return out;
        }
        
        let target_shape = get_target_shape(&*a, &*b);
        let size = get_target_size(&target_shape);
        if size > 1000000000 { println!("[DEBUG] Huge alloc! a: {:?}, b: {:?}, size: {}", (*a).shape, (*b).shape, size); } let out = alloc_tensor(size, false);
        (*out).rank = 4;
        (*out).shape = target_shape;
        (*out).parent_a = a;
        (*out).parent_b = b;
        (*out).op = 5;
        
        let a_strides = get_broadcast_strides(&(*a).shape);
        let b_strides = get_broadcast_strides(&(*b).shape);
        let a_data = std::slice::from_raw_parts((*a).data, (*a).size);
        let b_data = std::slice::from_raw_parts((*b).data, (*b).size);
        let out_data = std::slice::from_raw_parts_mut((*out).data, size);
        
        for i in 0..size {
            let idx_a = get_tensor_index(i, &target_shape, &a_strides, &(*a).shape);
            let idx_b = get_tensor_index(i, &target_shape, &b_strides, &(*b).shape);
            out_data[i] = a_data[idx_a] * b_data[idx_b];
        }
        
        out
    }
}

#[no_mangle]
pub extern "C" fn cartan_tensor_matmul_minkowski(a: *mut Tensor, b: *mut Tensor) -> *mut Tensor {
    // Minkowski metric (-+++). We compute standard matmul, then adjust the 0th dimension.
    let out = cartan_tensor_matmul(a, b);
    unsafe {
        if !out.is_null() && !a.is_null() && !b.is_null() {
            (*out).op = 8; // Opcode for Minkowski
            let m = (*a).shape[2] as usize;
            let n = (*b).shape[3] as usize;
            let k_dim = (*a).shape[3] as usize;
            let batch = ((*out).shape[0] * (*out).shape[1]) as usize;
            
            let a_data = std::slice::from_raw_parts((*a).data, (*a).size);
            let b_data = std::slice::from_raw_parts((*b).data, (*b).size);
            let out_data = std::slice::from_raw_parts_mut((*out).data, (*out).size);
            
            for b_idx in 0..batch {
                for i in 0..m {
                    for j in 0..n {
                        let a_val0 = a_data[b_idx * (m * k_dim) + i * k_dim + 0];
                        let b_val0 = b_data[b_idx * (k_dim * n) + 0 * n + j];
                        // Subtract 2 * A_i0 * B_0j to change + to -
                        out_data[b_idx * (m * n) + i * n + j] -= 2.0 * a_val0 * b_val0;
                    }
                }
            }
        }
    }
    out
}

#[no_mangle]
pub extern "C" fn cartan_tensor_matmul_poincare(a: *mut Tensor, b: *mut Tensor) -> *mut Tensor {
    // Prototype first-order approximation: regular matmul forward pass
    // Backward pass will apply the hyperbolic inverse metric tensor.
    let out = cartan_tensor_matmul(a, b);
    unsafe {
        if !out.is_null() {
            (*out).op = 9; // Opcode for Poincare
        }
    }
    out
}

#[no_mangle]
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
                continue;
            }
            
            if op == 8 || op == 9 {
                // Minkowski (8) or Poincare (9) Geometric Backward Pass
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
                        
                        // We need temporary gradient buffers because we will apply the metric tensor
                        let mut a_grad_eucl = vec![0.0f32; m * k_dim];
                        let mut b_grad_eucl = vec![0.0f32; k_dim * n];
                        let t_grad_ptr = t_grad[b_idx * (m * n)..].as_ptr();
                        
                            matrixmultiply::sgemm(
                                m, n, k_dim,
                                1.0,
                                t_grad_ptr, n as isize, 1,
                                b_ptr, 1, n as isize,
                                0.0,
                                a_grad_eucl.as_mut_ptr(), k_dim as isize, 1,
                            );
                            
                            matrixmultiply::sgemm(
                                k_dim, m, n,
                                1.0,
                                a_ptr, 1, k_dim as isize,
                                t_grad_ptr, n as isize, 1,
                                0.0,
                                b_grad_eucl.as_mut_ptr(), n as isize, 1,
                            );
                        
                        // Apply Inverse Metric Tensor (g^-1) to warp gradients back to the manifold
                        if op == 8 {
                            // Minkowski Metric: g^-1 = diag(-1, 1, 1, 1)
                            for i in 0..m {
                                for j in 0..k_dim {
                                    let mut grad_val = a_grad_eucl[i * k_dim + j];
                                    if j == 0 { grad_val = -grad_val; }
                                    a_grad[a_b_idx * (m * k_dim) + i * k_dim + j] += grad_val;
                                }
                            }
                            for i in 0..k_dim {
                                for j in 0..n {
                                    let mut grad_val = b_grad_eucl[i * n + j];
                                    if i == 0 { grad_val = -grad_val; }
                                    b_grad[b_b_idx * (k_dim * n) + i * n + j] += grad_val;
                                }
                            }
                        } else if op == 9 {
                            // Poincare Disk Metric: g^-1 = ( (1 - ||x||^2)^2 ) / 4
                            // Compute row norms for a_data, apply to a_grad
                            for i in 0..m {
                                let mut norm_sq = 0.0;
                                for j in 0..k_dim {
                                    let v = a_data[a_b_idx * (m * k_dim) + i * k_dim + j];
                                    norm_sq += v * v;
                                }
                                // g^-1 scaling factor
                                let scale = ((1.0 - norm_sq).max(1e-5).powi(2)) / 4.0;
                                for j in 0..k_dim {
                                    a_grad[a_b_idx * (m * k_dim) + i * k_dim + j] += a_grad_eucl[i * k_dim + j] * scale;
                                }
                            }
                            // Column norms for b_data, apply to b_grad
                            for j in 0..n {
                                let mut norm_sq = 0.0;
                                for i in 0..k_dim {
                                    let v = b_data[b_b_idx * (k_dim * n) + i * n + j];
                                    norm_sq += v * v;
                                }
                                let scale = ((1.0 - norm_sq).max(1e-5).powi(2)) / 4.0;
                                for i in 0..k_dim {
                                    b_grad[b_b_idx * (k_dim * n) + i * n + j] += b_grad_eucl[i * n + j] * scale;
                                }
                            }
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

#[no_mangle]
pub extern "C" fn cartan_tensor_step(lr: f32) {
    let beta1 = 0.9f32;
    let beta2 = 0.999f32;
    let epsilon = 1e-8f32;

    unsafe {
        for &t in &TENSOR_REGISTRY {
            if (*t).requires_grad && (*t).op == 0 {
                let size = (*t).size;
                let data = std::slice::from_raw_parts_mut((*t).data, size);
                let grad = std::slice::from_raw_parts_mut((*t).grad, size);
                
                if (*t).is_adam {
                    (*t).adam_t += 1;
                    let t_step = (*t).adam_t as f32;
                    let bias_correction1 = 1.0 - beta1.powf(t_step);
                    let bias_correction2 = 1.0 - beta2.powf(t_step);
                    
                    let m = std::slice::from_raw_parts_mut((*t).adam_m, size);
                    let v = std::slice::from_raw_parts_mut((*t).adam_v, size);
                    
                    for j in 0..size {
                        let g = grad[j];
                        m[j] = beta1 * m[j] + (1.0 - beta1) * g;
                        v[j] = beta2 * v[j] + (1.0 - beta2) * g * g;
                        
                        let m_hat = m[j] / bias_correction1;
                        let v_hat = v[j] / bias_correction2;
                        
                        data[j] -= lr * m_hat / (v_hat.sqrt() + epsilon);
                        grad[j] = 0.0; // zero grad
                    }
                } else {
                    for j in 0..size {
                        data[j] -= lr * grad[j];
                        grad[j] = 0.0; // zero grad
                    }
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
#[no_mangle]
pub extern "C" fn cartan_float_to_tensor(val: f32) -> *mut Tensor {
    let t = alloc_tensor(1, true);
    unsafe {
        let data = std::slice::from_raw_parts_mut((*t).data, 1);
        data[0] = val;
    }
    t
}

#[no_mangle]
pub extern "C" fn cartan_tensor_to_float(t: *mut Tensor) -> f32 {
    unsafe {
        let data = std::slice::from_raw_parts((*t).data, 1);
        data[0]
    }
}

// Native VM Hooks Stubs
#[no_mangle]
pub extern "C" fn cartan_init_elastic_vocabulary() -> *mut Tensor { alloc_tensor(256, true) }
#[no_mangle]
pub extern "C" fn cartan_init_sieving_cache() -> *mut Tensor { alloc_tensor(256, true) }
#[no_mangle]
pub extern "C" fn cartan_init_fractal_attention() -> *mut Tensor { alloc_tensor(256, true) }
#[no_mangle]
pub extern "C" fn cartan_stream_init(_modalities: *const std::ffi::c_char, _uri: *const std::ffi::c_char) -> *mut Tensor { alloc_tensor(1, true) }
#[no_mangle]
pub extern "C" fn cartan_init_spike() -> *mut Tensor { alloc_tensor(256, true) }
#[no_mangle]
pub extern "C" fn cartan_init_neuron() -> *mut Tensor { alloc_tensor(256, true) }
#[no_mangle]
pub extern "C" fn cartan_emit_spike(_intensity: f32) {}
#[no_mangle]
pub extern "C" fn cartan_prune_graph(_threshold: f32) {}
#[no_mangle]
pub extern "C" fn cartan_poll_stream(_obj: *mut Tensor) -> *mut Tensor { alloc_tensor(256, true) }
#[no_mangle]
pub extern "C" fn cartan_load_dma() -> *mut Tensor { alloc_tensor(1, true) }

#[no_mangle]
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

#[no_mangle]
pub extern "C" fn cartan_file_read_batch(context_ptr: *mut Tensor, target_ptr: *mut Tensor, count: f32, file_ptr: *mut std::os::raw::c_void) -> f32 {
    unsafe {
        if context_ptr.is_null() || target_ptr.is_null() || file_ptr.is_null() { return 0.0; }
        let c = &mut *context_ptr;
        let t = &mut *target_ptr;
        let num_tokens = count as usize;
        let read_count = std::cmp::min(c.size, num_tokens);
        
        let mut buffer: Vec<i32> = vec![0; read_count + 1];
        let items_read = libc::fread(
            buffer.as_mut_ptr() as *mut libc::c_void,
            4,
            read_count + 1,
            file_ptr as *mut libc::FILE
        );
        
        if items_read < read_count + 1 {
            return items_read as f32;
        }
        
        let c_data = std::slice::from_raw_parts_mut(c.data, c.size);
        let t_data = std::slice::from_raw_parts_mut(t.data, t.size);
        
        for i in 0..read_count {
            c_data[i] = buffer[i] as f32;
            t_data[i] = buffer[i + 1] as f32;
        }
        
        libc::fseek(file_ptr as *mut libc::FILE, -4, libc::SEEK_CUR);
        libc::fflush(std::ptr::null_mut());
        
        read_count as f32
    }
}

#[no_mangle]
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

#[no_mangle]
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

#[no_mangle]
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
        let grad_t = alloc_tensor(size, false);
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

#[no_mangle]
pub extern "C" fn cartan_absorb_weights(path: *const std::ffi::c_char, tensor: *mut Tensor) {
    unsafe {
        if tensor.is_null() || path.is_null() { return; }
        let c_str = std::ffi::CStr::from_ptr(path);
        let path_str = c_str.to_string_lossy();
        println!("[AgentOS] cartan_absorb_weights: Absorbing weights from {:?} into tensor id={}", path_str, (*tensor).id);
        
        if let Ok(bytes) = std::fs::read(path_str.as_ref()) {
            let size = (*tensor).size;
            let data = std::slice::from_raw_parts_mut((*tensor).data, size);
            let floats_to_read = std::cmp::min(size, bytes.len() / 4);
            for i in 0..floats_to_read {
                let mut b = [0u8; 4];
                b.copy_from_slice(&bytes[i*4..(i+1)*4]);
                data[i] = f32::from_ne_bytes(b);
            }
            println!("[AgentOS] Successfully absorbed {} parameters.", floats_to_read);
        } else {
            println!("[AgentOS] Warning: Failed to read weights from file {:?}", path_str);
        }
    }
}
  
  #[no_mangle]
  pub extern "C" fn cartan_tensor_free(t: *mut Tensor) {
      if t.is_null() { return; }
      unsafe {
          let size = (*t).size;
          let _data_vec = Vec::from_raw_parts((*t).data, size, size);
          let _grad_vec = Vec::from_raw_parts((*t).grad, size, size);
          if (*t).is_adam {
              let _m_vec = Vec::from_raw_parts((*t).adam_m, size, size);
              let _v_vec = Vec::from_raw_parts((*t).adam_v, size, size);
          }
          let mut idx_to_remove = None;
          for i in 0..TENSOR_REGISTRY.len() {
              if TENSOR_REGISTRY[i] == t {
                  idx_to_remove = Some(i);
                  break;
              }
          }
          if let Some(idx) = idx_to_remove {
              TENSOR_REGISTRY.remove(idx);
          }
          let _tensor_box = Box::from_raw(t);
      }
  }

  #[no_mangle]
  pub extern "C" fn cartan_free_compute_graph() {
      unsafe {
          let mut i = 0;
          while i < TENSOR_REGISTRY.len() {
              let t = TENSOR_REGISTRY[i];
              if (*t).op != 0 {
                  // Intermediate tensor, free it
                  let size = (*t).size;
                  let _data_vec = Vec::from_raw_parts((*t).data, size, size);
                  let _grad_vec = Vec::from_raw_parts((*t).grad, size, size);
                  let _tensor_box = Box::from_raw(t);
                  TENSOR_REGISTRY.remove(i);
              } else {
                  i += 1;
              }
          }
      }
  }
  
  #[no_mangle]
pub extern "C" fn cartan_project_vocab(source: *mut Tensor, target: *mut Tensor) {
    unsafe {
        if source.is_null() || target.is_null() { return; }
        println!("[AgentOS] cartan_project_vocab: Projecting vocab from tensor id={} to tensor id={}", (*source).id, (*target).id);
        let source_size = (*source).size;
        let target_size = (*target).size;
        let elements = std::cmp::min(source_size, target_size);
        let src_data = std::slice::from_raw_parts((*source).data, source_size);
        let tgt_data = std::slice::from_raw_parts_mut((*target).data, target_size);
        for i in 0..elements {
            tgt_data[i] = src_data[i];
        }
    }
}


#[no_mangle]
pub extern "C" fn cartan_fluid_precision_start(_primary: *mut std::ffi::c_void, _fallback: *mut std::ffi::c_void) {
    println!("[AgentOS] cartan_fluid_precision_start");
}

#[no_mangle]
pub extern "C" fn cartan_fluid_precision_end() {
    println!("[AgentOS] cartan_fluid_precision_end");
}

#[no_mangle]
pub extern "C" fn cartan_sparsity_start(block_size: i32, density: f32) {
    println!("[AgentOS] cartan_sparsity_start: block_size={}, density={}", block_size, density);
}

#[no_mangle]
pub extern "C" fn cartan_sparsity_end() {
    println!("[AgentOS] cartan_sparsity_end");
}

#[no_mangle]
pub extern "C" fn cartan_tensor_spherical_cosine_loss(output_ptr: *mut Tensor, target_ptr: *mut Tensor) -> f32 {
    unsafe {
        if output_ptr.is_null() || target_ptr.is_null() { return 0.0; }
        let output = &mut *output_ptr;
        let target = &*target_ptr;
        let size = std::cmp::min(output.size, target.size);
        if size == 0 { return 0.0; }
        
        let out_data = std::slice::from_raw_parts(output.data, size);
        let tgt_data = std::slice::from_raw_parts(target.data, size);
        
        let mut sum_out_sq = 0.0;
        let mut sum_tgt_sq = 0.0;
        for i in 0..size {
            sum_out_sq += out_data[i] * out_data[i];
            sum_tgt_sq += tgt_data[i] * tgt_data[i];
        }
        let out_norm = sum_out_sq.sqrt() + 1e-6;
        let tgt_norm = sum_tgt_sq.sqrt() + 1e-6;
        
        let mut dot = 0.0;
        for i in 0..size {
            dot += (out_data[i] / out_norm) * (tgt_data[i] / tgt_norm);
        }
        
        let shannon_weight = tgt_norm + 1.0;
        let loss = ((1.0 - dot) * shannon_weight) / (size as f32);
        
        let grad_t = alloc_tensor(size, false);
        let g = &mut *grad_t;
        g.rank = output.rank;
        g.shape = output.shape;
        let g_data = std::slice::from_raw_parts_mut(g.data, size);
        
        for i in 0..size {
            let x_hat = out_data[i] / out_norm;
            let t_hat = tgt_data[i] / tgt_norm;
            let grad_cos = (1.0 / out_norm) * (t_hat - x_hat * dot);
            let grad_geom = -grad_cos * shannon_weight;
            g_data[i] = grad_geom / (size as f32);
        }
        
        let out_grad = std::slice::from_raw_parts_mut(output.grad, size);
        for i in 0..size {
            out_grad[i] += g_data[i];
        }
        loss
    }
}

#[no_mangle]
pub extern "C" fn cartan_tensor_finsler_randers_loss(output_ptr: *mut Tensor, target_ptr: *mut Tensor) -> f32 {
    cartan_tensor_mse_loss(output_ptr, target_ptr)
}

#[no_mangle]
pub extern "C" fn cartan_tensor_betti_homology_loss(output_ptr: *mut Tensor, target_ptr: *mut Tensor) -> f32 {
    cartan_tensor_mse_loss(output_ptr, target_ptr)
}
#[no_mangle]
pub extern "C" fn cartan_net_fetch_tokens(url: *const std::ffi::c_char, out_tensor: *mut Tensor) -> f32 {
    unsafe {
        if url.is_null() || out_tensor.is_null() { return 0.0; }
        let c_str = std::ffi::CStr::from_ptr(url);
        let url_str = c_str.to_string_lossy();
        
        let out = &mut *out_tensor;
        
        match ureq::get(url_str.as_ref()).call() {
            Ok(response) => {
                let mut buf = Vec::new();
                use std::io::Read;
                if let Ok(_) = response.into_body().into_reader().read_to_end(&mut buf) {
                    let size = std::cmp::min(out.size, buf.len());
                    let out_data = std::slice::from_raw_parts_mut(out.data, out.size);
                    for i in 0..size {
                        out_data[i] = buf[i] as f32;
                    }
                    for i in size..out.size {
                        out_data[i] = 0.0;
                    }
                    return size as f32;
                }
            },
            Err(e) => {
                println!("[AgentOS] cartan_net_fetch_tokens failed: {}", e);
            }
        }
        0.0
    }
}

pub extern "C" fn cartan_align_spans(vocab_a_ptr: *const std::ffi::c_char, vocab_b_ptr: *const std::ffi::c_char, proj_ptr: *mut Tensor) {
    unsafe {
        if proj_ptr.is_null() || vocab_a_ptr.is_null() || vocab_b_ptr.is_null() {
            println!("[Runtime] align_spans error: Null pointer provided.");
            return;
        }
        
        let c_str_a = std::ffi::CStr::from_ptr(vocab_a_ptr);
        let path_a = match c_str_a.to_str() {
            Ok(s) => s,
            Err(_) => {
                println!("[Runtime] align_spans error: Invalid UTF-8 in vocab_a path.");
                return;
            }
        };
        
        let c_str_b = std::ffi::CStr::from_ptr(vocab_b_ptr);
        let path_b = match c_str_b.to_str() {
            Ok(s) => s,
            Err(_) => {
                println!("[Runtime] align_spans error: Invalid UTF-8 in vocab_b path.");
                return;
            }
        };
        
        println!("[Runtime] Executing Cross-Tokenizer Projection: Aligning spans from {} to {}", path_a, path_b);
        
        // Mock Implementation: Populate projection matrix with synthetic alignment data
        // In a real scenario, this would load the tokenizer configs, find common tokens, 
        // calculate subword span overlaps, and populate the sparse projection matrix.
        let t = &mut *proj_ptr;
        let size = t.size;
        let data = std::slice::from_raw_parts_mut(t.data, size);
        
        use rayon::prelude::*;
        data.par_iter_mut().enumerate().for_each(|(i, val)| {
            // Identity-like diagonal mapping + small off-diagonal noise
            let row = i / (t.shape[3] as usize);
            let col = i % (t.shape[3] as usize);
            if row == col {
                *val = 1.0;
            } else {
                let mut state = (i as u64).wrapping_add(84).wrapping_mul(6364136223846793005);
                state ^= state << 13;
                state ^= state >> 7;
                state ^= state << 17;
                let float_val = ((state & 0xFFFFFF) as f32 / 16777215.0) * 0.01;
                *val = float_val;
            }
        });
        
        println!("[Runtime] Successfully initialized cross-tokenizer projection matrix of size {}", size);
    }
}
#[no_mangle]
pub extern "C" fn cartan_console_read(out_buffer: *mut u8, max_len: i32) -> i32 {
    use std::io::Write;
    let _ = std::io::stdout().flush();
    let mut input = String::new();
    match std::io::stdin().read_line(&mut input) {
        Ok(len) => {
            let copy_len = std::cmp::min(len, max_len as usize - 1);
            unsafe {
                std::ptr::copy_nonoverlapping(input.as_ptr(), out_buffer, copy_len);
                *out_buffer.add(copy_len) = 0;
            }
            copy_len as i32
        }
        Err(_) => -1,
    }
}

#[no_mangle]
pub extern "C" fn cartan_has_arg(key: *const u8) -> f32 {
    let key_str = unsafe { std::ffi::CStr::from_ptr(key as *const i8).to_string_lossy() };
    for arg in std::env::args() {
        if arg == format!("--{}", key_str) || arg.starts_with(&format!("--{}=", key_str)) {
            return 1.0;
        }
    }
    0.0
}

#[no_mangle]
pub extern "C" fn cartan_get_arg_int(key: *const u8, default_val: f32) -> f32 {
    let key_str = unsafe { std::ffi::CStr::from_ptr(key as *const i8).to_string_lossy() };
    let prefix = format!("--{}=", key_str);
    for arg in std::env::args() {
        if arg.starts_with(&prefix) {
            if let Ok(val) = arg[prefix.len()..].parse::<f32>() {
                return val;
            }
        }
    }
    default_val
}

#[no_mangle]
pub extern "C" fn cartan_get_arg_float(key: *const u8, default_val: f32) -> f32 {
    let key_str = unsafe { std::ffi::CStr::from_ptr(key as *const i8).to_string_lossy() };
    let prefix = format!("--{}=", key_str);
    for arg in std::env::args() {
        if arg.starts_with(&prefix) {
            if let Ok(val) = arg[prefix.len()..].parse::<f32>() {
                return val;
            }
        }
    }
    default_val
}

#[no_mangle]
pub extern "C" fn cartan_get_arg_string(key: *const u8, default_val: *const u8) -> *const u8 {
    let key_str = unsafe { std::ffi::CStr::from_ptr(key as *const i8).to_string_lossy() };
    let prefix = format!("--{}=", key_str);
    for arg in std::env::args() {
        if arg.starts_with(&prefix) {
            let c_str = std::ffi::CString::new(arg[prefix.len()..].to_string()).unwrap();
            return c_str.into_raw() as *const u8;
        }
    }
    default_val
}
