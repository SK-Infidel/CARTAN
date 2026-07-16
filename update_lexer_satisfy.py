import os

with open('compiler/src/token.rs', 'r', encoding='utf-8') as f:
    code = f.read()
if 'Satisfy,' not in code:
    code = code.replace('HotSwap,', 'HotSwap,\n    Satisfy,\n    Otherwise,\n    Backtrack,')
with open('compiler/src/token.rs', 'w', encoding='utf-8') as f:
    f.write(code)

with open('compiler/src/lexer.rs', 'r', encoding='utf-8') as f:
    code = f.read()
if 'satisfy' not in code:
    code = code.replace('keywords.insert("hotswap".to_string(), TokenType::HotSwap);', 'keywords.insert("hotswap".to_string(), TokenType::HotSwap);\n        keywords.insert("satisfy".to_string(), TokenType::Satisfy);\n        keywords.insert("otherwise".to_string(), TokenType::Otherwise);\n        keywords.insert("backtrack".to_string(), TokenType::Backtrack);')
with open('compiler/src/lexer.rs', 'w', encoding='utf-8') as f:
    f.write(code)
