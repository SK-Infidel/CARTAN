import os

with open('src/ast.rs', 'r', encoding='utf-8') as f:
    code = f.read()

# Add Placeholder to Expr
old_expr = '''pub enum Expr {
    Integer(i64),
    Float(f64),
    Boolean(bool),
    StringLiteral(String),
    Identifier(String),'''

new_expr = '''pub enum Expr {
    Integer(i64),
    Float(f64),
    Boolean(bool),
    StringLiteral(String),
    Identifier(String),
    Placeholder(String),'''

if old_expr in code:
    code = code.replace(old_expr, new_expr)
    print("Added Placeholder to Expr")

# Add Placeholder to Stmt
old_stmt = '''pub enum Stmt {
    VarDecl {
        name: String,
        is_const: bool,
        value: Expr,
    },'''

new_stmt = '''pub enum Stmt {
    Placeholder(String),
    VarDecl {
        name: String,
        is_const: bool,
        value: Expr,
    },'''

if old_stmt in code:
    code = code.replace(old_stmt, new_stmt)
    print("Added Placeholder to Stmt")

with open('src/ast.rs', 'w', encoding='utf-8') as f:
    f.write(code)

