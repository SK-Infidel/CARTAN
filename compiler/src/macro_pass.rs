use crate::ast::{Stmt, Expr, MacroRule, BlockStmt};

pub struct MacroPass {
    macros: Vec<MacroRule>,
}

impl MacroPass {
    pub fn new() -> Self {
        Self { macros: Vec::new() }
    }

    pub fn optimize(&mut self, ast: &mut Vec<Stmt>) {
        // First pass: extract all MacroDecls
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

        // Second pass: apply macros
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
                    if self.matches(window, &m.pattern.statements) {
                        // Replace window with m.replace.statements
                        stmts.splice(i..i+p_len, m.replace.statements.clone());
                        matched = true;
                        break; // break the macros loop, not the while loop
                    }
                }
            }
            if !matched {
                // recurse down
                self.visit_stmt(&mut stmts[i]);
                i += 1;
            }
        }
    }
    
    fn matches(&self, window: &[Stmt], pattern: &[Stmt]) -> bool {
        // For Phase 1, we use exact structural equality. 
        // A future upgrade can implement wildcard placeholder ($X) matching here!
        window == pattern
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
