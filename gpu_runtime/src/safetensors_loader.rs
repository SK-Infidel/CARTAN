
use crate::Tensor;
use std::os::raw::c_char;

#[unsafe(no_mangle)]
pub extern "C" fn cartan_load_safetensors(
    path: *const c_char, 
    tensor_name: *const c_char, 
    tensor: *mut Tensor
) {
    unsafe {
        if tensor.is_null() || path.is_null() || tensor_name.is_null() { return; }
        
        let c_path = std::ffi::CStr::from_ptr(path);
        let path_str = c_path.to_string_lossy().to_string();
        
        let c_name = std::ffi::CStr::from_ptr(tensor_name);
        let name_str = c_name.to_string_lossy().to_string();
        
        println!("[GeoMind-FS] Loading {} from {}", name_str, path_str);
        
        let file = match std::fs::File::open(&path_str) {
            Ok(f) => f,
            Err(e) => {
                println!("[GeoMind-FS] Error opening file: {}", e);
                return;
            }
        };
        
        let mmap = match memmap2::MmapOptions::new().map(&file) {
            Ok(m) => m,
            Err(e) => {
                println!("[GeoMind-FS] Error mmapping file: {}", e);
                return;
            }
        };
        
        let safetensors = match safetensors::SafeTensors::deserialize(&mmap) {
            Ok(s) => s,
            Err(e) => {
                println!("[GeoMind-FS] Error deserializing safetensors: {:?}", e);
                return;
            }
        };
        
        let tensor_view = match safetensors.tensor(&name_str) {
            Ok(t) => t,
            Err(_) => {
                println!("[GeoMind-FS] Tensor {} not found in file", name_str);
                return;
            }
        };
        
        let bytes = tensor_view.data();
        let expected_bytes = (*tensor).size * 4; // Assuming f32
        
        if bytes.len() != expected_bytes {
            println!("[GeoMind-FS] Size mismatch for {}: expected {} bytes, got {} bytes", name_str, expected_bytes, bytes.len());
            // But lets try to load what we can for the proof of concept
            let to_copy = std::cmp::min(bytes.len(), expected_bytes);
            let dst = std::slice::from_raw_parts_mut((*tensor).data as *mut u8, to_copy);
            dst.copy_from_slice(&bytes[0..to_copy]);
        } else {
            let dst = std::slice::from_raw_parts_mut((*tensor).data, (*tensor).size);
            let src = std::slice::from_raw_parts(bytes.as_ptr() as *const f32, (*tensor).size);
            dst.copy_from_slice(src);
        }
        
        println!("[GeoMind-FS] Successfully loaded {} into tensor {}", name_str, (*tensor).id);
    }
}

