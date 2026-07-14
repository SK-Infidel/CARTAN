use crate::ast::{Stmt, Expr, ManifoldSpace};
use crate::ir::Opcode;
use std::collections::HashMap;

pub struct CodeGenerator {
    buffer: Vec<u8>,
    instruction_count: u32,
    alloc_count: u32,
    tensor_id_counter: u32,
    env: Vec<HashMap<String, u32>>,
}

impl CodeGenerator {
    pub fn new() -> Self {
        Self {
            buffer: Vec::new(),
            instruction_count: 0,
            alloc_count: 0,
            tensor_id_counter: 1, // Start IDs at 1
            env: vec![HashMap::new()],
        }
    }


    fn push_scope(&mut self) {
        self.env.push(HashMap::new());
    }

    fn pop_scope(&mut self) {
        self.env.pop();
    }

    fn resolve_var(&self, name: &str) -> Option<u32> {
        for scope in self.env.iter().rev() {
            if let Some(&id) = scope.get(name) {
                return Some(id);
            }
        }
        None
    }

    pub fn generate(&mut self, ast: &[Stmt]) -> Vec<u8> {
        // Reserve space for Magic Number + Header (16 bytes)
        for _ in 0..16 {
            self.buffer.push(0);
        }

        for stmt in ast {
            self.visit_stmt(stmt);
        }

        // Patch Header
        self.patch_header();

        self.buffer.clone()
    }

    fn patch_header(&mut self) {
        // Magic: AER0
        self.buffer[0] = b'A';
        self.buffer[1] = b'E';
        self.buffer[2] = b'R';
        self.buffer[3] = b'0';

        // Version: 1
        let version: u32 = 1;
        self.buffer[4..8].copy_from_slice(&version.to_le_bytes());

        // Instruction Count
        self.buffer[8..12].copy_from_slice(&self.instruction_count.to_le_bytes());

        // Alloc Count
        self.buffer[12..16].copy_from_slice(&self.alloc_count.to_le_bytes());
    }

    fn emit_jump(&mut self, opcode: Opcode) -> usize {
        self.emit_opcode(opcode);
        let offset = self.buffer.len();
        self.buffer.extend_from_slice(&0u32.to_le_bytes()); // placeholder
        offset
    }

    fn patch_jump(&mut self, offset: usize) {
        let target = self.buffer.len() as u32;
        self.buffer[offset..offset+4].copy_from_slice(&target.to_le_bytes());
    }

    fn emit_opcode(&mut self, opcode: Opcode) {
        self.buffer.push(opcode as u8);
        self.instruction_count += 1;
    }

    fn visit_stmt(&mut self, stmt: &Stmt) {
        match stmt {
            Stmt::FunctionDecl(decl) => {
                // In Sprint 7, we just enter the block to process local statements
                self.visit_stmt(&Stmt::Block(decl.body.clone()));
            },
            Stmt::Block(block_stmt) => {
                self.push_scope();
                for stmt in &block_stmt.statements {
                    self.visit_stmt(stmt);
                }
                self.pop_scope();
            },
            Stmt::AsyncCompute(block_stmt) => {
                self.push_scope();
                for stmt in &block_stmt.statements {
                    self.visit_stmt(stmt);
                }
                self.pop_scope();
            },
            Stmt::Backward(expr) => {
                let id_opt = self.visit_expr(expr);
                self.emit_opcode(Opcode::Backward);
                if let Some(id) = id_opt {
                    self.buffer.extend_from_slice(&id.to_le_bytes());
                } else {
                    self.buffer.extend_from_slice(&0u32.to_le_bytes());
                }
            },
            Stmt::StructDecl { name: _, fields: _ } => { /* ignore for now */ },

            Stmt::VarDecl { name, is_const: _, value } => {
                if let Some(id) = self.visit_expr(value) {
                    if let Some(scope) = self.env.last_mut() {
                        scope.insert(name.clone(), id);
                    }
                }
            },

            Stmt::TensorDecl { name, shape, manifold, location: _, backend: _, layout: _ } => {
                self.emit_opcode(Opcode::AllocTensor);
                let t_id = self.tensor_id_counter;
                if let Some(scope) = self.env.last_mut() {
                    scope.insert(name.clone(), t_id);
                }
                
                // Tensor ID
                let t_id = self.tensor_id_counter;
                self.tensor_id_counter += 1;
                self.buffer.extend_from_slice(&t_id.to_le_bytes());

                // Rank
                self.buffer.push(shape.len() as u8);

                // Space Flag Byte
                let space_flag: u8 = match manifold {
                    ManifoldSpace::Euclidean => 0x00,
                    ManifoldSpace::Minkowski => 0x01,
                    ManifoldSpace::PoincareDisk => 0x02,
                    ManifoldSpace::Custom(_) => 0xFF,
                };
                self.buffer.push(space_flag);

                // Dimensions (Evaluated naively assuming Integer literals for v0.1)
                for dim_expr in shape {
                    let dim_val = match dim_expr {
                        Expr::Integer(val) => *val as u32,
                        _ => 1, // Naive fallback for bootstrap
                    };
                    self.buffer.extend_from_slice(&dim_val.to_le_bytes());
                }
                
                self.alloc_count += 1;
            },

            Stmt::If { condition, true_block, false_block } => {
                self.visit_expr(condition);
                let jump_to_false = self.emit_jump(Opcode::JumpIfFalse);
                
                self.visit_stmt(&Stmt::Block(true_block.clone()));
                
                if let Some(fb) = false_block {
                    let jump_to_end = self.emit_jump(Opcode::Jump);
                    self.patch_jump(jump_to_false);
                    self.visit_stmt(&Stmt::Block(fb.clone()));
                    self.patch_jump(jump_to_end);
                } else {
                    self.patch_jump(jump_to_false);
                }
            },
            Stmt::While { condition, body } => {
                let loop_start = self.buffer.len() as u32;
                self.visit_expr(condition);
                let jump_to_end = self.emit_jump(Opcode::JumpIfFalse);
                
                self.visit_stmt(&Stmt::Block(body.clone()));
                
                self.emit_opcode(Opcode::Jump);
                self.buffer.extend_from_slice(&loop_start.to_le_bytes());
                self.patch_jump(jump_to_end);
            },
            Stmt::TryCatch { try_block, .. } => {
                for stmt in &try_block.statements {
                    self.visit_stmt(stmt);
                }
            },
            Stmt::FluidPrecisionBlock { block, .. } => {
                for stmt in &block.statements {
                    self.visit_stmt(stmt);
                }
            },
            Stmt::SparsityBlock { block, .. } => {
                for stmt in &block.statements {
                    self.visit_stmt(stmt);
                }
            },
            Stmt::PruneGraph(expr) => {
                self.visit_expr(expr);
            },
            Stmt::EmitSpike { intensity } => {
                self.visit_expr(intensity);
            },
            Stmt::Expr(expr) => {

                let _ = self.visit_expr(expr);
            },
            Stmt::Return { value } => {
                if let Some(expr) = value {
                    let _ = self.visit_expr(expr);
                }
            },
            _ => {
                // Ignore other statements for bootstrap
            }
        }
    }

    fn visit_expr(&mut self, expr: &Expr) -> Option<u32> {
        match expr {
            Expr::BinaryOp { left, op, right } => {
                // Visit children (Postfix evaluation order for stack-based execution)
                self.visit_expr(left);
                self.visit_expr(right);

                // Emit opcode
                match op.as_str() {
                    "+" => self.emit_opcode(Opcode::Add),
                    "-" => self.emit_opcode(Opcode::Sub),
                    "*" => self.emit_opcode(Opcode::Mul),
                    "/" => self.emit_opcode(Opcode::Div),
                    "@" => self.emit_opcode(Opcode::MatMul),
                    "<" => self.emit_opcode(Opcode::CmpLt),
                    "==" => self.emit_opcode(Opcode::CmpEq),
                    _ => {}
                }
                None
            },
            Expr::Identifier(name) => {
                if let Some(id) = self.resolve_var(name) {
                    self.emit_opcode(Opcode::PushTensor);
                    self.buffer.extend_from_slice(&id.to_le_bytes());
                    Some(id)
                } else {
                    None
                }
            },
            Expr::StreamInit { .. } => None,
            Expr::SievingCacheInit => {
                let id = self.tensor_id_counter;
                self.tensor_id_counter += 1;
                // Emit some mock opcode or just return the ID
                Some(id)
            },
            Expr::FractalAttentionInit => {
                let id = self.tensor_id_counter;
                self.tensor_id_counter += 1;
                Some(id)
            },
            Expr::ElasticVocabularyInit => None,
            Expr::LexAndEmbed(target) => self.visit_expr(target),
            Expr::AlignGeodesics(a, b) => {
                self.visit_expr(a);
                self.visit_expr(b);
                None
            },
            Expr::GeometricBridge(a, b) => {
                self.visit_expr(a);
                self.visit_expr(b);
                None
            },
            Expr::TransposeWeights(a, b) => {
                self.visit_expr(a);
                self.visit_expr(b);
                None
            },
            Expr::ReflectRepo => {
                None
            },
            Expr::HotSwap(target, new_graph) => {
                self.visit_expr(target);
                self.visit_expr(new_graph);
                None
            },
            Expr::SpikePrimitive => None,
            Expr::NeuronPrimitive => None,
            Expr::Attention { target, .. } => self.visit_expr(target),
            Expr::MethodCall { object, method_name, args } => {
                if method_name == "load_dma" {
                    // Check if object is Cartan
                    if let Expr::Identifier(name) = &**object {
                        if name == "Cartan" {
                            self.emit_opcode(Opcode::LoadDMA);
                            self.buffer.extend_from_slice(&0u32.to_le_bytes()); // Dummy ID for the path
                            return None;
                        }
                    }
                } else if method_name == "prune_graph" {
                    if let Expr::Identifier(name) = &**object {
                        if name == "Cartan" {
                            if args.len() > 0 {
                                self.visit_expr(&args[0]);
                            }
                            // Emitting mock prune graph opcode/instruction if it existed, for now just consume args.
                            return None;
                        }
                    }
                }
                
                let obj_id = self.visit_expr(object);
                for arg in args {
                    self.visit_expr(arg);
                }
                if method_name == "poll" {
                    self.emit_opcode(Opcode::PollStream);
                    let target_id = self.tensor_id_counter;
                    self.tensor_id_counter += 1;
                    if let Some(id) = obj_id {
                        self.buffer.extend_from_slice(&id.to_le_bytes()); // source stream id
                    } else {
                        self.buffer.extend_from_slice(&0u32.to_le_bytes());
                    }
                    self.buffer.extend_from_slice(&target_id.to_le_bytes()); // target tensor id
                    Some(target_id)
                } else {
                    None
                }
            },

            Expr::Assignment { target, value } => {
                if let Expr::IndexAccess { object, index } = &**target {
                    if let Expr::Identifier(name) = &**object {
                        if let Some(id) = self.resolve_var(name) {
                            self.emit_opcode(Opcode::StoreElement);
                            self.buffer.extend_from_slice(&id.to_le_bytes());
                            
                            // index (assume Integer for v0.1)
                            let idx_val = match &**index {
                                Expr::Integer(n) => *n as u32,
                                _ => 0,
                            };
                            self.buffer.extend_from_slice(&idx_val.to_le_bytes());
                            
                            // value (assume Float for v0.1)
                            let val = match &**value {
                                Expr::Float(f) => *f as f32,
                                Expr::Integer(n) => *n as f32,
                                _ => 0.0,
                            };
                            self.buffer.extend_from_slice(&val.to_le_bytes());
                        }
                    }
                }
                None
            },
            Expr::FunctionCall { name, args } => {
                if name == "Cartan.load_dma" {
                    // Expect 2 args: string literal path, string literal hardware location
                    self.emit_opcode(Opcode::LoadDMA);
                    self.buffer.extend_from_slice(&0u32.to_le_bytes()); // Dummy ID for the path
                    // Usually we'd push the arguments into the constant pool and emit their indices
                    // but for this prototype, we'll just emit the opcode.
                    return None;
                }
                for arg in args {
                    self.visit_expr(arg);
                }
                None
            },
            Expr::FusedKernel(exprs) => {
                let mut last = None;
                for e in exprs {
                    last = self.visit_expr(e);
                }
                last
            },
            _ => None
        }
    }
}
