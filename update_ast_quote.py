import os

with open('compiler/src/ast.rs', 'r', encoding='utf-8') as f:
    code = f.read()
if 'Quote(' not in code:
    code = code.replace('HotSwap(Box<Expr>, Box<Expr>),', 'HotSwap(Box<Expr>, Box<Expr>),\n    Quote(BlockStmt),')
with open('compiler/src/ast.rs', 'w', encoding='utf-8') as f:
    f.write(code)
