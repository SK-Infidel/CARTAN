import os

with open('compiler/src/token.rs', 'r', encoding='utf-8') as f:
    code = f.read()

if 'HotSwap,' not in code:
    code = code.replace('Mesh,', 'Mesh,\n    HotSwap,')

with open('compiler/src/token.rs', 'w', encoding='utf-8') as f:
    f.write(code)
