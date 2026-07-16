use crate::ast::{Stmt, Expr};

pub struct AutoDiffPass {
    forward_ops: Vec<(String, Expr, String, Expr)>, // (target, left, op, right)
}

impl AutoDiffPass {
    pub fn new() -> Self {
        Self {
            forward_ops: Vec::new(),
        }
    }

    pub fn optimize(&mut self, ast: &mut Vec<Stmt>) {
        self.visit_block_statements(ast);
    }

    fn visit_block_statements(&mut self, statements: &mut Vec<Stmt>) {
        let mut new_statements = Vec::new();
        
        for stmt in statements.drain(..) {
            match stmt.clone() {
                Stmt::VarDecl { name, value, .. } => {
                    self.track_forward_op(&name, &value);
                    new_statements.push(stmt);
                },
                Stmt::Expr(Expr::Assignment { target, value }) => {
                    if let Expr::Identifier(name) = *target {
                        self.track_forward_op(&name, &value);
                    }
                    new_statements.push(stmt);
                },
                Stmt::Backward(expr) => {
                    if let Expr::Identifier(loss_name) = expr {
                        new_statements.push(Stmt::Expr(Expr::StringLiteral("--- Auto-Generated Backward Pass ---".to_string())));
                        
                        new_statements.push(Stmt::VarDecl {
                            name: format!("d_{}", loss_name),
                            is_const: false,
                            value: Expr::FunctionCall {
                                name: "ones_like".to_string(),
                                args: vec![Expr::Identifier(loss_name.clone())],
                            },
                        });

                        for (target, left, op, right) in self.forward_ops.iter().rev() {
                            let d_target = format!("d_{}", target);

                            match op.as_str() {
                                "+" => {
                                    if let Expr::Identifier(l) = left {
                                        new_statements.push(self.create_grad_update(&format!("d_{}", l), &d_target));
                                    }
                                    if let Expr::Identifier(r) = right {
                                        new_statements.push(self.create_grad_update(&format!("d_{}", r), &d_target));
                                    }
                                },
                                "*" => {
                                    if let Expr::Identifier(l) = left {
                                        new_statements.push(self.create_grad_update_mul(&format!("d_{}", l), &d_target, right));
                                    }
                                    if let Expr::Identifier(r) = right {
                                        new_statements.push(self.create_grad_update_mul(&format!("d_{}", r), &d_target, left));
                                    }
                                },
                                "-" => {
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
                                "@" => {
                                    if let Expr::Identifier(l) = left {
                                        new_statements.push(self.create_grad_update_matmul_left(&format!("d_{}", l), &d_target, right));
                                    }
                                    if let Expr::Identifier(r) = right {
                                        new_statements.push(self.create_grad_update_matmul_right(&format!("d_{}", r), &d_target, left));
                                    }
                                },
                                _ => {}
                            }
                        }
                        
                        new_statements.push(Stmt::Expr(Expr::StringLiteral("--- End Backward Pass ---".to_string())));
                    }
                    new_statements.push(stmt);
                },
                mut other => {
                    self.visit_stmt(&mut other);
                    new_statements.push(other);
                }
            }
        }
        
        *statements = new_statements;
    }

    fn track_forward_op(&mut self, target: &str, value: &Expr) {
        let mut inner_val = value;
        if let Expr::FusedKernel(block) = value {
            if let Some(crate::ast::Stmt::Expr(first)) = block.statements.first() {
                inner_val = first;
            }
        }

        if let Expr::BinaryOp { left, op, right } = inner_val {
            self.forward_ops.push((target.to_string(), *left.clone(), op.clone(), *right.clone()));
        }
    }

    fn create_grad_update(&self, grad_name: &str, upstream: &str) -> Stmt {
        Stmt::VarDecl {
            name: grad_name.to_string(),
            is_const: false,
            value: Expr::Identifier(upstream.to_string()),
        }
    }

    fn create_grad_update_neg(&self, grad_name: &str, upstream: &str) -> Stmt {
        Stmt::VarDecl {
            name: grad_name.to_string(),
            is_const: false,
            value: Expr::BinaryOp {
                left: Box::new(Expr::Identifier(upstream.to_string())),
                op: "*".to_string(),
                right: Box::new(Expr::Float(-1.0)),
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
            right: Box::new(Expr::Float(-1.0)),
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

    fn create_grad_update_mul(&self, grad_name: &str, upstream: &str, var: &Expr) -> Stmt {
        Stmt::VarDecl {
            name: grad_name.to_string(),
            is_const: false,
            value: Expr::BinaryOp {
                left: Box::new(Expr::Identifier(upstream.to_string())),
                op: "*".to_string(),
                right: Box::new(var.clone()),
            }
        }
    }

    fn create_grad_update_matmul_left(&self, grad_name: &str, upstream: &str, right_var: &Expr) -> Stmt {
        Stmt::VarDecl {
            name: grad_name.to_string(),
            is_const: false,
            value: Expr::BinaryOp {
                left: Box::new(Expr::Identifier(upstream.to_string())),
                op: "@".to_string(),
                right: Box::new(Expr::Transpose(Box::new(right_var.clone()))),
            }
        }
    }

    fn create_grad_update_matmul_right(&self, grad_name: &str, upstream: &str, left_var: &Expr) -> Stmt {
        Stmt::VarDecl {
            name: grad_name.to_string(),
            is_const: false,
            value: Expr::BinaryOp {
                left: Box::new(Expr::Transpose(Box::new(left_var.clone()))),
                op: "@".to_string(),
                right: Box::new(Expr::Identifier(upstream.to_string())),
            }
        }
    }

    fn visit_stmt(&mut self, stmt: &mut Stmt) {
        match stmt {
            Stmt::Block(block) | Stmt::MeshBlock { body: block, .. } | Stmt::AsyncCompute(block) => {
                self.visit_block_statements(&mut block.statements);
            },
            Stmt::FunctionDecl(decl) => {
                self.forward_ops.clear(); // Reset forward tape per function
                self.visit_block_statements(&mut decl.body.statements);
            },
            Stmt::If { true_block, false_block, .. } => {
                self.visit_block_statements(&mut true_block.statements);
                if let Some(fb) = false_block {
                    self.visit_block_statements(&mut fb.statements);
                }
            },
            Stmt::While { body, .. } => {
                self.visit_block_statements(&mut body.statements);
            },
            _ => {}
        }
    }
}
