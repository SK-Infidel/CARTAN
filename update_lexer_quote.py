import os

with open('compiler/src/token.rs', 'r', encoding='utf-8') as f:
    code = f.read()
if 'Quote,' not in code:
    code = code.replace('Backtrack,', 'Backtrack,\n    Quote,')
with open('compiler/src/token.rs', 'w', encoding='utf-8') as f:
    f.write(code)

with open('compiler/src/lexer.rs', 'r', encoding='utf-8') as f:
    code = f.read()
if 'quote' not in code:
    code = code.replace('keywords.insert("backtrack".to_string(), TokenType::Backtrack);', 'keywords.insert("backtrack".to_string(), TokenType::Backtrack);\n        keywords.insert("quote".to_string(), TokenType::Quote);')
with open('compiler/src/lexer.rs', 'w', encoding='utf-8') as f:
    f.write(code)
