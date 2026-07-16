import os

with open('compiler/src/lexer.rs', 'r', encoding='utf-8') as f:
    code = f.read()

if '"mesh" =>' not in code:
    code = code.replace('"macro" => TokenType::Macro,', '"macro" => TokenType::Macro,\n            "mesh" => TokenType::Mesh,\n            "supervisor" => TokenType::Supervisor,')

with open('compiler/src/lexer.rs', 'w', encoding='utf-8') as f:
    f.write(code)
