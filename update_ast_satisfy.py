import os

with open('compiler/src/ast.rs', 'r', encoding='utf-8') as f:
    code = f.read()
if 'Satisfy {' not in code:
    code = code.replace('MeshBlock {\n        name: String,\n        strategy: String,\n        body: BlockStmt,\n    },', 'MeshBlock {\n        name: String,\n        strategy: String,\n        body: BlockStmt,\n    },\n    Satisfy {\n        condition: Expr,\n        body: BlockStmt,\n        otherwise: Option<BlockStmt>,\n    },\n    Backtrack,')
with open('compiler/src/ast.rs', 'w', encoding='utf-8') as f:
    f.write(code)
