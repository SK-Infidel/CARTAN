use crate::ast::{Stmt, Expr, MacroRule, BlockStmt};
use std::collections::HashMap;

pub struct MacroPass {
    macros: Vec<MacroRule>,
}

impl MacroPass {
    pub fn new() -> Self {
        Self { macros: Vec::new() }
    }

    pub fn optimize(&mut self, ast: &mut Vec<Stmt>) {
        ast.retain(|stmt| {
            if let Stmt::MacroDecl(m) = stmt {
                self.macros.push(m.clone());
                false
            } else {
                true
            }
        });

        if self.macros.is_empty() {
            return;
        }

        self.apply_to_stmts(ast);
    }

    fn apply_to_stmts(&self, stmts: &mut Vec<Stmt>) {
        let mut i = 0;
        while i < stmts.len() {
            let mut matched = false;
            for m in &self.macros {
                let p_len = m.pattern.statements.len();
                if p_len > 0 && i + p_len <= stmts.len() {
                    let window = &stmts[i..i+p_len];
                    let mut bindings = HashMap::new();
                    if self.matches_stmts(window, &m.pattern.statements, &mut bindings) {
                        let mut replaced = m.replace.statements.clone();
                        for stmt in &mut replaced {
                            self.substitute_stmt(stmt, &bindings);
                        }
                        println!("MACRO MATCHED AND REPLACED!");
                        let r_len = replaced.len();
                        stmts.splice(i..i+p_len, replaced);
                        i += r_len; // advance past the replacement to avoid infinite loops
                        matched = true;
                        break;
                    }
                }
            }
            if !matched {
                self.visit_stmt(&mut stmts[i]);
                i += 1;
            }
        }
    }
    
    fn matches_stmts(&self, window: &[Stmt], pattern: &[Stmt], bindings: &mut HashMap<String, Stmt>) -> bool {
        if window.len() != pattern.len() { return false; }
        for (w, p) in window.iter().zip(pattern.iter()) {
            if !self.matches_stmt(w, p, bindings) { return false; }
        }
        true
    }
    
    fn matches_stmt(&self, window: &Stmt, pattern: &Stmt, bindings: &mut HashMap<String, Stmt>) -> bool {
        if let Stmt::Placeholder(name) = pattern {
            bindings.insert(name.clone(), window.clone());
            return true;
        }
        if let (Stmt::Expr(w_e), Stmt::Expr(p_e)) = (window, pattern) {
            return self.matches_expr(w_e, p_e, bindings);
        }
        // Fallback to strict equality for non-placeholder structures
        window == pattern
    }

    fn matches_expr(&self, window: &Expr, pattern: &Expr, bindings: &mut HashMap<String, Stmt>) -> bool {
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
            (Expr::Quote(w_b), Expr::Quote(p_b)) => {
                if w_b.statements.len() != p_b.statements.len() { return false; }
                for (ws, ps) in w_b.statements.iter().zip(p_b.statements.iter()) {
                    if !self.matches_stmt(ws, ps, bindings) { return false; }
                }
                true
            }
            _ => window == pattern,
        }
    }

    fn substitute_stmt(&self, stmt: &mut Stmt, bindings: &HashMap<String, Stmt>) {
        if let Stmt::Placeholder(name) = stmt {
            if let Some(bound) = bindings.get(name) {
                *stmt = bound.clone();
                return;
            }
        }
        if let Stmt::Expr(e) = stmt {
            let mut new_e = e.clone();
            if self.substitute_expr(&mut new_e, bindings) {
                *stmt = Stmt::Expr(new_e);
                return;
            }
        }
        
        match stmt {
            Stmt::Block(block) | Stmt::AsyncCompute(block) => {
                self.apply_to_stmts(&mut block.statements);
            },
            Stmt::FunctionDecl(f) => {
                self.apply_to_stmts(&mut f.body.statements);
            },
            _ => {}
        }
    }
    
    fn substitute_expr(&self, expr: &mut Expr, bindings: &HashMap<String, Stmt>) -> bool {
        if let Expr::Placeholder(name) = expr {
            if let Some(Stmt::Expr(bound_e)) = bindings.get(name) {
                *expr = bound_e.clone();
                return true;
            }
        }
        match expr {
            Expr::FunctionCall { args, .. } => {
                for arg in args {
                    self.substitute_expr(arg, bindings);
                }
            }
            Expr::BinaryOp { left, right, .. } => {
                self.substitute_expr(left, bindings);
                self.substitute_expr(right, bindings);
            }
            Expr::UnaryOp { right, .. } => {
                self.substitute_expr(right, bindings);
            }
            Expr::MethodCall { object, args, .. } => {
                self.substitute_expr(object, bindings);
                for arg in args {
                    self.substitute_expr(arg, bindings);
                }
            }
            Expr::Assignment { target, value } => {
                self.substitute_expr(target, bindings);
                self.substitute_expr(value, bindings);
            }
            _ => {}
        }
        false
    }

    fn visit_stmt(&self, stmt: &mut Stmt) {
        match stmt {
            Stmt::Block(block) | Stmt::AsyncCompute(block) => {
                self.apply_to_stmts(&mut block.statements);
            },
            Stmt::FunctionDecl(f) => {
                self.apply_to_stmts(&mut f.body.statements);
            },
            Stmt::If { true_block, false_block, .. } => {
                self.apply_to_stmts(&mut true_block.statements);
                if let Some(fb) = false_block {
                    self.apply_to_stmts(&mut fb.statements);
                }
            },
            Stmt::While { body, .. } => {
                self.apply_to_stmts(&mut body.statements);
            },
            Stmt::For { body, .. } => {
                self.apply_to_stmts(&mut body.statements);
            },
            Stmt::TryCatch { try_block, catch_block, .. } => {
                self.apply_to_stmts(&mut try_block.statements);
                self.apply_to_stmts(&mut catch_block.statements);
            },
            Stmt::FluidPrecisionBlock { block, .. } => {
                self.apply_to_stmts(&mut block.statements);
            },
            Stmt::SparsityBlock { block, .. } => {
                self.apply_to_stmts(&mut block.statements);
            },
            Stmt::ManifoldDecl { body, .. } => {
                self.apply_to_stmts(&mut body.statements);
            },
            Stmt::TopologyDecl { body, .. } => {
                self.apply_to_stmts(&mut body.statements);
            },
            _ => {}
        }
    }
}
