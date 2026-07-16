import os

with open('compiler/src/ast.rs', 'r', encoding='utf-8') as f:
    code = f.read()

if 'MeshBlock {' not in code:
    mesh_stmt = '''    MeshBlock {
        name: String,
        strategy: String,
        body: BlockStmt,
    },
    TopologyDecl {'''
    code = code.replace('    TopologyDecl {', mesh_stmt)

with open('compiler/src/ast.rs', 'w', encoding='utf-8') as f:
    f.write(code)
