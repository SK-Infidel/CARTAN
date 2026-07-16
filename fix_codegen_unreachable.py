import os

with open('compiler/src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('''            Expr::Quote(_) => {
                Some("0.0".to_string())
            },''', '')

with open('compiler/src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
    f.write(code)
