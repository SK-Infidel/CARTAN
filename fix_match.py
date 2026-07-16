import os

files = ['compiler/src/type_checker.rs', 'compiler/src/liveness.rs', 'compiler/src/macro_pass.rs', 'compiler/src/optimizer.rs', 'compiler/src/llvm_codegen.rs']

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        code = file.read()
    
    # We want to swap the order of Stmt::If and Stmt::Match.
    # Actually, we can just find "Stmt::If { condition, true_block, false_block } => {\n            Stmt::Match { condition, arms } => {"
    # and change it to "Stmt::Match { condition, arms } => { ... },\nStmt::If { condition, true_block, false_block } => {"
    # But it's easier to just find the block and swap it.
    
    import re
    
    # Find Stmt::If { ... } => { ... \n Stmt::Match { ... } => { ... }
    # Let's just find the exact string we inserted.
    
    # Since I know I inserted it right after Stmt::If { condition, true_block, false_block } => {
    # The code looks like:
    # Stmt::If { condition, true_block, false_block } => {
    #             Stmt::Match { condition, arms } => {
    #                 ...
    #             },
    
    code = code.replace("            Stmt::If { condition, true_block, false_block } => {\n            Stmt::Match { condition, arms } => {", "            Stmt::Match { condition, arms } => {")
    
    code = code.replace("            Stmt::Match { condition, arms } => {", "            Stmt::Match { condition, arms } => {\n                // DUMMY\n            },\n            Stmt::If { condition, true_block, false_block } => {\n            Stmt::Match { condition, arms } => {")
    
    # Wait, this is getting complicated. Let's do it clean.
