import os

with open('compiler/src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    code = f.read()

codegen_logic = '''            Expr::Transpose(inner) => {
                let inner_val = self.visit_expr(inner)?.replace("ptr:", "");
                let reg = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_tensor_transpose(ptr {})\n", reg, inner_val));
                Some(format!("ptr:{}", reg))
            },
            Expr::TransposeWeights'''

code = code.replace('            Expr::TransposeWeights', codegen_logic)

with open('compiler/src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
    f.write(code)
