with open('tensor_runtime/src/lib.rs', 'a', encoding='utf-8') as f:
    f.write('''
#[no_mangle]
pub extern "C" fn cartan_weight_decay(tensor: *mut Tensor, amount: f32) {
    unsafe {
        if tensor.is_null() { return; }
        // Formalized weight decay bounds: 
        let size = (*tensor).size;
        let data = std::slice::from_raw_parts_mut((*tensor).data, size);
        
        let decay_factor = 1.0 - amount;
        
        data.par_iter_mut().for_each(|val| {
            let mut v = *val * decay_factor;
            if v > 10.0 {
                v = 10.0;
            } else if v < -10.0 {
                v = -10.0;
            } else if v.abs() < 1e-7 {
                v = 0.0;
            }
            *val = v;
        });
    }
}
''')

with open('gpu_runtime/src/lib.rs', 'a', encoding='utf-8') as f:
    f.write('''
#[no_mangle]
pub extern "C" fn cartan_weight_decay(tensor: *mut Tensor, amount: f32) {
    unsafe {
        if tensor.is_null() { return; }
        let size = (*tensor).size;
        let data = std::slice::from_raw_parts_mut((*tensor).data, size);
        let decay_factor = 1.0 - amount;
        data.par_iter_mut().for_each(|val| {
            let mut v = *val * decay_factor;
            if v > 10.0 { v = 10.0; } 
            else if v < -10.0 { v = -10.0; } 
            else if v.abs() < 1e-7 { v = 0.0; }
            *val = v;
        });
    }
}
''')

with open('gpu_runtime/src/lib_combined.rs', 'a', encoding='utf-8') as f:
    f.write('''
#[no_mangle]
pub extern "C" fn cartan_weight_decay(tensor: *mut Tensor, amount: f32) {
    unsafe {
        if tensor.is_null() { return; }
        let size = (*tensor).size;
        let data = std::slice::from_raw_parts_mut((*tensor).data, size);
        let decay_factor = 1.0 - amount;
        data.par_iter_mut().for_each(|val| {
            let mut v = *val * decay_factor;
            if v > 10.0 { v = 10.0; } 
            else if v < -10.0 { v = -10.0; } 
            else if v.abs() < 1e-7 { v = 0.0; }
            *val = v;
        });
    }
}
''')
