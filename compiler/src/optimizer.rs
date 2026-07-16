use crate::ast::{Stmt, Expr};

pub struct KernelFusionPass;

impl KernelFusionPass {
    pub fn new() -> Self {
        Self
    }

    pub fn optimize(&mut self, ast: &mut Vec<Stmt>) {
        for stmt in ast.iter_mut() {
            self.visit_stmt(stmt);
        }
    }

    fn is_fusible_tree(&self, expr: &Expr) -> bool {
        match expr {
            Expr::BinaryOp { op, left, right } => {
                if op == "+" || op == "-" || op == "*" || op == "/" {
                    self.is_fusible_tree(left) && self.is_fusible_tree(right)
                } else {
                    false
                }
            },
            Expr::MethodCall { object, method_name, args } => {
                let name = method_name.as_str();
                if matches!(name, "relu" | "dropout" | "layernorm" | "gelu" | "sigmoid" | "tanh") {
                    self.is_fusible_tree(object) && args.iter().all(|a| self.is_fusible_tree(a))
                } else {
                    false
                }
            },
            Expr::FunctionCall { name, args } => {
                if matches!(name.as_str(), "Cartan.relu" | "Cartan.dropout" | "Cartan.layernorm" | "Cartan.gelu" | "Cartan.sigmoid" | "Cartan.tanh") {
                    args.iter().all(|a| self.is_fusible_tree(a))
                } else {
                    false
                }
            },
            Expr::Integer(_) | Expr::Float(_) | Expr::Identifier(_) => true,
            Expr::IndexAccess { .. } => true,
            _ => false,
        }
    }

    fn visit_stmt(&mut self, stmt: &mut Stmt) {
        match stmt {
            Stmt::Block(block) | Stmt::MeshBlock { body: block, .. } | Stmt::AsyncCompute(block) => {
                for s in &mut block.statements {
                    self.visit_stmt(s);
                }
            },
            Stmt::FunctionDecl(decl) => {
                for s in &mut decl.body.statements {
                    self.visit_stmt(s);
                }
            },
            Stmt::If { true_block, false_block, condition } => {
                self.visit_expr(condition);
                for s in &mut true_block.statements {
                    self.visit_stmt(s);
                }
                if let Some(fb) = false_block {
                    for s in &mut fb.statements {
                        self.visit_stmt(s);
                    }
                }
            },
            Stmt::While { body, condition } => {
                self.visit_expr(condition);
                for s in &mut body.statements {
                    self.visit_stmt(s);
                }
            },
            Stmt::For { init, condition, increment, body } => {
                if let Some(i) = init { self.visit_stmt(i); }
                if let Some(c) = condition { self.visit_expr(c); }
                if let Some(inc) = increment { self.visit_stmt(inc); }
                for s in &mut body.statements {
                    self.visit_stmt(s);
                }
            },
            Stmt::TryCatch { try_block, catch_block, .. } => {
                for s in &mut try_block.statements { self.visit_stmt(s); }
                for s in &mut catch_block.statements { self.visit_stmt(s); }
            },
            Stmt::VarDecl { value, .. } => {
                self.visit_expr(value);
            },
            Stmt::Expr(expr) => {
                self.visit_expr(expr);
            },
            Stmt::Return { value } => {
                if let Some(e) = value {
                    self.visit_expr(e);
                }
            },
            Stmt::StructDecl { fields, .. } => {
                for s in fields {
                    self.visit_stmt(s);
                }
            },
            _ => {}
        }
    }

    fn visit_expr(&mut self, expr: &mut Expr) {
        // If it's a top-level math or element-wise tree, fuse it!
        let mut should_fuse = false;
        match expr {
            Expr::BinaryOp { op, .. } if matches!(op.as_str(), "+" | "-" | "*" | "/") => {
                should_fuse = self.is_fusible_tree(expr);
            },
            Expr::MethodCall { method_name, .. } if matches!(method_name.as_str(), "relu" | "dropout" | "layernorm" | "gelu" | "sigmoid" | "tanh") => {
                should_fuse = self.is_fusible_tree(expr);
            },
            Expr::FunctionCall { name, .. } if matches!(name.as_str(), "Cartan.relu" | "Cartan.dropout" | "Cartan.layernorm" | "Cartan.gelu" | "Cartan.sigmoid" | "Cartan.tanh") => {
                should_fuse = self.is_fusible_tree(expr);
            },
            _ => {}
        }
        
        if should_fuse {
            let e = expr.clone();
            *expr = Expr::FusedKernel(crate::ast::BlockStmt { statements: vec![crate::ast::Stmt::Expr(e)] });
            return; // Do not recurse, we've bundled the whole subtree
        }

        match expr {
            Expr::BinaryOp { left, right, .. } => {
                self.visit_expr(left);
                self.visit_expr(right);
            },
            Expr::Assignment { target, value } => {
                self.visit_expr(target);
                self.visit_expr(value);
            },
            Expr::FunctionCall { args, .. } => {
                for arg in args {
                    self.visit_expr(arg);
                }
            },
            Expr::MethodCall { object, args, .. } => {
                self.visit_expr(object);
                for arg in args {
                    self.visit_expr(arg);
                }
            },
            Expr::PropertyAccess { object, .. } => {
                self.visit_expr(object);
            },
            Expr::IndexAccess { object, index } => {
                self.visit_expr(object);
                self.visit_expr(index);
            },
            Expr::UnaryOp { right, .. } => {
                self.visit_expr(right);
            },
            Expr::ArrayDecl { elements } => {
                for e in elements {
                    self.visit_expr(e);
                }
            },
            Expr::DictionaryDecl { pairs } => {
                for (k, v) in pairs {
                    self.visit_expr(k);
                    self.visit_expr(v);
                }
            },
            _ => {}
        }
    }
}
pub struct AlgebraicSimplificationPass;

impl AlgebraicSimplificationPass {
    pub fn new() -> Self { Self }

    pub fn optimize(&mut self, ast: &mut Vec<Stmt>) {
        for stmt in ast.iter_mut() {
            self.visit_stmt(stmt);
        }
    }

    fn visit_stmt(&mut self, stmt: &mut Stmt) {
        match stmt {
            Stmt::Block(block) | Stmt::MeshBlock { body: block, .. } | Stmt::AsyncCompute(block) => {
                for s in &mut block.statements { self.visit_stmt(s); }
            },
            Stmt::FunctionDecl(decl) => {
                for s in &mut decl.body.statements { self.visit_stmt(s); }
            },
            Stmt::If { true_block, false_block, condition } => {
                self.visit_expr(condition);
                for s in &mut true_block.statements { self.visit_stmt(s); }
                if let Some(fb) = false_block {
                    for s in &mut fb.statements { self.visit_stmt(s); }
                }
            },
            Stmt::While { body, condition } => {
                self.visit_expr(condition);
                for s in &mut body.statements { self.visit_stmt(s); }
            },
            Stmt::For { init, condition, increment, body } => {
                if let Some(i) = init { self.visit_stmt(i); }
                if let Some(c) = condition { self.visit_expr(c); }
                if let Some(inc) = increment { self.visit_stmt(inc); }
                for s in &mut body.statements { self.visit_stmt(s); }
            },
            Stmt::TryCatch { try_block, catch_block, .. } => {
                for s in &mut try_block.statements { self.visit_stmt(s); }
                for s in &mut catch_block.statements { self.visit_stmt(s); }
            },
            Stmt::VarDecl { value, .. } => { self.visit_expr(value); },
            Stmt::Expr(expr) => { self.visit_expr(expr); },
            Stmt::Return { value } => { if let Some(e) = value { self.visit_expr(e); } },
            Stmt::StructDecl { fields, .. } => { for s in fields { self.visit_stmt(s); } },
            _ => {}
        }
    }

    fn visit_expr(&mut self, expr: &mut Expr) {
        // Recursive simplification
        let mut simplified = None;
        match expr {
            Expr::BinaryOp { left, op, right } => {
                self.visit_expr(left);
                self.visit_expr(right);
                
                let is_zero = |e: &Expr| {
                    if let Expr::Integer(0) = e { true }
                    else if let Expr::Float(v) = e { *v == 0.0 }
                    else { false }
                };
                let is_one = |e: &Expr| {
                    if let Expr::Integer(1) = e { true }
                    else if let Expr::Float(v) = e { *v == 1.0 }
                    else { false }
                };
                
                if op == "*" {
                    if is_zero(left) || is_zero(right) {
                        simplified = Some(Expr::Float(0.0));
                    } else if is_one(left) {
                        simplified = Some((**right).clone());
                    } else if is_one(right) {
                        simplified = Some((**left).clone());
                    }
                } else if op == "+" {
                    if is_zero(left) {
                        simplified = Some((**right).clone());
                    } else if is_zero(right) {
                        simplified = Some((**left).clone());
                    }
                } else if op == "-" {
                    if is_zero(right) {
                        simplified = Some((**left).clone());
                    }
                    // Could add x - x => 0 but we need Eq on Expr
                } else if op == "/" {
                    if is_one(right) {
                        simplified = Some((**left).clone());
                    }
                }
            },
            Expr::Assignment { target, value } => {
                self.visit_expr(target);
                self.visit_expr(value);
            },
            Expr::FunctionCall { args, .. } => {
                for arg in args { self.visit_expr(arg); }
            },
            Expr::MethodCall { object, args, .. } => {
                self.visit_expr(object);
                for arg in args { self.visit_expr(arg); }
            },
            Expr::PropertyAccess { object, .. } => {
                self.visit_expr(object);
            },
            Expr::IndexAccess { object, index } => {
                self.visit_expr(object);
                self.visit_expr(index);
            },
            Expr::UnaryOp { right, .. } => {
                self.visit_expr(right);
            },
            Expr::ArrayDecl { elements } => {
                for e in elements { self.visit_expr(e); }
            },
            Expr::DictionaryDecl { pairs } => {
                for (k, v) in pairs {
                    self.visit_expr(k);
                    self.visit_expr(v);
                }
            },
            Expr::Attention { target, .. } => {
                self.visit_expr(target);
            },
            Expr::FusedKernel(block) => {
                for s in &mut block.statements { self.visit_stmt(s); }
            },
            _ => {}
        }
        
        if let Some(new_expr) = simplified {
            *expr = new_expr;
        }
    }
}

pub struct TopologicRewritingPass;

impl TopologicRewritingPass {
    pub fn new() -> Self { Self }

    pub fn optimize(&mut self, ast: &mut Vec<Stmt>) {
        for stmt in ast.iter_mut() {
            self.visit_stmt(stmt);
        }
    }

    fn visit_stmt(&mut self, stmt: &mut Stmt) {
        match stmt {
            Stmt::Block(block) | Stmt::MeshBlock { body: block, .. } | Stmt::AsyncCompute(block) => {
                for s in &mut block.statements { self.visit_stmt(s); }
            },
            Stmt::FunctionDecl(decl) => {
                for s in &mut decl.body.statements { self.visit_stmt(s); }
            },
            Stmt::If { true_block, false_block, condition } => {
                self.visit_expr(condition);
                for s in &mut true_block.statements { self.visit_stmt(s); }
                if let Some(fb) = false_block {
                    for s in &mut fb.statements { self.visit_stmt(s); }
                }
            },
            Stmt::While { body, condition } => {
                self.visit_expr(condition);
                for s in &mut body.statements { self.visit_stmt(s); }
            },
            Stmt::For { init, condition, increment, body } => {
                if let Some(i) = init { self.visit_stmt(i); }
                if let Some(c) = condition { self.visit_expr(c); }
                if let Some(inc) = increment { self.visit_stmt(inc); }
                for s in &mut body.statements { self.visit_stmt(s); }
            },
            Stmt::TryCatch { try_block, catch_block, .. } => {
                for s in &mut try_block.statements { self.visit_stmt(s); }
                for s in &mut catch_block.statements { self.visit_stmt(s); }
            },
            Stmt::VarDecl { value, .. } => { self.visit_expr(value); },
            Stmt::Expr(expr) => { self.visit_expr(expr); },
            Stmt::Return { value } => { if let Some(e) = value { self.visit_expr(e); } },
            Stmt::StructDecl { fields, .. } => { for s in fields { self.visit_stmt(s); } },
            _ => {}
        }
    }

    fn visit_expr(&mut self, expr: &mut Expr) {
        match expr {
            Expr::Attention { target, routing } => {
                self.visit_expr(target);
                if routing == "default" {
                    *routing = "flash".to_string(); // Topology rewrite to FlashAttention
                }
            },
            Expr::BinaryOp { left, right, .. } => {
                self.visit_expr(left);
                self.visit_expr(right);
            },
            Expr::Assignment { target, value } => {
                self.visit_expr(target);
                self.visit_expr(value);
            },
            Expr::FunctionCall { args, .. } => {
                for arg in args { self.visit_expr(arg); }
            },
            Expr::MethodCall { object, args, .. } => {
                self.visit_expr(object);
                for arg in args { self.visit_expr(arg); }
            },
            Expr::PropertyAccess { object, .. } => {
                self.visit_expr(object);
            },
            Expr::IndexAccess { object, index } => {
                self.visit_expr(object);
                self.visit_expr(index);
            },
            Expr::UnaryOp { right, .. } => {
                self.visit_expr(right);
            },
            Expr::ArrayDecl { elements } => {
                for e in elements { self.visit_expr(e); }
            },
            Expr::DictionaryDecl { pairs } => {
                for (k, v) in pairs {
                    self.visit_expr(k);
                    self.visit_expr(v);
                }
            },
            Expr::FusedKernel(block) => {
                for s in &mut block.statements { self.visit_stmt(s); }
            },
            _ => {}
        }
    }
}
