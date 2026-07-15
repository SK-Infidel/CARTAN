import os

with open('compiler/src/lexer.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_keys = '''        keywords.insert("in".to_string(), TokenType::In);
        keywords.insert("backward".to_string(), TokenType::Backward);'''
new_keys = '''        keywords.insert("in".to_string(), TokenType::In);
        keywords.insert("backward".to_string(), TokenType::Backward);
        keywords.insert("macro".to_string(), TokenType::Macro);
        keywords.insert("pattern".to_string(), TokenType::Pattern);
        keywords.insert("replace".to_string(), TokenType::Replace);'''

if old_keys in code:
    code = code.replace(old_keys, new_keys)
    with open('compiler/src/lexer.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added macro keywords to lexer.rs")
else:
    print("Failed to find keywords in lexer")
