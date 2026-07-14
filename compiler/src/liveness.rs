use crate::ast::{Stmt, Expr};
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct MemoryInterval {
    pub name: String,
    pub start_op: usize,
    pub end_op: usize,
    pub size_bytes: usize,
    pub physical_offset: Option<usize>,
}

pub struct LivenessPass {
    lifetimes: HashMap<String, MemoryInterval>,
    current_idx: usize,
}

impl LivenessPass {
    pub fn new() -> Self {
        Self {
            lifetimes: HashMap::new(),
            current_idx: 0,
        }
    }

    pub fn optimize(&mut self, ast: &mut Vec<Stmt>) {
        self.analyze_block(ast);
        self.assign_memory_slots(ast);
    }

    fn analyze_block(&mut self, statements: &[Stmt]) {
        for stmt in statements {
            self.current_idx += 1;
            match stmt {
                Stmt::VarDecl { value, .. } => {
                    self.visit_expr_usage(value, self.current_idx);
                },
                Stmt::TensorDecl { name, shape, .. } => {
                    let mut size_bytes = 4; // Default fp32 = 4 bytes
                    for dim in shape {
                        if let Expr::Integer(val) = dim {
                            size_bytes *= *val as usize;
                        }
                    }
                    self.lifetimes.insert(name.clone(), MemoryInterval {
                        name: name.clone(),
                        start_op: self.current_idx,
                        end_op: self.current_idx,
                        size_bytes,
                        physical_offset: None,
                    });
                },
                Stmt::Expr(expr) => {
                    self.visit_expr_usage(expr, self.current_idx);
                },
                Stmt::Backward(expr) => {
                    self.visit_expr_usage(expr, self.current_idx);
                },
                Stmt::If { condition, true_block, false_block } => {
                    self.visit_expr_usage(condition, self.current_idx);
                    self.analyze_block(&true_block.statements);
                    if let Some(fb) = false_block {
                        self.analyze_block(&fb.statements);
                    }
                },
                Stmt::While { condition, body } => {
                    self.visit_expr_usage(condition, self.current_idx);
                    let loop_start_idx = self.current_idx;
                    self.analyze_block(&body.statements);
                    let loop_end_idx = self.current_idx;
                    
                    // Pragmatic "Loop Conservative" Rule:
                    // Any tensor accessed inside this loop gets its lifetime pinned to the loop's termination.
                    for interval in self.lifetimes.values_mut() {
                        if interval.end_op >= loop_start_idx && interval.end_op <= loop_end_idx {
                            interval.end_op = loop_end_idx;
                        }
                    }
                },
                Stmt::FunctionDecl(decl) => {
                    self.analyze_block(&decl.body.statements);
                },
                Stmt::Block(block) | Stmt::AsyncCompute(block) => {
                    self.analyze_block(&block.statements);
                },
                Stmt::FluidPrecisionBlock { block, .. } => {
                    self.analyze_block(&block.statements);
                },
                Stmt::SparsityBlock { block, .. } => {
                    self.analyze_block(&block.statements);
                },
                Stmt::PruneGraph(expr) => {
                    self.visit_expr_usage(expr, self.current_idx);
                },
                Stmt::EmitSpike { intensity } => {
                    self.visit_expr_usage(intensity, self.current_idx);
                },
                _ => {}
            }
        }
    }

    fn visit_expr_usage(&mut self, expr: &Expr, idx: usize) {
        match expr {
            Expr::Identifier(name) => {
                self.record_usage(name, idx);
            },
            Expr::BinaryOp { left, right, .. } => {
                self.visit_expr_usage(left, idx);
                self.visit_expr_usage(right, idx);
            },
            Expr::Assignment { target, value } => {
                self.visit_expr_usage(target, idx);
                self.visit_expr_usage(value, idx);
            },
            Expr::FunctionCall { args, .. } => {
                for arg in args {
                    self.visit_expr_usage(arg, idx);
                }
            },
            Expr::FusedKernel(exprs) => {
                for e in exprs {
                    self.visit_expr_usage(e, idx);
                }
            },
            Expr::UnaryOp { right, .. } => {
                self.visit_expr_usage(right, idx);
            },
            Expr::Attention { target, .. } => {
                self.visit_expr_usage(target, idx);
            },
            Expr::LexAndEmbed(target) => {
                self.visit_expr_usage(target, self.current_idx);
            },
            Expr::AlignGeodesics(a, b) => {
                self.visit_expr_usage(a, self.current_idx);
                self.visit_expr_usage(b, self.current_idx);
            },
            Expr::GeometricBridge(a, b) => {
                self.visit_expr_usage(a, self.current_idx);
                self.visit_expr_usage(b, self.current_idx);
            },
            Expr::TransposeWeights(a, b) => {
                self.visit_expr_usage(a, self.current_idx);
                self.visit_expr_usage(b, self.current_idx);
            },
            Expr::ReflectRepo => {},
            Expr::HotSwap(target, new_graph) => {
                self.visit_expr_usage(target, self.current_idx);
                self.visit_expr_usage(new_graph, self.current_idx);
            },
            Expr::SpikePrimitive => {},
            Expr::NeuronPrimitive => {},
            _ => {}
        }
    }

    fn record_usage(&mut self, name: &str, idx: usize) {
        // Only update tensors that were explicitly registered in TensorDecl
        if let Some(lifetime) = self.lifetimes.get_mut(name) {
            lifetime.end_op = idx;
        }
    }

    fn assign_memory_slots(&mut self, statements: &mut Vec<Stmt>) {
        // Sort intervals by start time
        let mut intervals: Vec<MemoryInterval> = self.lifetimes.values().cloned().collect();
        intervals.sort_by_key(|i| i.start_op);

        let mut active: Vec<MemoryInterval> = Vec::new(); // Currently live intervals
        let mut variable_offsets: HashMap<String, usize> = HashMap::new();

        // Size-Aware Memory Pooling using First-Fit Allocation
        for mut interval in intervals {
            // Remove dead intervals from active
            active.retain(|active_int| active_int.end_op >= interval.start_op);
            
            // Get all occupied regions: (offset, offset + size)
            let mut occupied: Vec<(usize, usize)> = active.iter()
                .filter_map(|i| i.physical_offset.map(|off| (off, off + i.size_bytes)))
                .collect();
                
            occupied.sort_by_key(|(start, _)| *start);
            
            let mut candidate_offset = 0;
            for (occ_start, occ_end) in occupied {
                if candidate_offset + interval.size_bytes <= occ_start {
                    // Fits perfectly in the gap before this occupied region!
                    break;
                }
                if occ_end > candidate_offset {
                    candidate_offset = occ_end;
                }
            }
            
            interval.physical_offset = Some(candidate_offset);
            variable_offsets.insert(interval.name.clone(), candidate_offset);
            
            active.push(interval);
        }

        // Apply physical offsets to TensorDecls in the AST
        self.apply_slots_to_ast(statements, &variable_offsets);
    }

    fn apply_slots_to_ast(&mut self, statements: &mut Vec<Stmt>, offsets: &HashMap<String, usize>) {
        for stmt in statements.iter_mut() {
            match stmt {
                Stmt::TensorDecl { name, location, backend: _, .. } => {
                    if let Some(offset) = offsets.get(name) {
                        *location = Some(format!("offset_{}", offset));
                    }
                },
                Stmt::FunctionDecl(decl) => {
                    self.apply_slots_to_ast(&mut decl.body.statements, offsets);
                },
                Stmt::Block(block) | Stmt::AsyncCompute(block) => {
                    self.apply_slots_to_ast(&mut block.statements, offsets);
                },
                Stmt::If { true_block, false_block, .. } => {
                    self.apply_slots_to_ast(&mut true_block.statements, offsets);
                    if let Some(fb) = false_block {
                        self.apply_slots_to_ast(&mut fb.statements, offsets);
                    }
                },
                Stmt::While { body, .. } => {
                    self.apply_slots_to_ast(&mut body.statements, offsets);
                },
                _ => {}
            }
        }
    }
}
