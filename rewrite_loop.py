import os

with open('compiler/src/macro_pass.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_code = '''                        println!("MACRO MATCHED AND REPLACED!");
                        stmts.splice(i..i+p_len, replaced);
                        matched = true;
                        break;'''
new_code = '''                        println!("MACRO MATCHED AND REPLACED!");
                        let r_len = replaced.len();
                        stmts.splice(i..i+p_len, replaced);
                        i += r_len; // advance past the replacement to avoid infinite loops
                        matched = true;
                        break;'''

if old_code in code:
    code = code.replace(old_code, new_code)
    with open('compiler/src/macro_pass.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Fixed infinite loop in macro_pass")
else:
    print("Failed to find loop logic")
