import sys

def modify_file():
    with open('..\\\\CARTAN\\\\tensor_runtime\\\\src\\\\lib.rs', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. TENSOR_REGISTRY decl
    content = content.replace(
        'static mut TENSOR_REGISTRY: Vec<*mut Tensor> = Vec::new();',
        'use once_cell::sync::Lazy;\\nuse std::sync::Mutex;\\n\\nstatic TENSOR_REGISTRY: Lazy<Mutex<Vec<*mut Tensor>>> = Lazy::new(|| Mutex::new(Vec::new()));'
    )
    
    # 2. alloc_tensor
    content = content.replace(
        'TENSOR_REGISTRY.push(t_ptr);',
        'TENSOR_REGISTRY.lock().unwrap().push(t_ptr);'
    )
    
    # 3. cartan_tensor_backward
    content = content.replace(
        'for i in (0..TENSOR_REGISTRY.len()).rev() {\\n            let t = TENSOR_REGISTRY[i];',
        'let registry = TENSOR_REGISTRY.lock().unwrap().clone();\\n        for i in (0..registry.len()).rev() {\\n            let t = registry[i];'
    )
    
    # 4. cartan_tensor_step loop 1
    content = content.replace(
        'for &t in &TENSOR_REGISTRY {\\n            if (*t).requires_grad && (*t).op == 0 {',
        'let registry_clone = TENSOR_REGISTRY.lock().unwrap().clone();\\n        for &t in registry_clone.iter() {\\n            if (*t).requires_grad && (*t).op == 0 {'
    )
    
    # 5. cartan_tensor_step loop 2 & OOM fix
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
        TENSOR_REGISTRY.lock().unwrap().retain(|&t| {
            if unsafe { (*t).op != 0 } {
                // Deallocate the underlying memory layers of intermediate nodes immediately
                unsafe {
                    let size = (*t).size;
                    let _data_vec = Vec::from_raw_parts((*t).data, size, size);
                    let _grad_vec = Vec::from_raw_parts((*t).grad, size, size);
                    if (*t).is_adam {
                        let _m_vec = Vec::from_raw_parts((*t).adam_m, size, size);
                        let _v_vec = Vec::from_raw_parts((*t).adam_v, size, size);
                    }
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
    
    # 6. cartan_tensor_free
    old_free = '''            let mut idx_to_remove = None;
            for i in 0..TENSOR_REGISTRY.len() {
                if TENSOR_REGISTRY[i] == t {
                    idx_to_remove = Some(i);
                    break;
                }
            }
            if let Some(idx) = idx_to_remove {
                TENSOR_REGISTRY.remove(idx);
            }'''
            
    new_free = '''            let mut registry = TENSOR_REGISTRY.lock().unwrap();
            let mut idx_to_remove = None;
            for i in 0..registry.len() {
                if registry[i] == t {
                    idx_to_remove = Some(i);
                    break;
                }
            }
            if let Some(idx) = idx_to_remove {
                registry.remove(idx);
            }'''
    content = content.replace(old_free, new_free)
    
    # 7. cartan_free_compute_graph
    old_graph = '''    pub extern "C" fn cartan_free_compute_graph() {
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
    }'''
    
    new_graph = '''    pub extern "C" fn cartan_free_compute_graph() {
        let mut registry = TENSOR_REGISTRY.lock().unwrap();
        registry.retain(|&t| {
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
    
    # 8. cartan_tensor_matmul parallel fallback
    old_matmul = '''        for i in 0..size {
            let idx_a = get_tensor_index(i, &target_shape, &a_strides, &(*a).shape);
            let idx_b = get_tensor_index(i, &target_shape, &b_strides, &(*b).shape);
            out_data[i] = a_data[idx_a] * b_data[idx_b];
        }'''
        
    new_matmul = '''        // Boost fallback matmul speeds by spreading computations across active CPU threads
        out_data.par_iter_mut().enumerate().for_each(|(i, val)| {
            unsafe {
                let idx_a = get_tensor_index(i, &target_shape, &a_strides, &(*a).shape);
                let idx_b = get_tensor_index(i, &target_shape, &b_strides, &(*b).shape);
                *val = a_data[idx_a] * b_data[idx_b];
            }
        });'''
    content = content.replace(old_matmul, new_matmul)

    with open('..\\\\CARTAN\\\\tensor_runtime\\\\src\\\\lib.rs', 'w', encoding='utf-8') as f:
        f.write(content)

modify_file()
