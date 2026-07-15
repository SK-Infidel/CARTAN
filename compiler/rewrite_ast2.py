import os

with open('src/ast.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_stmt = '''pub enum Stmt {
    Expr(Expr),'''

new_stmt = '''pub enum Stmt {
    Placeholder(String),
    Expr(Expr),'''

if old_stmt in code:
    code = code.replace(old_stmt, new_stmt)
    print("Added Placeholder to Stmt")

with open('src/ast.rs', 'w', encoding='utf-8') as f:
    f.write(code)

