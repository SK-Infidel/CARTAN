import os

with open('src/token.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_tok = '''    // Special Cartan Primitives
    AtLocation, // @location
    AtBackend, // @backend
    Hash, // #'''

new_tok = '''    // Special Cartan Primitives
    AtLocation, // @location
    AtBackend, // @backend
    Hash, // #
    Placeholder(String), // '''

if old_tok in code:
    code = code.replace(old_tok, new_tok)
    with open('src/token.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added Placeholder to token.rs")
else:
    print("Could not find Special Cartan Primitives in token.rs")

