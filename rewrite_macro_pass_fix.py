import os

with open('compiler/src/macro_pass.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_code = '''                    if !self.matches_stmts(ws, &[ps.clone()], bindings) { return false; }'''
new_code = '''                    if !self.matches_stmt(ws, ps, bindings) { return false; }'''

if old_code in code:
    code = code.replace(old_code, new_code)
    with open('compiler/src/macro_pass.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Fixed type error in matches_stmts")
else:
    print("Could not find the typo")
