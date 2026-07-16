import os
import re

# Fix liveness.rs
with open('compiler/src/liveness.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace("self.visit_expr_usage(condition, idx);", "self.visit_expr_usage(condition, self.current_idx);")
code = code.replace("self.visit_expr_usage(p, idx);", "self.visit_expr_usage(p, self.current_idx);")
code = code.replace("self.visit_stmt(body, idx);", "self.analyze_block(std::slice::from_ref(&**body));")

with open('compiler/src/liveness.rs', 'w', encoding='utf-8') as f:
    f.write(code)

# Fix llvm_codegen.rs duplicate Stmt::Match
with open('compiler/src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    code = f.read()

# The second Match is the one I injected (it starts with "let cond_val = self.visit_expr(condition).unwrap_or("".to_string());")
bad_match_start = '            Stmt::Match { condition, arms } => {\n                let cond_val = self.visit_expr(condition).unwrap_or("".to_string());'

# It ends right before "Stmt::If"
start_idx = code.find(bad_match_start)
if start_idx != -1:
    end_idx = code.find('            Stmt::If { condition, true_block, false_block } => {', start_idx)
    code = code[:start_idx] + code[end_idx:]

# Also there's unreachable pattern Expr::Transpose in llvm_codegen.rs, wait!
# I saw a warning about Expr::Transpose unreachable pattern earlier.
# Let's clean that up too.
transp_pattern = '            Expr::Transpose(inner) => {\n                let inner_val = self.visit_expr(inner)?.replace("ptr:", "");\n                let reg = self.next_reg();\n                self.output.push_str(&format!("  {} = call ptr @cartan_tensor_transpose(ptr {})\\n", reg, inner_val));\n                Some(format!("ptr:{}", reg))\n            },\n'
code = code.replace(transp_pattern, "", 1) # remove the first one if there are duplicates

with open('compiler/src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
    f.write(code)

