import os

with open('compiler/src/ast.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_ast = '''    Boolean(bool),
    StringLiteral(String),
    Identifier(String),
    Placeholder(String),'''
new_ast = '''    Boolean(bool),
    StringLiteral(String),
    Identifier(String),
    Placeholder(String),
    Quote(BlockStmt),'''

if old_ast in code:
    code = code.replace(old_ast, new_ast)
    with open('compiler/src/ast.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added Quote to Expr in ast.rs")
else:
    print("Could not find Expr variants in ast.rs")
