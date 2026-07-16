import os

with open('tensor_runtime/src/lib.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('if t.rows == ng.rows && t.cols == ng.cols && t.depth == ng.depth {', 'if t.size == ng.size {')

with open('tensor_runtime/src/lib.rs', 'w', encoding='utf-8') as f:
    f.write(code)
