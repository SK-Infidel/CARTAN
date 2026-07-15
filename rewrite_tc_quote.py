import os

with open('compiler/src/type_checker.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_code = '''            Expr::Placeholder(_) => {
                Ok(CartanType::Unknown)
            },'''
new_code = '''            Expr::Placeholder(_) => {
                Ok(CartanType::Unknown)
            },
            Expr::Quote(_) => {
                Ok(CartanType::Unknown)
            },'''

if old_code in code:
    code = code.replace(old_code, new_code)
    with open('compiler/src/type_checker.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added Quote to type_checker.rs")
else:
    print("Could not find Placeholder in type_checker.rs")
