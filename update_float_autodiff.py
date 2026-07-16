import os

with open('compiler/src/autodiff.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('Expr::FloatLiteral(-1.0)', 'Expr::Float(-1.0)')

with open('compiler/src/autodiff.rs', 'w', encoding='utf-8') as f:
    f.write(code)
