import os

with open('src/macro_pass.rs', 'r', encoding='utf-8') as f:
    code = f.read()

new_code = '''use crate::ast::{Stmt, Expr, MacroRule, BlockStmt};
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
                        stmts.splice(i..i+p_len, replaced);
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
        window == pattern
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
'''

with open('src/macro_pass.rs', 'w', encoding='utf-8') as f:
    f.write(new_code)
print("Updated macro_pass.rs with  placeholder support")
