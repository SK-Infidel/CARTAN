use std::collections::HashMap;
use crate::ast::{Stmt, Expr};
use crate::error::Diagnostic;
use crate::token::Span;
use crate::types::{CartanType, Dimension};

pub struct TypeChecker {
    functions: HashMap<String, Vec<crate::ast::FunctionDecl>>,
    symbol_table: Vec<HashMap<String, CartanType>>,
}

impl TypeChecker {
    pub fn new() -> Self {
        Self {
            symbol_table: vec![HashMap::new()],
            functions: HashMap::new(),
        }
    }


    fn push_scope(&mut self) {
        self.symbol_table.push(HashMap::new());
    }

    fn pop_scope(&mut self) {
        self.symbol_table.pop();
    }

    fn resolve_var(&self, name: &str) -> Option<CartanType> {
        for scope in self.symbol_table.iter().rev() {
            if let Some(t) = scope.get(name) {
                return Some(t.clone());
            }
        }
        None
    }

    pub fn check(&mut self, ast: &mut [Stmt]) -> Result<(), Diagnostic> {
        for stmt in ast.iter() {
            if let Stmt::FunctionDecl(decl) = stmt {
                self.functions.entry(decl.name.clone()).or_default().push(decl.clone());
            }
        }
        for stmt in ast {
            self.visit_stmt(stmt)?;
        }
        Ok(())
    }

    fn visit_stmt(&mut self, stmt: &mut Stmt) -> Result<(), Diagnostic> {
        match stmt {
            Stmt::Placeholder(_) => { /* Ignore placeholders during type checking */ },
            Stmt::FieldDecl { name: _, type_name: _ } => { /* no-op */ },
            Stmt::StructDecl { name: _, fields } => {
                for f in fields {
                    self.visit_stmt(f)?;
                }
            },
            Stmt::ImplDecl { target_name, methods, .. } => {
                self.push_scope();
                if let Some(scope) = self.symbol_table.last_mut() {
                    scope.insert("self".to_string(), CartanType::Struct(target_name.clone()));
                }
                for m in methods {
                    self.visit_stmt(m)?;
                }
                self.pop_scope();
            },
            Stmt::TraitDecl { methods, .. } => {
                for m in methods {
                    self.visit_stmt(m)?;
                }
            },
            Stmt::TensorDecl { name, shape, manifold, layout, location: _, backend: _, is_lazy: _, is_unified: _, is_latent: _ } => {
                let mut dimensions = Vec::new();
                for dim_expr in shape {
                    match dim_expr {
                        Expr::Integer(val) => {
                            dimensions.push(Dimension::Fixed(*val as u32));
                        }
                        Expr::Identifier(ident) => {
                            dimensions.push(Dimension::Symbolic(ident.clone()));
                        }
                        _ => {
                            // Using a dummy span for now; full span tracking on AST nodes would be ideal
                            return Err(Diagnostic::error(
                                "Tensor dimension must be an integer literal or a symbolic identifier.",
                                Span::new(0, 0, 0), 
                            ));
                        }
                    }
                }
                if let Some(scope) = self.symbol_table.last_mut() {
                    scope.insert(name.clone(), CartanType::Tensor(dimensions, manifold.clone(), layout.clone()));
                }
            },
            Stmt::ParameterDecl { name, shape, manifold, layout, location: _, backend: _, optimizer } => {
                let mut dimensions = Vec::new();
                for dim_expr in shape {
                    match dim_expr {
                        Expr::Integer(val) => {
                            dimensions.push(Dimension::Fixed(*val as u32));
                        }
                        Expr::Identifier(ident) => {
                            dimensions.push(Dimension::Symbolic(ident.clone()));
                        }
                        _ => {
                            // Using a dummy span for now; full span tracking on AST nodes would be ideal
                            return Err(Diagnostic::error(
                                "Parameter dimension must be an integer literal or a symbolic identifier.",
                                Span::new(0, 0, 0), 
                            ));
                        }
                    }
                }
                if let Some(scope) = self.symbol_table.last_mut() {
                    scope.insert(name.clone(), CartanType::Parameter(dimensions, manifold.clone(), layout.clone(), optimizer.clone()));
                }
            },
            Stmt::SequenceDecl { name, max_len } => {
                let dim = match max_len {
                    Expr::Integer(val) => Dimension::Fixed(*val as u32),
                    Expr::Identifier(ident) => Dimension::Symbolic(ident.clone()),
                    _ => return Err(Diagnostic::error("Sequence max length must be int or symbolic.", Span::new(0, 0, 0))),
                };
                if let Some(scope) = self.symbol_table.last_mut() {
                    scope.insert(name.clone(), CartanType::Sequence(dim));
                }
            },
            Stmt::BlockDecl { name, size } => {
                let dim = match size {
                    Expr::Integer(val) => Dimension::Fixed(*val as u32),
                    Expr::Identifier(ident) => Dimension::Symbolic(ident.clone()),
                    _ => return Err(Diagnostic::error("Block size must be int or symbolic.", Span::new(0, 0, 0))),
                };
                if let Some(scope) = self.symbol_table.last_mut() {
                    scope.insert(name.clone(), CartanType::Block(dim));
                }
            },
            Stmt::LatticeDecl { name, lattice_type, dim } => {
                let dim_val = match dim {
                    Expr::Integer(val) => Dimension::Fixed(*val as u32),
                    Expr::Identifier(ident) => Dimension::Symbolic(ident.clone()),
                    _ => return Err(Diagnostic::error("Lattice dimension must be an integer literal or a symbolic identifier.", Span::new(0, 0, 0))),
                };
                if let Some(scope) = self.symbol_table.last_mut() {
                    scope.insert(name.clone(), CartanType::Lattice { lattice_type: lattice_type.clone(), dim: dim_val });
                }
            },
            Stmt::TreeDecl { name, element_type } => {
                // Determine the generic element type (currently primitive match)
                let elem_cartan_type = match element_type.as_str() {
                    "tensor" => CartanType::Tensor(vec![], crate::ast::ManifoldSpace::Euclidean, None),
                    "vector" => CartanType::Vector { data_type: None, dim: Dimension::Fixed(0), space: crate::ast::VectorSpace::AmbientEuclidean },
                    "float" => CartanType::Float,
                    "int" => CartanType::Integer,
                    _ => CartanType::Unknown,
                };
                if let Some(scope) = self.symbol_table.last_mut() {
                    scope.insert(name.clone(), CartanType::Tree { element_type: Box::new(elem_cartan_type) });
                }
            },
            Stmt::VectorDecl { name, data_type, dim, space } => {
                let dim_val = match dim {
                    Expr::Integer(val) => Dimension::Fixed(*val as u32),
                    Expr::Identifier(ident) => Dimension::Symbolic(ident.clone()),
                    _ => return Err(Diagnostic::error("Vector dimension must be an integer literal or a symbolic identifier.", Span::new(0, 0, 0))),
                };
                if let crate::ast::VectorSpace::TangentSpace { anchor } = space {
                    // Check if anchor exists and is a tensor
                    let anchor_type = self.resolve_var(anchor);
                    match anchor_type {
                        Some(CartanType::Tensor(_, _, _)) | Some(CartanType::Parameter(_, _, _, _)) => {
                            // Anchor is valid
                        },
                        Some(_) => return Err(Diagnostic::error(&format!("Vector anchor '{}' must be a tensor on a manifold.", anchor), Span::new(0,0,0))),
                        None => return Err(Diagnostic::error(&format!("Undefined anchor '{}' for tangent vector.", anchor), Span::new(0,0,0))),
                    }
                }
                if let Some(scope) = self.symbol_table.last_mut() {
                    scope.insert(name.clone(), CartanType::Vector {
                        data_type: data_type.clone(),
                        dim: dim_val,
                        space: space.clone(),
                    });
                }
            },
            Stmt::Expr(expr) => {
                self.visit_expr(expr)?;
            },
            Stmt::Return { value } => {
                if let Some(expr) = value {
                    self.visit_expr(expr)?;
                }
            },
            Stmt::FunctionDecl(decl) => {
                let mut mangled = decl.name.clone();
                for param in &decl.parameters {
                    if let Some(m) = &param.manifold {
                        mangled.push('_');
                        mangled.push_str(&format!("{:?}", m).to_lowercase());
                    }
                }
                decl.name = mangled;
                
                // Register function parameters in a new scope
                self.push_scope();
                for param in &decl.parameters {
                    // For now, treat all parameters as empty tensors to allow matrix math checks
                    if let Some(scope) = self.symbol_table.last_mut() {
                        scope.insert(param.name.clone(), CartanType::Tensor(vec![], crate::ast::ManifoldSpace::Euclidean, None));
                    }
                }
                for stmt in &mut decl.body.statements {
                    self.visit_stmt(stmt)?;
                }
                self.pop_scope();
            },
            Stmt::Block(block_stmt) => {
                self.push_scope();
                for stmt in &mut block_stmt.statements {
                    self.visit_stmt(stmt)?;
                }
                self.pop_scope();
            },

            Stmt::VarDecl { name, is_const: _, value, type_annotation: _ } => {
                let val_type = self.visit_expr(value)?;
                if let Some(scope) = self.symbol_table.last_mut() {
                    scope.insert(name.clone(), val_type);
                }
            },

            
            Stmt::LayerDecl { name: _, layer_type: _, dim: _, activation: _ } => {}, Stmt::GraphDecl { name: _, body: _ } => {}, Stmt::Match { condition, arms } => {
                self.visit_expr(condition)?;
                for (pattern, body) in arms {
                    if let Some(p) = pattern {
                        self.visit_expr(p)?;
                    }
                    self.visit_stmt(body)?;
                }
            },
            Stmt::If { condition, true_block, false_block } => {
                let _cond_type = self.visit_expr(condition)?;
                self.push_scope();
                for stmt in &mut true_block.statements {
                    self.visit_stmt(stmt)?;
                }
                self.pop_scope();
                if let Some(fb) = false_block {
                    self.push_scope();
                    for stmt in &mut fb.statements {
                        self.visit_stmt(stmt)?;
                    }
                    self.pop_scope();
                }
            },
            Stmt::While { condition, body } => {
                let _cond_type = self.visit_expr(condition)?;
                self.push_scope();
                for stmt in &mut body.statements {
                    self.visit_stmt(stmt)?;
                }
                self.pop_scope();
            },
            Stmt::TryCatch { try_block, catch_var, catch_block } => {
                self.push_scope();
                for stmt in &mut try_block.statements {
                    self.visit_stmt(stmt)?;
                }
                self.pop_scope();
                
                self.push_scope();
                if let Some(scope) = self.symbol_table.last_mut() {
                    scope.insert(catch_var.clone(), CartanType::String); // Error message
                }
                for stmt in &mut catch_block.statements {
                    self.visit_stmt(stmt)?;
                }
                self.pop_scope();
            },
            Stmt::AsyncCompute(block) => {
                self.push_scope();
                for stmt in &mut block.statements {
                    self.visit_stmt(stmt)?;
                }
                self.pop_scope();
            },
            Stmt::Backward(expr) => {
                self.visit_expr(expr)?;
            },
            Stmt::FluidPrecisionBlock { block, .. } => {
                self.push_scope();
                for stmt in &mut block.statements {
                    self.visit_stmt(stmt)?;
                }
                self.pop_scope();
            },
            Stmt::SparsityBlock { block, .. } => {
                self.push_scope();
                for stmt in &mut block.statements {
                    self.visit_stmt(stmt)?;
                }
                self.pop_scope();
            },
            Stmt::PruneGraph(expr) => {
                self.visit_expr(expr)?;
            },
            Stmt::EmitSpike { intensity } => {
                self.visit_expr(intensity)?;
            },
            Stmt::AbsorbWeights { donor_path: _, local_tensor } => {
                if self.resolve_var(local_tensor).is_none() {
                    return Err(Diagnostic::error(&format!("Variable '{}' not found", local_tensor), Span::new(0,0,0)));
                }
            },
            Stmt::ProjectVocab { source_tensor, target_vocab } => {
                if self.resolve_var(source_tensor).is_none() {
                    return Err(Diagnostic::error(&format!("Variable '{}' not found", source_tensor), Span::new(0,0,0)));
                }
                if self.resolve_var(target_vocab).is_none() {
                    return Err(Diagnostic::error(&format!("Variable '{}' not found", target_vocab), Span::new(0,0,0)));
                }
            },
            Stmt::ImportModel { uri: _, alias } => {
                if let Some(scope) = self.symbol_table.last_mut() {
                    scope.insert(alias.clone(), CartanType::Unknown);
                }
            },
            _ => {}
        }
        Ok(())
    }

    fn visit_expr(&mut self, expr: &mut Expr) -> Result<CartanType, Diagnostic> {
        match expr {


            Expr::IndexAccess { object, index } => {
                let _obj_type = self.visit_expr(object)?;
                let _idx_type = self.visit_expr(index)?;
                // For now, Cartan tensors contain Floats
                Ok(CartanType::Float)
            },
            Expr::Assignment { target, value } => {
                let _target_type = self.visit_expr(target)?;
                let value_type = self.visit_expr(value)?;
                Ok(value_type)
            },
            Expr::FusedKernel(block) => {
                let mut last_type = CartanType::Unknown;
                for s in &mut block.statements {
                    if let crate::ast::Stmt::Expr(e) = s {
                        last_type = self.visit_expr(e)?;
                    } else {
                        self.visit_stmt(s)?;
                    }
                }
                Ok(last_type)
            },
            Expr::StreamInit { .. } => Ok(CartanType::Stream),
            Expr::SievingCacheInit => Ok(CartanType::Unknown), // Replace with specific type when implemented
            Expr::FractalAttentionInit => Ok(CartanType::Unknown), // Replace with specific type when implemented
            Expr::ElasticVocabularyInit => Ok(CartanType::Unknown),
            Expr::TokenizeBPE { text, .. } => {
                self.visit_expr(text)?;
                Ok(CartanType::Unknown) // Would be a Sequence
            },
            Expr::AlignSpans { projection_matrix, .. } => {
                self.visit_expr(projection_matrix)?;
                Ok(CartanType::Unknown) // Projection Matrix Tensor
            },
            Expr::LexAndEmbed(target) => {
                self.visit_expr(target)?;
                Ok(CartanType::Unknown)
            },
            Expr::AlignGeodesics(a, b) => {
                self.visit_expr(a)?;
                self.visit_expr(b)?;
                Ok(CartanType::Unknown)
            },
            Expr::GeometricBridge(a, b) => {
                self.visit_expr(a)?;
                self.visit_expr(b)?;
                Ok(CartanType::Unknown)
            },
            Expr::Transpose(inner) => {
                let inner_type = self.visit_expr(inner)?;
                match inner_type {
                    CartanType::Tensor(dims, space, layout) => {
                        let mut new_dims = dims.clone();
                        if new_dims.len() >= 2 {
                            let len = new_dims.len();
                            new_dims.swap(len - 1, len - 2);
                        }
                        Ok(CartanType::Tensor(new_dims, space, layout))
                    },
                    _ => Ok(inner_type)
                }
            },
            Expr::TransposeWeights(a, b) => {
                self.visit_expr(a)?;
                self.visit_expr(b)?;
                Ok(CartanType::Unknown)
            },
            Expr::ReflectRepo => {
                Ok(CartanType::Unknown)
            },
            Expr::Quote(block) => {
                for stmt in &mut block.statements {
                    self.visit_stmt(stmt)?;
                }
                Ok(CartanType::Tensor(vec![crate::types::Dimension::Fixed(0)], crate::ast::ManifoldSpace::Euclidean, None))
            },
            Expr::HotSwap(target, new_graph) => {
                self.visit_expr(target)?;
                self.visit_expr(new_graph)?;
                Ok(CartanType::Unknown)
            },
            Expr::StringView { source, start, len } => {
                self.visit_expr(source)?;
                self.visit_expr(start)?;
                self.visit_expr(len)?;
                Ok(CartanType::StringView)
            },
            Expr::SimdFindFirst { buffer, target_byte } => {
                self.visit_expr(buffer)?;
                self.visit_expr(target_byte)?;
                Ok(CartanType::Integer)
            },
            Expr::SimdMaskAlpha { buffer } => {
                self.visit_expr(buffer)?;
                Ok(CartanType::Integer)
            },
            Expr::SpikePrimitive => Ok(CartanType::Unknown),
            Expr::NeuronPrimitive => Ok(CartanType::Unknown),
            Expr::ParallelTransport { vector, from, to } => {
                let vec_type = self.visit_expr(vector)?;
                let from_type = self.visit_expr(from)?;
                let to_type = self.visit_expr(to)?;
                
                let (dt, dim, _space) = match vec_type {
                    CartanType::Vector { data_type, dim, space } => (data_type, dim, space),
                    _ => return Err(Diagnostic::error("First argument to parallel_transport must be a vector.", Span::new(0,0,0))),
                };
                
                let from_space = match from_type {
                    CartanType::Tensor(_, m, _) | CartanType::Parameter(_, m, _, _) => m,
                    _ => return Err(Diagnostic::error("'from' argument must be a tensor.", Span::new(0,0,0))),
                };
                let to_space = match to_type {
                    CartanType::Tensor(_, m, _) | CartanType::Parameter(_, m, _, _) => m,
                    _ => return Err(Diagnostic::error("'to' argument must be a tensor.", Span::new(0,0,0))),
                };
                
                if from_space != to_space {
                    return Err(Diagnostic::error("Geometric Misalignment: 'from' and 'to' points must reside on the same manifold space for parallel transport.", Span::new(0,0,0)));
                }

                // If 'to' is an identifier, we can anchor the returned vector to it.
                // But Expr might not be an Identifier. If it is, we bind it.
                let new_anchor = if let Expr::Identifier(id) = &**to {
                    id.clone()
                } else {
                    return Err(Diagnostic::error("'to' argument must be a variable identifier to act as a vector anchor.", Span::new(0,0,0)));
                };

                Ok(CartanType::Vector {
                    data_type: dt,
                    dim,
                    space: crate::ast::VectorSpace::TangentSpace { anchor: new_anchor }
                })
            },
            Expr::StructInit { name, .. } => {
                Ok(CartanType::Struct(name.clone()))
            },
            Expr::Attention { target, .. } => self.visit_expr(target),
            Expr::FunctionCall { name, args } => {
                let mut arg_manifolds = Vec::new();
                for arg in args.iter_mut() {
                    let arg_type = self.visit_expr(arg)?;
                    if let CartanType::Tensor(_, m, _) = arg_type {
                        arg_manifolds.push(Some(m));
                    } else {
                        arg_manifolds.push(None);
                    }
                }
                
                let mut mangled = name.clone();
                for m_opt in arg_manifolds {
                    if let Some(m) = m_opt {
                        mangled.push('_');
                        mangled.push_str(&format!("{:?}", m).to_lowercase());
                    }
                }
                
                if self.functions.contains_key(&mangled) {
                    *name = mangled;
                } else {
                    // Try to mangle based on what's available, or just leave it
                    *name = mangled.clone();
                }
                
                if name.starts_with("ones_like") && args.len() == 1 {
                    return Ok(self.visit_expr(&mut args[0])?);
                }
                
                Ok(CartanType::Unknown)
            },
            Expr::MethodCall { object, method_name, args } => {
                let obj_type = self.visit_expr(object)?;
                for arg in args.iter_mut() {
                    self.visit_expr(arg)?;
                }
                if let CartanType::Stream = obj_type {
                    if method_name == "poll" {
                        return Ok(CartanType::Tensor(vec![Dimension::Fixed(1)], crate::ast::ManifoldSpace::Euclidean, None));
                    }
                }
                Ok(CartanType::Unknown)
            },
            Expr::PropertyAccess { object, property_name: _ } => {
                let _obj_type = self.visit_expr(object)?;
                Ok(CartanType::Unknown) // Real type checking requires looking up the struct fields
            },
            Expr::Placeholder(_) => {
                Ok(CartanType::Unknown)
            },

            Expr::Identifier(name) => {
                if name == "spike" {
                    return Ok(CartanType::Spike);
                } else if name == "neuron" {
                    return Ok(CartanType::Neuron);
                }
                if name == "Cartan" || name == "optimizer" {
                    return Ok(CartanType::Unknown); // Built-in object
                }
                if let Some(t) = self.resolve_var(name) {
                    Ok(t.clone())
                } else {
                    Err(Diagnostic::error(
                        &format!("Undefined identifier '{}'", name),
                        Span::new(0, 0, 0),
                    ))
                }
            },
            Expr::BinaryOp { left, op, right } => {
                let left_type = self.visit_expr(left)?;
                let right_type = self.visit_expr(right)?;

                                if op == "==" || op == "<" || op == ">" || op == "<=" || op == ">=" || op == "!=" {
                    return Ok(CartanType::Boolean);
                }
                
                if op == "@" {
                    let (l_dims, l_space, l_layout) = match &left_type {
                        CartanType::Tensor(d, s, l) => (d, s, l),
                        CartanType::Parameter(d, s, l, _) => (d, s, l),
                        _ => return Err(Diagnostic::error("Matrix multiplication '@' requires tensor operands.", Span::new(0,0,0)))
                    };
                    let (r_dims, _r_space, _r_layout) = match &right_type {
                        CartanType::Tensor(d, s, l) => (d, s, l),
                        CartanType::Parameter(d, s, l, _) => (d, s, l),
                        _ => return Err(Diagnostic::error("Matrix multiplication '@' requires tensor operands.", Span::new(0,0,0)))
                    };

                    if l_dims.len() == 1 && r_dims.len() == 1 {
                        if l_dims[0] != r_dims[0] {
                            return Err(Diagnostic::error(
                                &format!("Shape mismatch in 1D dot product: {} != {}", l_dims[0], r_dims[0]),
                                Span::new(0,0,0)
                            ));
                        }
                        return Ok(CartanType::Float);
                    } else if l_dims.len() == 2 && r_dims.len() == 2 {
                        let l_cols = &l_dims[1];
                        let r_rows = &r_dims[0];
                        if l_cols != r_rows {
                            return Err(Diagnostic::error(
                                &format!("Shape mismatch in matrix multiplication: inner dimensions must match ({} != {})", l_cols, r_rows),
                                Span::new(0,0,0)
                            ));
                        }
                        return Ok(CartanType::Tensor(vec![l_dims[0].clone(), r_dims[1].clone()], l_space.clone(), l_layout.clone()));
                    } else if l_dims.len() == 2 && r_dims.len() == 1 {
                        let l_cols = &l_dims[1];
                        let r_rows = &r_dims[0];
                        if l_cols != r_rows {
                            return Err(Diagnostic::error(
                                &format!("Shape mismatch in matrix-vector multiplication: inner dimensions must match ({} != {})", l_cols, r_rows),
                                Span::new(0,0,0)
                            ));
                        }
                        return Ok(CartanType::Tensor(vec![l_dims[0].clone()], l_space.clone(), l_layout.clone()));
                    } else if l_dims.len() == 1 && r_dims.len() == 2 {
                        let l_cols = &l_dims[0];
                        let r_rows = &r_dims[0];
                        if l_cols != r_rows {
                            return Err(Diagnostic::error(
                                &format!("Shape mismatch in vector-matrix multiplication: inner dimensions must match ({} != {})", l_cols, r_rows),
                                Span::new(0,0,0)
                            ));
                        }
                        return Ok(CartanType::Tensor(vec![r_dims[1].clone()], l_space.clone(), l_layout.clone()));
                    } else {
                        return Err(Diagnostic::error(
                            &format!("Unsupported tensor dimensions for '@': {}D and {}D", l_dims.len(), r_dims.len()),
                            Span::new(0,0,0)
                        ));
                    }
                } else {
                    // Vector math check
                    if let (CartanType::Vector { space: space_l, .. }, CartanType::Vector { space: space_r, .. }) = (&left_type, &right_type) {
                        if space_l != space_r {
                            return Err(Diagnostic::error(
                                "Geometric Misalignment: Cannot perform binary operations between vectors in different vector spaces (e.g., different anchors). Use parallel_transport.",
                                Span::new(0,0,0)
                            ));
                        }
                    }

                    // Standard math (+, -, *, /)
                    // Simplify: assume shape broadcasting or exact match in production
                    Ok(left_type)
                }
            },
            Expr::Integer(_) => Ok(CartanType::Integer),
            Expr::Float(_) => Ok(CartanType::Float),
            Expr::Boolean(_) => Ok(CartanType::Boolean),
            Expr::StringLiteral(_) => Ok(CartanType::String),
            Expr::TreeSearch { tree, algorithm: _, state: _ } => {
                let tree_type = self.visit_expr(tree)?;
                if let CartanType::Tree { .. } = tree_type {
                    // Tree search returns a 1D tensor representing the optimal action or path
                    Ok(CartanType::Tensor(vec![Dimension::Fixed(1)], crate::ast::ManifoldSpace::Euclidean, None))
                } else {
                    Err(Diagnostic::error("search() requires a tree target", Span::new(0,0,0)))
                }
            },
            _ => Ok(CartanType::Unknown),
        }
    }
}
