import sys

def modify_file():
    with open('..\\\\CARTAN\\\\gpu_runtime\\\\src\\\\lib.rs', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. TENSOR_REGISTRY decl
    content = content.replace(
        'static mut TENSOR_REGISTRY: Vec<*mut Tensor> = Vec::new();',
        'use std::sync::Mutex;\\nuse once_cell::sync::Lazy;\\n\\nstatic TENSOR_REGISTRY: Lazy<Mutex<Vec<usize>>> = Lazy::new(|| Mutex::new(Vec::new()));'
    )
    
    # 2. alloc_tensor
    content = content.replace(
        'TENSOR_REGISTRY.push(t_ptr);',
        'TENSOR_REGISTRY.lock().unwrap().push(t_ptr as usize);'
    )

    # 3. space_id in allocs
    content = content.replace(
        'pub extern "C" fn cartan_tensor_alloc(size: u32) -> *mut Tensor {',
        'pub extern "C" fn cartan_tensor_alloc(size: u32, space_id: u32) -> *mut Tensor {'
    )
    content = content.replace(
        'pub extern "C" fn cartan_tensor_alloc_nd(rank: u32, d0: u32, d1: u32, d2: u32, d3: u32) -> *mut Tensor {',
        'pub extern "C" fn cartan_tensor_alloc_nd(rank: u32, d0: u32, d1: u32, d2: u32, d3: u32, space_id: u32) -> *mut Tensor {'
    )
    content = content.replace(
        'pub extern "C" fn cartan_alloc_sequence(size: i32) -> *mut Tensor {\\n    cartan_tensor_alloc(size as u32)',
        'pub extern "C" fn cartan_alloc_sequence(size: i32) -> *mut Tensor {\\n    cartan_tensor_alloc(size as u32, 0)'
    )
    
    # 4. closure captures
    content = content.replace(
        'let idx_a = get_tensor_index(i, &target_shape, &a_strides, &(*a).shape);',
        'let idx_a = get_tensor_index(i, &target_shape, &a_strides, &a_shape);'
    )
    content = content.replace(
        'let idx_b = get_tensor_index(i, &target_shape, &b_strides, &(*b).shape);',
        'let idx_b = get_tensor_index(i, &target_shape, &b_strides, &b_shape);'
    )
    
    # 5. Backward pass
    content = content.replace(
        'for i in (0..TENSOR_REGISTRY.len()).rev() {\\n            let t = TENSOR_REGISTRY[i];',
        'let registry = TENSOR_REGISTRY.lock().unwrap().clone();\\n        for i in (0..registry.len()).rev() {\\n            let t = registry[i] as *mut Tensor;'
    )
    
    # 6. Step pass
    content = content.replace(
        'for &t in &TENSOR_REGISTRY {\\n            if (*t).requires_grad && (*t).op == 0 {',
        'let registry_clone = TENSOR_REGISTRY.lock().unwrap().clone();\\n        for &t_raw in registry_clone.iter() {\\n            let t = t_raw as *mut Tensor;\\n            if (*t).requires_grad && (*t).op == 0 {'
    )
    
    # 7. Step pass OOM loop
    old_oom_loop = '''        // Free intermediate tensors to prevent OOM
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
        }'''
        
    new_oom_loop = '''        // Mutate the registry completely in-place with zero re-allocations
        TENSOR_REGISTRY.lock().unwrap().retain(|&t_raw| {
            let t = t_raw as *mut Tensor;
            if unsafe { (*t).op != 0 } {
                // Deallocate the underlying memory layers of intermediate nodes immediately
                unsafe {
                    let size = (*t).size;
                    let _data_vec = Vec::from_raw_parts((*t).data, size, size);
                    let _grad_vec = Vec::from_raw_parts((*t).grad, size, size);
                    let _tensor_box = Box::from_raw(t);
                }
                false // Drop this pointer from the registry
            } else {
                true // Keep leaf parameters pinned safely
            }
        });
        
        static mut STEP_COUNT: usize = 0;
        STEP_COUNT += 1;
        if STEP_COUNT % 10 == 0 {
            println!("Step {} completed, TENSOR_REGISTRY size: {}", STEP_COUNT, TENSOR_REGISTRY.lock().unwrap().len());
        }'''
        
    content = content.replace(old_oom_loop, new_oom_loop)
    
    # 8. Free compute graph
    old_graph = 'pub extern "C" fn cartan_free_compute_graph() {}'
    new_graph = '''pub extern "C" fn cartan_free_compute_graph() {
    let mut registry = TENSOR_REGISTRY.lock().unwrap();
    registry.retain(|&t_raw| {
        let t = t_raw as *mut Tensor;
        if unsafe { (*t).op != 0 } {
            unsafe {
                let size = (*t).size;
                let _data_vec = Vec::from_raw_parts((*t).data, size, size);
                let _grad_vec = Vec::from_raw_parts((*t).grad, size, size);
                let _tensor_box = Box::from_raw(t);
            }
            false
        } else {
            true
        }
    });
}'''
    content = content.replace(old_graph, new_graph)

    with open('..\\\\CARTAN\\\\gpu_runtime\\\\src\\\\lib.rs', 'w', encoding='utf-8') as f:
        f.write(content)

modify_file()
