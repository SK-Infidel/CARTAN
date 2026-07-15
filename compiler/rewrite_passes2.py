import os
with open('src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    llvm_code = f.read()

old_llvm = '''            Expr::Integer(i) => {
                Some(format!("{}", i))
            },'''
new_llvm = '''            Expr::Placeholder(_) => {
                Some("0.0".to_string())
            },
            Expr::Integer(i) => {
                Some(format!("{}", i))
            },'''

if old_llvm in llvm_code:
    llvm_code = llvm_code.replace(old_llvm, new_llvm)
    with open('src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
        f.write(llvm_code)
    print("Added Placeholder to llvm_codegen.rs")
else:
    print("Failed to find Integer in llvm_codegen.rs")
