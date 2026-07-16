import os

with open('compiler/src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    code = f.read()

quote_logic = '''            Expr::Quote(block) => {
                let stmt_count = block.statements.len();
                let reg = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_tensor_alloc(i32 1, i32 {}\\n", reg, stmt_count));
                Some(format!("ptr:{}", reg))
            },
            Expr::HotSwap'''

code = code.replace('            Expr::HotSwap', quote_logic)

with open('compiler/src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
    f.write(code)
