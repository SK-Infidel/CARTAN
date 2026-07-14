pub struct WGSLGenerator;

impl WGSLGenerator {
    pub fn new() -> Self {
        Self
    }
    
    pub fn generate(&self, _ast: &[crate::ast::Stmt]) -> String {
        // Real WGSL is pre-compiled in gpu_runtime/src/kernels.wgsl
        "// WGSL kernels are pre-compiled in gpu_runtime crate\n".to_string()
    }
}
