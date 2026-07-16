import os

with open('compiler/src/lexer.rs', 'r', encoding='utf-8') as f:
    code = f.read()

if 'hotswap' not in code:
    code = code.replace('keywords.insert("mesh".to_string(), TokenType::Mesh);', 'keywords.insert("mesh".to_string(), TokenType::Mesh);\n        keywords.insert("hotswap".to_string(), TokenType::HotSwap);')

with open('compiler/src/lexer.rs', 'w', encoding='utf-8') as f:
    f.write(code)
