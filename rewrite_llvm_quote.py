import os

with open('compiler/src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_code = '''            Expr::Placeholder(_) => {
                Some("0.0".to_string())
            },'''
new_code = '''            Expr::Placeholder(_) => {
                Some("0.0".to_string())
            },
            Expr::Quote(_) => {
                Some("0.0".to_string())
            },'''

if old_code in code:
    code = code.replace(old_code, new_code)
    with open('compiler/src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added Quote to llvm_codegen.rs")
else:
    print("Could not find Placeholder in llvm_codegen.rs")
