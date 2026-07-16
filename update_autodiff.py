import os

with open('compiler/src/autodiff.rs', 'r', encoding='utf-8') as f:
    code = f.read()

autodiff_logic = '''                                "-" => {
                                    if let Expr::Identifier(l) = left {
                                        new_statements.push(self.create_grad_update(&format!("d_{}", l), &d_target));
                                    }
                                    if let Expr::Identifier(r) = right {
                                        new_statements.push(self.create_grad_update_neg(&format!("d_{}", r), &d_target));
                                    }
                                },
                                "/" => {
                                    if let Expr::Identifier(l) = left {
                                        new_statements.push(self.create_grad_update_div(&format!("d_{}", l), &d_target, right));
                                    }
                                    if let Expr::Identifier(r) = right {
                                        new_statements.push(self.create_grad_update_div_right(&format!("d_{}", r), &d_target, left, right));
                                    }
                                },
                                "@" => {'''

code = code.replace('''                                "@" => {''', autodiff_logic)

helper_methods = '''    fn create_grad_update_neg(&self, grad_name: &str, upstream: &str) -> Stmt {
        Stmt::VarDecl {
            name: grad_name.to_string(),
            is_const: false,
            value: Expr::BinaryOp {
                left: Box::new(Expr::Identifier(upstream.to_string())),
                op: "*".to_string(),
                right: Box::new(Expr::FloatLiteral(-1.0)),
            }
        }
    }

    fn create_grad_update_div(&self, grad_name: &str, upstream: &str, var: &Expr) -> Stmt {
        Stmt::VarDecl {
            name: grad_name.to_string(),
            is_const: false,
            value: Expr::BinaryOp {
                left: Box::new(Expr::Identifier(upstream.to_string())),
                op: "/".to_string(),
                right: Box::new(var.clone()),
            }
        }
    }

    fn create_grad_update_div_right(&self, grad_name: &str, upstream: &str, l_var: &Expr, r_var: &Expr) -> Stmt {
        let neg_upstream = Expr::BinaryOp {
            left: Box::new(Expr::Identifier(upstream.to_string())),
            op: "*".to_string(),
            right: Box::new(Expr::FloatLiteral(-1.0)),
        };
        let num = Expr::BinaryOp {
            left: Box::new(neg_upstream),
            op: "*".to_string(),
            right: Box::new(l_var.clone()),
        };
        let denom = Expr::BinaryOp {
            left: Box::new(r_var.clone()),
            op: "*".to_string(),
            right: Box::new(r_var.clone()),
        };
        Stmt::VarDecl {
            name: grad_name.to_string(),
            is_const: false,
            value: Expr::BinaryOp {
                left: Box::new(num),
                op: "/".to_string(),
                right: Box::new(denom),
            }
        }
    }

    fn create_grad_update_mul'''

code = code.replace('''    fn create_grad_update_mul''', helper_methods)

with open('compiler/src/autodiff.rs', 'w', encoding='utf-8') as f:
    f.write(code)
