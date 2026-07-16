import os

with open('compiler/src/lexer.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('keywords.insert("macro".to_string(), TokenType::Macro);', 'keywords.insert("macro".to_string(), TokenType::Macro);\n        keywords.insert("mesh".to_string(), TokenType::Mesh);\n        keywords.insert("supervisor".to_string(), TokenType::Supervisor);')

with open('compiler/src/lexer.rs', 'w', encoding='utf-8') as f:
    f.write(code)
