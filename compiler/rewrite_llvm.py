import os

with open('src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    llvm_code = f.read()

# Pass 1
old_pass1 = '''        // Pass 1: Collect globals and declare extern functions
        for stmt in ast {
            match stmt {
                Stmt::ExternFunctionDecl(decl) => {'''
new_pass1 = '''        // Pass 1: Collect globals and declare extern functions
        for stmt in ast {
            match stmt {
                Stmt::Placeholder(_) => {},
                Stmt::ExternFunctionDecl(decl) => {'''
if old_pass1 in llvm_code:
    llvm_code = llvm_code.replace(old_pass1, new_pass1)
    
# Main loop
old_main = '''        for stmt in ast {
            let mut skip = false;
            match stmt {
                Stmt::ExternFunctionDecl(_) | Stmt::FunctionDecl(_) => skip = true,'''
new_main = '''        for stmt in ast {
            let mut skip = false;
            match stmt {
                Stmt::Placeholder(_) => skip = true,
                Stmt::ExternFunctionDecl(_) | Stmt::FunctionDecl(_) => skip = true,'''
if old_main in llvm_code:
    llvm_code = llvm_code.replace(old_main, new_main)

# visit_stmt
old_visit = '''    fn visit_stmt(&mut self, stmt: &Stmt) {
        match stmt {
            Stmt::Match { condition, arms } => {'''
new_visit = '''    fn visit_stmt(&mut self, stmt: &Stmt) {
        match stmt {
            Stmt::Placeholder(_) => {},
            Stmt::Match { condition, arms } => {'''
if old_visit in llvm_code:
    llvm_code = llvm_code.replace(old_visit, new_visit)

with open('src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
    f.write(llvm_code)
print("Updated llvm_codegen.rs")
