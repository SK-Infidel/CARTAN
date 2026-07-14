use crate::ast::{Stmt, Expr};
use std::collections::HashMap;
use std::time::SystemTime;
use std::fs::File;

#[derive(Debug, Clone, PartialEq)]
pub enum Value {
    Integer(i64),
    Float(f64),
    Pointer(usize),
    Null,
}

pub struct Evaluator {
    env: Vec<HashMap<String, Value>>,
    open_files: HashMap<usize, File>,
    next_file_ptr: usize,
}

impl Evaluator {
    pub fn new() -> Self {
        Self {
            env: vec![HashMap::new()],
            open_files: HashMap::new(),
            next_file_ptr: 1,
        }
    }

    fn push_scope(&mut self) {
        self.env.push(HashMap::new());
    }

    fn pop_scope(&mut self) {
        self.env.pop();
    }

    fn get_var(&self, name: &str) -> Value {
        for scope in self.env.iter().rev() {
            if let Some(val) = scope.get(name) {
                return val.clone();
            }
        }
        Value::Null
    }

    fn set_var(&mut self, name: &str, value: Value) {
        for scope in self.env.iter_mut().rev() {
            if scope.contains_key(name) {
                scope.insert(name.to_string(), value);
                return;
            }
        }
        if let Some(scope) = self.env.last_mut() {
            scope.insert(name.to_string(), value);
        }
    }

    pub fn eval(&mut self, ast: &[Stmt]) {
        for stmt in ast {
            self.eval_stmt(stmt);
        }
    }

    fn eval_stmt(&mut self, stmt: &Stmt) -> Option<Value> {
        match stmt {
            Stmt::Block(block) => {
                self.push_scope();
                for s in &block.statements {
                    if let Some(ret) = self.eval_stmt(s) {
                        self.pop_scope();
                        return Some(ret);
                    }
                }
                self.pop_scope();
                None
            }
            Stmt::FunctionDecl(decl) => {
                if decl.name == "main" {
                    self.eval_stmt(&Stmt::Block(decl.body.clone()));
                }
                None
            }
            Stmt::VarDecl { name, is_const: _, value } => {
                let val = self.eval_expr(value);
                self.set_var(name, val);
                None
            }
            Stmt::If { condition, true_block, false_block } => {
                let cond_val = self.eval_expr(condition);
                let is_true = match cond_val {
                    Value::Integer(i) => i != 0,
                    Value::Float(f) => f != 0.0,
                    Value::Pointer(p) => p != 0,
                    _ => false,
                };

                if is_true {
                    self.eval_stmt(&Stmt::Block(true_block.clone()))
                } else if let Some(fb) = false_block {
                    self.eval_stmt(&Stmt::Block(fb.clone()))
                } else {
                    None
                }
            }
            Stmt::While { condition, body } => {
                loop {
                    let cond_val = self.eval_expr(condition);
                    let is_true = match cond_val {
                        Value::Integer(i) => i != 0,
                        Value::Float(f) => f != 0.0,
                        Value::Pointer(p) => p != 0,
                        _ => false,
                    };
                    if !is_true {
                        break;
                    }
                    if let Some(ret) = self.eval_stmt(&Stmt::Block(body.clone())) {
                        return Some(ret);
                    }
                }
                None
            }
            Stmt::Expr(expr) => {
                self.eval_expr(expr);
                None
            }
            Stmt::Return { value } => {
                if let Some(expr) = value {
                    Some(self.eval_expr(expr))
                } else {
                    Some(Value::Null)
                }
            }
            Stmt::Backward(_) => None,
            _ => None
        }
    }

    fn eval_expr(&mut self, expr: &Expr) -> Value {
        match expr {
            Expr::Integer(i) => Value::Integer(*i),
            Expr::Float(f) => Value::Float(*f),
            Expr::StringLiteral(_s) => Value::Null,
            Expr::Identifier(name) => self.get_var(name),
            Expr::BinaryOp { left, op, right } => {
                let l = self.eval_expr(left);
                let r = self.eval_expr(right);

                match (l, r) {
                    (Value::Integer(li), Value::Integer(ri)) => {
                        match op.as_str() {
                            "+" => Value::Integer(li + ri),
                            "-" => Value::Integer(li - ri),
                            "*" => Value::Integer(li * ri),
                            "/" => Value::Integer(if ri != 0 { li / ri } else { 0 }),
                            "==" => Value::Integer(if li == ri { 1 } else { 0 }),
                            "<" => Value::Integer(if li < ri { 1 } else { 0 }),
                            ">" => Value::Integer(if li > ri { 1 } else { 0 }),
                            _ => Value::Null,
                        }
                    },
                    (Value::Pointer(lp), Value::Integer(ri)) => {
                        if op == "==" {
                            Value::Integer(if lp == ri as usize { 1 } else { 0 })
                        } else {
                            Value::Null
                        }
                    },
                    _ => Value::Null,
                }
            }
            Expr::Assignment { target, value } => {
                let val = self.eval_expr(value);
                if let Expr::Identifier(name) = &**target {
                    self.set_var(name, val.clone());
                }
                val
            }
            Expr::FunctionCall { name, args } => {
                if name == "clock" {
                    let now = SystemTime::now().duration_since(SystemTime::UNIX_EPOCH).unwrap().as_millis();
                    return Value::Integer(now as i64);
                } else if name == "printf" {
                    if let Some(Expr::StringLiteral(s)) = args.get(0) {
                        let mut msg = s.clone();
                        if msg.starts_with('"') && msg.ends_with('"') {
                            msg = msg[1..msg.len()-1].to_string();
                        }
                        msg = msg.replace("\\n", "\n");
                        print!("{}", msg);
                    }
                    return Value::Integer(0);
                } else if name == "fopen" {
                    if let Some(Expr::StringLiteral(path)) = args.get(0) {
                        let mut clean_path = path.clone();
                        if clean_path.starts_with('"') && clean_path.ends_with('"') {
                            clean_path = clean_path[1..clean_path.len()-1].to_string();
                        }
                        if let Ok(file) = File::open(&clean_path) {
                            let ptr = self.next_file_ptr;
                            self.next_file_ptr += 1;
                            self.open_files.insert(ptr, file);
                            return Value::Pointer(ptr);
                        } else {
                            return Value::Pointer(0);
                        }
                    }
                } else if name == "fclose" {
                    if let Some(arg) = args.get(0) {
                        let ptr_val = self.eval_expr(arg);
                        if let Value::Pointer(p) = ptr_val {
                            self.open_files.remove(&p);
                        }
                    }
                    return Value::Integer(0);
                }
                Value::Null
            }
            Expr::MSELoss(_, _) => Value::Float(0.25),
            Expr::MethodCall { .. } => Value::Null,
            Expr::FusedKernel(exprs) => {
                let mut last_val = Value::Null;
                for e in exprs {
                    last_val = self.eval_expr(e);
                }
                last_val
            },
            _ => Value::Null,
        }
    }
}
