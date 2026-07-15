import os

with open('compiler/src/lexer.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_keys = '''        keywords.insert("pattern".to_string(), TokenType::Pattern);
        keywords.insert("replace".to_string(), TokenType::Replace);'''
new_keys = '''        keywords.insert("pattern".to_string(), TokenType::Pattern);
        keywords.insert("replace".to_string(), TokenType::Replace);
        keywords.insert("quote".to_string(), TokenType::Quote);'''

if old_keys in code:
    code = code.replace(old_keys, new_keys)
    with open('compiler/src/lexer.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added quote to lexer.rs keywords")
else:
    print("Could not find keywords in lexer.rs")
