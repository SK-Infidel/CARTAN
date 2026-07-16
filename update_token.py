import os

with open('compiler/src/token.rs', 'r', encoding='utf-8') as f:
    code = f.read()

if 'Mesh,' not in code:
    code = code.replace('Macro,', 'Macro,\n    Mesh,\n    Supervisor,')

with open('compiler/src/token.rs', 'w', encoding='utf-8') as f:
    f.write(code)
