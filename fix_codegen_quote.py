import os

with open('compiler/src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('@cartan_tensor_alloc(i32 1, i32 {}\\n', '@cartan_tensor_alloc(i32 1, i32 {})\\n')

with open('compiler/src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
    f.write(code)
