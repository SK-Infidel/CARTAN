import os

with open('compiler/src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    code = f.read()

hotswap_codegen = '''            Expr::HotSwap(target, new_graph) => {
                self.output.push_str("  ; --- Hot Swap ---\\n");
                let target_reg = self.visit_expr(target).unwrap_or("null".to_string());
                let clean_t = target_reg.split(':').last().unwrap_or(&target_reg).to_string();
                let new_graph_reg = self.visit_expr(new_graph).unwrap_or("%0".to_string());
                let clean_n = new_graph_reg.split(':').last().unwrap_or(&new_graph_reg).to_string();
                self.output.push_str("  ; Try-Catch Sandbox Safety Boundary\\n");
                self.output.push_str(&format!("  call void @cartan_sandbox_hot_swap(ptr {}, ptr {})\\n", clean_t, clean_n));'''

code = code.replace('''            Expr::HotSwap(target, new_graph) => {
                self.output.push_str("  ; --- Hot Swap ---\\n");
                let target_reg = self.visit_expr(target).unwrap_or("null".to_string());
                let new_graph_reg = self.visit_expr(new_graph).unwrap_or("%0".to_string());
                self.output.push_str("  ; Try-Catch Sandbox Safety Boundary\\n");
                self.output.push_str(&format!("  call void @cartan_sandbox_hot_swap(ptr {}, ptr {})\\n", target_reg, new_graph_reg));''', hotswap_codegen)

with open('compiler/src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
    f.write(code)
