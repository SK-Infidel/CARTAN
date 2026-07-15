import os

with open('compiler/src/macro_pass.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_match = '''            (Expr::FunctionCall { name: w_n, args: w_a }, Expr::FunctionCall { name: p_n, args: p_a }) => {
                if w_n != p_n || w_a.len() != p_a.len() { return false; }
                for (wa, pa) in w_a.iter().zip(p_a.iter()) {
                    if !self.matches_expr(wa, pa, bindings) { return false; }
                }
                true
            }
            _ => window == pattern,
        }
    }'''

new_match = '''            (Expr::FunctionCall { name: w_n, args: w_a }, Expr::FunctionCall { name: p_n, args: p_a }) => {
                if w_n != p_n || w_a.len() != p_a.len() { return false; }
                for (wa, pa) in w_a.iter().zip(p_a.iter()) {
                    if !self.matches_expr(wa, pa, bindings) { return false; }
                }
                true
            }
            (Expr::Quote(w_b), Expr::Quote(p_b)) => {
                if w_b.statements.len() != p_b.statements.len() { return false; }
                for (ws, ps) in w_b.statements.iter().zip(p_b.statements.iter()) {
                    if !self.matches_stmts(ws, &[ps.clone()], bindings) { return false; }
                }
                true
            }
            _ => window == pattern,
        }
    }'''

code = code.replace(old_match, new_match)

old_sub = '''              Expr::MethodCall { object, args, .. } => {
                  self.substitute_expr(object, bindings);
                  for arg in args {
                      self.substitute_expr(arg, bindings);
                  }
              }
              Expr::Assignment { target, value } => {'''

new_sub = '''              Expr::MethodCall { object, args, .. } => {
                  self.substitute_expr(object, bindings);
                  for arg in args {
                      self.substitute_expr(arg, bindings);
                  }
              }
              Expr::Quote(block) => {
                  for stmt in &mut block.statements {
                      self.substitute_stmt(stmt, bindings);
                  }
              }
              Expr::Assignment { target, value } => {'''

code = code.replace(old_sub, new_sub)

with open('compiler/src/macro_pass.rs', 'w', encoding='utf-8') as f:
    f.write(code)

print("Updated macro_pass.rs")
