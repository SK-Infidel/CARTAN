import os

with open('compiler/src/macro_pass.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_code = '''    fn matches_expr(&self, window: &Expr, pattern: &Expr, bindings: &mut HashMap<String, Stmt>) -> bool {
        if let Expr::Placeholder(name) = pattern {
            bindings.insert(name.clone(), Stmt::Expr(window.clone()));
            return true;
        }
        window == pattern
    }'''
new_code = '''    fn matches_expr(&self, window: &Expr, pattern: &Expr, bindings: &mut HashMap<String, Stmt>) -> bool {
        if let Expr::Placeholder(name) = pattern {
            bindings.insert(name.clone(), Stmt::Expr(window.clone()));
            return true;
        }
        match (window, pattern) {
            (Expr::Assignment { target: w_t, value: w_v }, Expr::Assignment { target: p_t, value: p_v }) => {
                self.matches_expr(w_t, p_t, bindings) && self.matches_expr(w_v, p_v, bindings)
            }
            (Expr::BinaryOp { left: w_l, op: w_o, right: w_r }, Expr::BinaryOp { left: p_l, op: p_o, right: p_r }) => {
                w_o == p_o && self.matches_expr(w_l, p_l, bindings) && self.matches_expr(w_r, p_r, bindings)
            }
            (Expr::UnaryOp { op: w_o, right: w_r }, Expr::UnaryOp { op: p_o, right: p_r }) => {
                w_o == p_o && self.matches_expr(w_r, p_r, bindings)
            }
            (Expr::FunctionCall { name: w_n, args: w_a }, Expr::FunctionCall { name: p_n, args: p_a }) => {
                if w_n != p_n || w_a.len() != p_a.len() { return false; }
                for (wa, pa) in w_a.iter().zip(p_a.iter()) {
                    if !self.matches_expr(wa, pa, bindings) { return false; }
                }
                true
            }
            _ => window == pattern,
        }
    }'''

if old_code in code:
    code = code.replace(old_code, new_code)
    with open('compiler/src/macro_pass.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added recursive expression matching")
else:
    print("Could not find matches_expr")
