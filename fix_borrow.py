import os

with open('compiler/src/type_checker.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('for arg in args {', 'for arg in args.iter_mut() {')

with open('compiler/src/type_checker.rs', 'w', encoding='utf-8') as f:
    f.write(code)
