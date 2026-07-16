import os

with open('compiler/src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('Stmt::Block(block) | Stmt::MeshBlock { body: block, .. } => {', 'Stmt::Block(block) => {')

with open('compiler/src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
    f.write(code)
