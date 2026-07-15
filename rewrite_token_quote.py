import os

with open('compiler/src/token.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_code = '''    AsyncCompute, Backward, Macro, Pattern, Replace,
    BackedBy, // backed_by'''
new_code = '''    AsyncCompute, Backward, Macro, Pattern, Replace, Quote,
    BackedBy, // backed_by'''

if old_code in code:
    code = code.replace(old_code, new_code)
    with open('compiler/src/token.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added Quote to TokenType")
else:
    print("Could not find line in token.rs")
