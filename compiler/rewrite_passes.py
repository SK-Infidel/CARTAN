import os

# type_checker.rs
with open('src/type_checker.rs', 'r', encoding='utf-8') as f:
    tc_code = f.read()

old_expr = '''            Expr::Identifier(name) => {
                if name == "spike" {'''
new_expr = '''            Expr::Placeholder(_) => {
                Ok(CartanType::Unknown)
            },
            Expr::Identifier(name) => {
                if name == "spike" {'''

if old_expr in tc_code:
    tc_code = tc_code.replace(old_expr, new_expr)
    with open('src/type_checker.rs', 'w', encoding='utf-8') as f:
        f.write(tc_code)
    print("Added Placeholder to type_checker.rs")
else:
    print("Failed to find Identifier in type_checker.rs")

# llvm_codegen.rs
with open('src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    llvm_code = f.read()

old_llvm = '''            Expr::StringLiteral(s) => {
                Some(format!("string:{}", s))
            },'''
new_llvm = '''            Expr::Placeholder(_) => {
                Some("0.0".to_string())
            },
            Expr::StringLiteral(s) => {
                Some(format!("string:{}", s))
            },'''

if old_llvm in llvm_code:
    llvm_code = llvm_code.replace(old_llvm, new_llvm)
    with open('src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
        f.write(llvm_code)
    print("Added Placeholder to llvm_codegen.rs")
else:
    print("Failed to find StringLiteral in llvm_codegen.rs")

