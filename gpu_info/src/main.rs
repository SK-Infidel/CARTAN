fn main() {
    let instance = wgpu::Instance::default();
    let adapter = pollster::block_on(instance.request_adapter(&wgpu::RequestAdapterOptions::default())).unwrap();
    println!("{:#?}", adapter.get_info());
    println!("{:#?}", adapter.limits());
}
