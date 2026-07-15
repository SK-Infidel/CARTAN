import os

# type_checker.rs
with open('src/type_checker.rs', 'r', encoding='utf-8') as f:
    tc_code = f.read()

old_stmt = '''        match stmt {
            Stmt::StructDecl { name: _, fields: _ } => { /* ignore for now */ },'''
new_stmt = '''        match stmt {
            Stmt::Placeholder(_) => { /* Ignore placeholders during type checking */ },
            Stmt::StructDecl { name: _, fields: _ } => { /* ignore for now */ },'''

if old_stmt in tc_code:
    tc_code = tc_code.replace(old_stmt, new_stmt)
    with open('src/type_checker.rs', 'w', encoding='utf-8') as f:
        f.write(tc_code)
    print("Added Stmt::Placeholder to type_checker.rs")
else:
    print("Failed to find StructDecl in type_checker.rs")

# llvm_codegen.rs
with open('src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    llvm_code = f.read()

old_stmt_llvm = '''        match stmt {
            Stmt::ExternFunctionDecl(_) => {
                // Already handled in Pass 1
            },'''
new_stmt_llvm = '''        match stmt {
            Stmt::Placeholder(_) => {
                // Do nothing
            },
            Stmt::ExternFunctionDecl(_) => {
                // Already handled in Pass 1
            },'''

if old_stmt_llvm in llvm_code:
    llvm_code = llvm_code.replace(old_stmt_llvm, new_stmt_llvm)
    with open('src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
        f.write(llvm_code)
    print("Added Stmt::Placeholder to llvm_codegen.rs")
else:
    print("Failed to find ExternFunctionDecl in llvm_codegen.rs")

