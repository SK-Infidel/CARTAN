import os

with open('compiler/src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    code = f.read()

import re
code = re.sub(r'            Expr::Transpose\(inner\) => \{\n                let inner_val = self\.visit_expr\(inner\)\?\.replace\("ptr:", ""\);\n                let reg = self\.next_reg\(\);\n                self\.output\.push_str\(&format\!\("  \{\} = call ptr \@cartan_tensor_transpose\(ptr \{\}\\n", reg, inner_val\)\);\n                Some\(format\!\("ptr:\{\}", reg\)\)\n            \},\n', '', code, count=1)

with open('compiler/src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
    f.write(code)
