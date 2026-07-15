import os

with open('compiler/src/macro_pass.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_code = '''                        for stmt in &mut replaced {
                            self.substitute_stmt(stmt, &bindings);
                        }
                        stmts.splice(i..i+p_len, replaced);
                        matched = true;'''
new_code = '''                        for stmt in &mut replaced {
                            self.substitute_stmt(stmt, &bindings);
                        }
                        println!("MACRO MATCHED AND REPLACED!");
                        stmts.splice(i..i+p_len, replaced);
                        matched = true;'''

if old_code in code:
    code = code.replace(old_code, new_code)
    with open('compiler/src/macro_pass.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added debug print to macro_pass")
else:
    print("Could not find match in macro_pass.rs")
