use memmap2::{Mmap, MmapOptions};
use std::fs::File;
use std::io::{self, Cursor, Read, Write};
use std::path::Path;

pub const AEW_MAGIC: [u8; 4] = [b'A', b'E', b'W', 0x01];

#[derive(Debug, Clone)]
pub struct TensorHeader {
    pub name: String,
    pub data_type: u8, // 0 = f32, 1 = f16, etc.
    pub shape: Vec<u32>,
    pub data_offset: u64,
    pub data_length: u64,
}

pub struct AewFile {
    pub tensors: Vec<TensorHeader>,
    mmap: Mmap,
}

impl AewFile {
    pub fn load<P: AsRef<Path>>(path: P) -> io::Result<Self> {
        let file = File::open(path)?;
        
        let mmap = unsafe { MmapOptions::new().map(&file)? };
        
        let mut cursor = Cursor::new(&mmap[..]);
        let mut magic = [0u8; 4];
        cursor.read_exact(&mut magic)?;
        
        if magic != AEW_MAGIC {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "Invalid AEW magic bytes"));
        }
        
        let mut header_size_buf = [0u8; 4];
        cursor.read_exact(&mut header_size_buf)?;
        let _header_size = u32::from_le_bytes(header_size_buf);
        
        let mut tensor_count_buf = [0u8; 4];
        cursor.read_exact(&mut tensor_count_buf)?;
        let tensor_count = u32::from_le_bytes(tensor_count_buf);
        
        let mut tensors = Vec::new();
        
        for _ in 0..tensor_count {
            let mut name_len_buf = [0u8; 2];
            cursor.read_exact(&mut name_len_buf)?;
            let name_len = u16::from_le_bytes(name_len_buf);
            
            let mut name_buf = vec![0u8; name_len as usize];
            cursor.read_exact(&mut name_buf)?;
            let name = String::from_utf8(name_buf)
                .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "Invalid UTF-8 in tensor name"))?;
                
            let mut dt_buf = [0u8; 1];
            cursor.read_exact(&mut dt_buf)?;
            let data_type = dt_buf[0];
            
            let mut dims_count_buf = [0u8; 1];
            cursor.read_exact(&mut dims_count_buf)?;
            let dims_count = dims_count_buf[0];
            
            let mut shape = Vec::new();
            for _ in 0..dims_count {
                let mut dim_buf = [0u8; 4];
                cursor.read_exact(&mut dim_buf)?;
                shape.push(u32::from_le_bytes(dim_buf));
            }
            
            let mut offset_buf = [0u8; 8];
            cursor.read_exact(&mut offset_buf)?;
            let data_offset = u64::from_le_bytes(offset_buf);
            
            let mut len_buf = [0u8; 8];
            cursor.read_exact(&mut len_buf)?;
            let data_length = u64::from_le_bytes(len_buf);
            
            tensors.push(TensorHeader {
                name,
                data_type,
                shape,
                data_offset,
                data_length,
            });
        }
        
        Ok(Self {
            tensors,
            mmap,
        })
    }
    
    pub fn get_tensor_data(&self, name: &str) -> Option<&[u8]> {
        if let Some(header) = self.tensors.iter().find(|t| t.name == name) {
            let start = header.data_offset as usize;
            let end = start + header.data_length as usize;
            if end <= self.mmap.len() {
                return Some(&self.mmap[start..end]);
            }
        }
        None
    }
}

pub fn save_aew<P: AsRef<Path>>(path: P, tensors: &[(TensorHeader, &[u8])]) -> io::Result<()> {
    let mut file = File::create(path)?;
    
    file.write_all(&AEW_MAGIC)?;
    
    // Header size (placeholder for now)
    file.write_all(&0u32.to_le_bytes())?;
    
    let count = tensors.len() as u32;
    file.write_all(&count.to_le_bytes())?;
    
    // We need to calculate data offsets before writing headers.
    // The data starts after all headers.
    let mut current_header_offset = 12; // Magic (4) + Header Size (4) + Count (4)
    
    for (header, _) in tensors {
        current_header_offset += 2 + header.name.len() as u64; // name_len + name
        current_header_offset += 1; // data_type
        current_header_offset += 1; // dims_count
        current_header_offset += header.shape.len() as u64 * 4; // shape
        current_header_offset += 8 + 8; // data_offset + data_length
    }
    
    // Align data start to 64 bytes for cache line optimization
    let padding = (64 - (current_header_offset % 64)) % 64;
    let data_start = current_header_offset + padding;
    
    // Write the actual header size now (we can seek back later but let's just ignore for this prototype)
    
    let mut current_data_offset = data_start;
    
    for (header, data) in tensors {
        let name_bytes = header.name.as_bytes();
        file.write_all(&(name_bytes.len() as u16).to_le_bytes())?;
        file.write_all(name_bytes)?;
        
        file.write_all(&[header.data_type])?;
        file.write_all(&[header.shape.len() as u8])?;
        
        for &dim in &header.shape {
            file.write_all(&dim.to_le_bytes())?;
        }
        
        let data_len = data.len() as u64;
        file.write_all(&current_data_offset.to_le_bytes())?;
        file.write_all(&data_len.to_le_bytes())?;
        
        // Ensure tensors are aligned to 64 bytes
        let align_padding = (64 - (data_len % 64)) % 64;
        current_data_offset += data_len + align_padding;
    }
    
    // Write header padding
    for _ in 0..padding {
        file.write_all(&[0u8])?;
    }
    
    // Write data blocks
    for (_, data) in tensors {
        file.write_all(data)?;
        
        let data_len = data.len() as u64;
        let align_padding = (64 - (data_len % 64)) % 64;
        for _ in 0..align_padding {
            file.write_all(&[0u8])?;
        }
    }
    
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[test]
    fn test_aew_serialization() {
        let test_path = "test_weights.aew";
        
        let data1: Vec<f32> = vec![1.0, 2.0, 3.0, 4.0];
        let bytes1 = unsafe {
            std::slice::from_raw_parts(data1.as_ptr() as *const u8, data1.len() * 4)
        };
        
        let data2: Vec<f32> = vec![5.0, 6.0, 7.0, 8.0, 9.0, 10.0];
        let bytes2 = unsafe {
            std::slice::from_raw_parts(data2.as_ptr() as *const u8, data2.len() * 4)
        };
        
        let tensors = vec![
            (
                TensorHeader {
                    name: "layer1.weight".to_string(),
                    data_type: 0,
                    shape: vec![2, 2],
                    data_offset: 0,
                    data_length: 0,
                },
                bytes1
            ),
            (
                TensorHeader {
                    name: "layer1.bias".to_string(),
                    data_type: 0,
                    shape: vec![6],
                    data_offset: 0,
                    data_length: 0,
                },
                bytes2
            ),
        ];
        
        save_aew(test_path, &tensors).unwrap();
        
        let aew = AewFile::load(test_path).unwrap();
        
        assert_eq!(aew.tensors.len(), 2);
        assert_eq!(aew.tensors[0].name, "layer1.weight");
        assert_eq!(aew.tensors[0].shape, vec![2, 2]);
        
        let loaded_bytes1 = aew.get_tensor_data("layer1.weight").unwrap();
        assert_eq!(loaded_bytes1, bytes1);
        
        let loaded_bytes2 = aew.get_tensor_data("layer1.bias").unwrap();
        assert_eq!(loaded_bytes2, bytes2);
        
        // Ensure zero-copy alignment
        assert_eq!(aew.tensors[0].data_offset % 64, 0);
        assert_eq!(aew.tensors[1].data_offset % 64, 0);
        
        fs::remove_file(test_path).unwrap();
    }
}
