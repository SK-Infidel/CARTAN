import re

with open("C:/Users/rich-/source/repos/Cartan/gpu_runtime/src/lib_combined.rs", "r") as f:
    content = f.read()

# Replace the matmul implementation
matmul_impl = """
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
    let instance = wgpu::Instance::default();
    let adapter = pollster::block_on(instance.request_adapter(&wgpu::RequestAdapterOptions::default())).unwrap();
    let (device, queue) = pollster::block_on(adapter.request_device(&wgpu::DeviceDescriptor::default())).unwrap();
    
    let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
        label: Some("Kernels"),
        source: wgpu::ShaderSource::Wgsl(include_str!("kernels.wgsl").into()),
    });

    let matmul_pipeline = device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
        label: Some("Matmul Pipeline"),
        layout: None,
        module: &shader,
        entry_point: Some("matmul"),
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
        
        ctx.device.poll(wgpu::Maintain::Wait);
        receiver.recv().unwrap().unwrap();
        
        let data = buffer_slice.get_mapped_range();
        let result: &[f32] = bytemuck::cast_slice(&data);
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
"""

content = re.sub(r'#\[no_mangle\]\s*pub extern "C" fn cartan_tensor_matmul.*?out\s*\}\s*\}', matmul_impl, content, flags=re.DOTALL)

# Also fix `#[no_mangle]` globally to `#[unsafe(no_mangle)]` in the rest of the file
content = content.replace("#[no_mangle]", "#[unsafe(no_mangle)]")

with open("C:/Users/rich-/source/repos/Cartan/gpu_runtime/src/lib.rs", "w") as f:
    f.write(content)
