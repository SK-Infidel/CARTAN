import os

with open('compiler/src/main.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old = '''    println!("Lexing completed: {} tokens.", tokens.len());'''
new = '''    println!("Lexing completed: {} tokens.", tokens.len());
    for t in &tokens {
        println!("{:?}", t);
    }'''

if old in code:
    code = code.replace(old, new)
    with open('compiler/src/main.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added debug output")
else:
    print("Could not find lexing completed line")

