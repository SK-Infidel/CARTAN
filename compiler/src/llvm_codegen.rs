use crate::ast::{Stmt, Expr};

use std::collections::HashMap;

pub struct LLVMGenerator {
    pub output: String,
    register_count: u32,
    label_count: u32,
    string_counter: usize,
    globals: String,
    symbols: HashMap<String, String>,
    var_types: HashMap<String, String>,
    var_manifolds: HashMap<String, crate::ast::ManifoldSpace>,
    struct_fields: HashMap<String, Vec<String>>,
    func_return_types: HashMap<String, String>,
    loop_labels: Vec<(String, String)>,
    current_return_type: String,
    struct_field_types: HashMap<String, Vec<String>>,
    struct_field_stmts: HashMap<String, Vec<crate::ast::Stmt>>,
    current_struct: Option<String>,
}

impl LLVMGenerator {
    pub fn new() -> Self {
        let mut func_return_types = HashMap::new();
        func_return_types.insert("sys_get_arg".to_string(), "ptr".to_string());
        func_return_types.insert("fopen".to_string(), "ptr".to_string());
        func_return_types.insert("malloc".to_string(), "ptr".to_string());
        func_return_types.insert("cartan_tensor_embed".to_string(), "ptr".to_string());
        
        Self {
            output: String::new(),
            register_count: 1,
            label_count: 1,
            string_counter: 0,
            globals: String::new(),
            symbols: HashMap::new(),
            var_types: HashMap::new(),
            var_manifolds: HashMap::new(),
            struct_fields: HashMap::new(),
            func_return_types,
            loop_labels: Vec::new(),
            current_return_type: "i32".to_string(),
            struct_field_types: HashMap::new(),
            struct_field_stmts: HashMap::new(),
            current_struct: None,
        }
    }

    fn next_reg(&mut self) -> String {
        let reg = format!("%{}", self.register_count);
        self.register_count += 1;
        reg
    }

    fn next_label(&mut self, prefix: &str) -> String {
        let label = format!("{}{}", prefix, self.label_count);
        self.label_count += 1;
        label
    }

    pub fn generate(&mut self, ast: &Vec<Stmt>) -> String {
        // Module header
        self.output.push_str("; ModuleID = 'CartanModule'\n");
        self.output.push_str("source_filename = \"cartan_source\"\n");
        self.output.push_str("target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n");
        self.output.push_str("target triple = \"x86_64-pc-windows-msvc\"\n\n");
        
        // Standard library declarations
        self.globals.push_str("declare ptr @malloc(i64)\n");
        self.globals.push_str("declare void @free(ptr)
declare i32 @strcmp(ptr, ptr)\n");
        
        // Tensor Runtime declarations
        let mut declared_externs = std::collections::HashSet::new();
        if !declared_externs.contains("cartan_tensor_alloc") {
            self.globals.push_str("declare ptr @cartan_tensor_alloc(i32)\n");
        }
        if !declared_externs.contains("cartan_tensor_alloc_nd") {
            self.globals.push_str("declare ptr @cartan_tensor_alloc_nd(i32, i32, i32, i32, i32)\n");
        }
        if !declared_externs.contains("cartan_tensor_add") {
            self.globals.push_str("declare ptr @cartan_tensor_add(ptr, ptr)\n");
        }
        if !declared_externs.contains("cartan_tensor_sub") {
            self.globals.push_str("declare ptr @cartan_tensor_sub(ptr, ptr)\n");
        }
        if !declared_externs.contains("cartan_tensor_mul") {
            self.globals.push_str("declare ptr @cartan_tensor_mul(ptr, ptr)\n");
        }
        if !declared_externs.contains("cartan_tensor_matmul") {
            self.globals.push_str("declare ptr @cartan_tensor_matmul(ptr, ptr)\n");
        }
        if !declared_externs.contains("cartan_tensor_matmul_minkowski") {
            self.globals.push_str("declare ptr @cartan_tensor_matmul_minkowski(ptr, ptr)\n");
        }
        if !declared_externs.contains("cartan_tensor_matmul_poincare") {
            self.globals.push_str("declare ptr @cartan_tensor_matmul_poincare(ptr, ptr)\n");
        }
        if !declared_externs.contains("cartan_tensor_backward") {
            self.globals.push_str("declare void @cartan_tensor_backward(ptr)\n");
        }
        self.globals.push_str("declare void @cartan_tensor_print(ptr)\n");
        self.globals.push_str("declare void @cartan_tensor_step(float)\n");
        self.globals.push_str("declare float @cartan_file_read_tokens(ptr, float, ptr)\n");
        self.globals.push_str("declare float @cartan_net_fetch_tokens(ptr, ptr)\n");
        self.globals.push_str("declare float @cartan_file_read_batch(ptr, ptr, float, ptr)\n");
        self.globals.push_str("declare float @cartan_tensor_mse_loss(ptr, ptr)\n");
        self.globals.push_str("declare float @cartan_tensor_cross_entropy_loss(ptr, ptr)\n");
        self.globals.push_str("declare float @cartan_tensor_spherical_cosine_loss(ptr, ptr)\n");
        self.globals.push_str("declare float @cartan_tensor_finsler_randers_loss(ptr, ptr)\n");
        self.globals.push_str("declare float @cartan_tensor_betti_homology_loss(ptr, ptr)\n");
        self.globals.push_str("declare ptr @cartan_tensor_embed(ptr, ptr)\n");
        
        // Cartan Native VM hooks
        self.globals.push_str("declare void @cartan_emit_spike(float)\n");
        self.globals.push_str("declare ptr @cartan_init_elastic_vocabulary()\n");
        self.globals.push_str("declare ptr @cartan_init_sieving_cache()\n");
        self.globals.push_str("declare ptr @cartan_init_fractal_attention()\n");
        self.globals.push_str("declare ptr @cartan_stream_init(ptr, ptr)\n");
        self.globals.push_str("declare ptr @cartan_init_spike()\n");
        self.globals.push_str("declare ptr @cartan_init_neuron()\n");
        self.globals.push_str("declare ptr @cartan_alloc_parameter_adam(i32)\n");
        self.globals.push_str("declare ptr @cartan_alloc_parameter_adam_nd(i32, i32, i32, i32, i32)\n");
        self.globals.push_str("declare ptr @cartan_alloc_sequence(i32)\n");
        self.globals.push_str("declare ptr @cartan_alloc_block(i32)\n");
        self.globals.push_str("declare void @cartan_absorb_weights(ptr, ptr)\n");
        self.globals.push_str("declare void @cartan_project_vocab(ptr, ptr)\n");
        self.globals.push_str("declare ptr @cartan_tokenize_bpe(ptr, ptr)\n");
        self.globals.push_str("declare void @cartan_align_spans(ptr, ptr, ptr)\n");
        self.globals.push_str("declare void @cartan_free_compute_graph()\n");
        self.globals.push_str("declare void @cartan_fluid_precision_start(ptr, ptr)\n");
        self.globals.push_str("declare void @cartan_fluid_precision_end()\n");
        self.globals.push_str("declare void @cartan_sparsity_start(i32, float)\n");
        self.globals.push_str("declare void @cartan_sparsity_end()\n");
        self.globals.push_str("declare void @cartan_prune_graph(float)\n");


        // Pass 0: Collect structs
        for stmt in ast {
            if let Stmt::StructDecl { name, fields } = stmt {
                let mut field_names = Vec::new();
                let mut field_types = Vec::new();
                let mut field_stmts = Vec::new();
                for field in fields {
                    match field {
                        Stmt::VarDecl { name: field_name, value, .. } => {
                            field_names.push(field_name.clone());
                            let type_str = if let Expr::FunctionCall { name: struct_name, .. } = value {
                                if struct_name.chars().next().unwrap_or(' ').is_uppercase() {
                                    format!("%{}", struct_name)
                                } else { "float".to_string() }
                            } else { "float".to_string() };
                            field_types.push(type_str);
                            field_stmts.push(field.clone());
                        },
                        Stmt::TensorDecl { name: field_name, .. } | Stmt::ParameterDecl { name: field_name, .. } => {
                            field_names.push(field_name.clone());
                            field_types.push("ptr".to_string());
                            field_stmts.push(field.clone());
                        },
                        _ => {}
                    }
                }
                let count = field_names.len();
                self.struct_fields.insert(name.clone(), field_names);
                self.struct_field_types.insert(name.clone(), field_types.clone());
                self.struct_field_stmts.insert(name.clone(), field_stmts);
                self.output.push_str(&format!("%{} = type {{ ", name));
                for i in 0..count {
                    if i > 0 { self.output.push_str(", "); }
                    let t = field_types.get(i).map(|s| s.as_str()).unwrap_or("float");
                    self.output.push_str(t);
                }
                self.output.push_str(" }\n");
            }
        }
        self.output.push_str("\n");

        // Pass 1: Collect globals and declare extern functions
        for stmt in ast {
            match stmt {
                Stmt::ExternFunctionDecl(decl) => {
                    if declared_externs.contains(&decl.name) {
                        continue;
                    }
                    declared_externs.insert(decl.name.clone());
                    let mut param_types = Vec::new();
                    for p in &decl.parameters {
                        let p_type = if p.type_name == "i32" || p.type_name == "int" { "i32" } else if p.type_name == "float" || p.type_name == "f32" { "float" } else { "ptr" };
                        param_types.push(p_type.to_string());
                    }
                    let ret_type = if let Some(rt) = &decl.return_type {
                        if rt == "i32" || rt == "int" { "i32" } else if rt == "float" || rt == "f32" { "float" } else { "ptr" }
                    } else { "void" };
                    let mut params = param_types.join(", ");
                    if decl.name == "printf" {
                        if params.is_empty() { params = "...".to_string(); }
                        else { params = format!("{}, ...", params); }
                    }
                    if decl.name == "malloc" { params = "i64".to_string(); }
                    if decl.name == "free" { params = "ptr".to_string(); }
                    self.func_return_types.insert(decl.name.clone(), ret_type.to_string());
                    self.output.push_str(&format!("declare {} @{}({})\n", ret_type, decl.name, params));
                    self.symbols.insert(decl.name.clone(), format!("@{}", decl.name));
                    self.func_return_types.insert(decl.name.clone(), ret_type.to_string());
                },
                Stmt::VarDecl { name, is_const, value } if *is_const => {
                    if let crate::ast::Expr::ArrayDecl { elements } = value {
                        let mut float_vals = Vec::new();
                        for el in elements {
                            if let crate::ast::Expr::Float(f) = el {
                                float_vals.push(format!("float {:.6e}", f));
                            } else if let crate::ast::Expr::Integer(i) = el {
                                float_vals.push(format!("float {:.6e}", *i as f64));
                            } else {
                                float_vals.push("float 0.000000e+00".to_string());
                            }
                        }
                        let arr_content = float_vals.join(", ");
                        self.globals.push_str(&format!("@{} = dso_local constant [{} x float] [{}], align 4\n", name, elements.len(), arr_content));
                        self.symbols.insert(name.clone(), format!("@{}", name));
                        self.var_types.insert(name.clone(), "ptr".to_string());
                    } else if let crate::ast::Expr::Float(f) = value {
                        self.globals.push_str(&format!("@{} = dso_local constant float {:.6e}, align 4\n", name, f));
                        self.symbols.insert(name.clone(), format!("@{}", name));
                        self.var_types.insert(name.clone(), "float".to_string());
                    } else if let crate::ast::Expr::Integer(i) = value {
                        self.globals.push_str(&format!("@{} = dso_local constant float {:.6e}, align 4\n", name, *i as f64));
                        self.symbols.insert(name.clone(), format!("@{}", name));
                        self.var_types.insert(name.clone(), "float".to_string());
                    }
                },
                _ => {}
            }
        }
        self.output.push_str("\n");

        // Pass 2: Process User-Defined Functions
        let mut all_funcs = Vec::new();
        for stmt in ast {
            if let Stmt::FunctionDecl(decl) = stmt {
                all_funcs.push((None, decl));
            } else if let Stmt::StructDecl { name, fields } = stmt {
                for field in fields {
                    if let Stmt::FunctionDecl(decl) = field {
                        all_funcs.push((Some(name.clone()), decl));
                    }
                }
            }
        }

        for (struct_name, decl) in all_funcs {
            self.current_struct = struct_name.clone();
            let saved_symbols = self.symbols.clone();
            let saved_types = self.var_types.clone();
            
            let mut param_types = Vec::new();
            if let Some(sname) = &struct_name {
                param_types.push(format!("%{} %arg_this", sname));
            }
            
            for p in &decl.parameters {
                let p_type = if p.type_name == "i32" || p.type_name == "int" { "i32" } else if p.type_name == "float" || p.type_name == "f32" { "float" } else { "ptr" };
                param_types.push(format!("{} %arg_{}", p_type, p.name));
            }
            
            let ret_type = if let Some(rt) = &decl.return_type {
                if rt == "i32" || rt == "int" { "i32" } else if rt == "float" || rt == "f32" { "float" } else { "ptr" }
            } else { "void" };
            let params = param_types.join(", ");
            let safe_name = if decl.name == "main" { "user_main".to_string() } else if let Some(sname) = &struct_name { format!("{}_{}", sname, decl.name) } else { decl.name.clone() };
            self.func_return_types.insert(safe_name.clone(), ret_type.to_string());
            
            let mut attrs = String::new();
            if decl.is_agent_accessible {
                attrs.push_str("dso_local dllexport ");
            }
            
            self.output.push_str(&format!("define {}{} @{}({}) {{\n", attrs, ret_type, safe_name, params));
            self.output.push_str("entry:\n");

            if let Some(sname) = &struct_name {
                let alloc_ptr = self.next_reg();
                self.output.push_str(&format!("  {} = alloca %{}, align 8\n", alloc_ptr, sname));
                self.output.push_str(&format!("  store %{} %arg_this, ptr {}, align 8\n", sname, alloc_ptr));
                self.symbols.insert("this".to_string(), alloc_ptr);
                self.var_types.insert("this".to_string(), format!("%{}", sname));
            }

            for p in &decl.parameters {
                let p_type = if p.type_name == "i32" || p.type_name == "int" { "i32" } else if p.type_name == "float" || p.type_name == "f32" { "float" } else { "ptr" };
                let alloc_ptr = self.next_reg();
                self.output.push_str(&format!("  {} = alloca {}, align 4\n", alloc_ptr, p_type));
                self.output.push_str(&format!("  store {} %arg_{}, ptr {}, align 4\n", p_type, p.name, alloc_ptr));
                self.symbols.insert(p.name.clone(), alloc_ptr);
                self.var_types.insert(p.name.clone(), p_type.to_string());
            }

            self.current_return_type = ret_type.to_string();
            self.visit_stmt(&Stmt::Block(decl.body.clone()));
            self.current_return_type = "i32".to_string();
            
            // Add default return if needed
            if ret_type == "void" {
                self.output.push_str("  ret void\n");
            } else if ret_type == "float" {
                self.output.push_str("  ret float 0.0\n");
            } else if ret_type == "i32" {
                self.output.push_str("  ret i32 0\n");
            } else {
                self.output.push_str(&format!("  ret {} null\n", ret_type));
            }
            
            self.output.push_str("}\n\n");
            self.symbols = saved_symbols;
            self.var_types = saved_types;
        }

        // Pass 3: Main logic
        self.globals.push_str("@global_argc = global i32 0, align 4\n");
        self.globals.push_str("@global_argv = global ptr null, align 8\n\n");
        self.globals.push_str("define ptr @sys_get_arg(float %index) {\n");
        self.globals.push_str("entry:\n");
        self.globals.push_str("  %int_idx = fptosi float %index to i32\n");
        self.globals.push_str("  %argv_base = load ptr, ptr @global_argv, align 8\n");
        self.globals.push_str("  %arg_ptr = getelementptr inbounds ptr, ptr %argv_base, i32 %int_idx\n");
        self.globals.push_str("  %arg_str = load ptr, ptr %arg_ptr, align 8\n");
        self.globals.push_str("  ret ptr %arg_str\n");
        self.globals.push_str("}\n\n");
        
        let mut has_main = false;
        for stmt in ast {
            if let Stmt::FunctionDecl(decl) = stmt {
                if decl.name == "main" {
                    has_main = true;
                }
            }
        }
        
        self.output.push_str("define i32 @main(i32 %argc, ptr %argv) {\n");
        self.output.push_str("entry:\n");
        self.output.push_str("  store i32 %argc, ptr @global_argc, align 4\n");
        self.output.push_str("  store ptr %argv, ptr @global_argv, align 8\n");

        for stmt in ast {
            let mut skip = false;
            match stmt {
                Stmt::ExternFunctionDecl(_) | Stmt::FunctionDecl(_) => skip = true,
                Stmt::VarDecl { is_const: true, .. } => skip = true,
                _ => {}
            }
            if !skip {
                self.visit_stmt(stmt);
            }
        }

        if has_main {
            self.output.push_str("  %exit_code = call i32 @user_main()\n");
            self.output.push_str("  ret i32 %exit_code\n");
        } else {
            self.output.push_str("  ret i32 0\n");
        }
        self.output.push_str("}\n\n");

        // Append globals
        self.output.push_str(&self.globals);

        self.output.clone()
    }

    fn visit_stmt(&mut self, stmt: &Stmt) {
        match stmt {
            Stmt::Match { condition, arms } => {
                let cond_reg = self.visit_expr(condition).unwrap_or("0.0".to_string());
                let is_cond_ptr = cond_reg.starts_with("ptr:") || cond_reg.starts_with("string:");
                let clean_cond = cond_reg.split(':').last().unwrap_or(&cond_reg).to_string();
                
                let end_label = self.next_label("match_end_");
                
                for (pattern_opt, body) in arms {
                    let arm_label = self.next_label("match_arm_");
                    let next_label = self.next_label("match_next_");
                    
                    if let Some(pattern) = pattern_opt {
                        let pat_reg = self.visit_expr(pattern).unwrap_or("0.0".to_string());
                        let is_pat_ptr = pat_reg.starts_with("ptr:") || pat_reg.starts_with("string:");
                        let clean_pat = pat_reg.split(':').last().unwrap_or(&pat_reg).to_string();
                        
                          if is_cond_ptr && is_pat_ptr {
                              let cmp_res = self.next_reg();
                              self.output.push_str(&format!("  {} = call i32 @strcmp(ptr {}, ptr {})\n", cmp_res, clean_cond, clean_pat));
                              let cond_bool = self.next_reg();
                              self.output.push_str(&format!("  {} = icmp eq i32 {}, 0\n", cond_bool, cmp_res));
                              self.output.push_str(&format!("  br i1 {}, label %{}, label %{}\n", cond_bool, arm_label, next_label));
                          } else {
                              // Float comparison
                              let cond_f = if is_cond_ptr {
                                  let t1 = self.next_reg();
                                  let t2 = self.next_reg();
                                  self.output.push_str(&format!("  {} = ptrtoint ptr {} to i64\n", t1, clean_cond));
                                  self.output.push_str(&format!("  {} = sitofp i64 {} to float\n", t2, t1));
                                  t2
                              } else { clean_cond.clone() };
                              
                              let pat_f = if is_pat_ptr {
                                  let t1 = self.next_reg();
                                  let t2 = self.next_reg();
                                  self.output.push_str(&format!("  {} = ptrtoint ptr {} to i64\n", t1, clean_pat));
                                  self.output.push_str(&format!("  {} = sitofp i64 {} to float\n", t2, t1));
                                  t2
                              } else { clean_pat.clone() };
                              
                              let cond_bool = self.next_reg();
                              self.output.push_str(&format!("  {} = fcmp oeq float {}, {}\n", cond_bool, cond_f, pat_f));
                              self.output.push_str(&format!("  br i1 {}, label %{}, label %{}\n", cond_bool, arm_label, next_label));
                          }
                    } else {
                        // Wildcard fallback
                        self.output.push_str(&format!("  br label %{}\n", arm_label));
                    }
                    
                    self.output.push_str(&format!("{}:\n", arm_label));
                    self.visit_stmt(body);
                    self.output.push_str(&format!("  br label %{}\n", end_label));
                    
                    self.output.push_str(&format!("{}:\n", next_label));
                }
                
                self.output.push_str(&format!("  br label %{}\n", end_label));
                self.output.push_str(&format!("{}:\n", end_label));
            },
            Stmt::If { condition, true_block, false_block } => {
                let cond_reg = self.visit_expr(condition).unwrap_or("0.0".to_string());
                let cond_bool = self.next_reg();
                self.output.push_str(&format!("  {} = fcmp one float {}, 0.0\n", cond_bool, cond_reg));
                
                let then_label = self.next_label("then_");
                let else_label = self.next_label("else_");
                let end_label = self.next_label("end_");

                if false_block.is_some() {
                    self.output.push_str(&format!("  br i1 {}, label %{}, label %{}\n", cond_bool, then_label, else_label));
                } else {
                    self.output.push_str(&format!("  br i1 {}, label %{}, label %{}\n", cond_bool, then_label, end_label));
                }

                self.output.push_str(&format!("{}:\n", then_label));
                for s in &true_block.statements { self.visit_stmt(s); }
                self.output.push_str(&format!("  br label %{}\n", end_label));

                if let Some(f_block) = false_block {
                    self.output.push_str(&format!("{}:\n", else_label));
                    for s in &f_block.statements { self.visit_stmt(s); }
                    self.output.push_str(&format!("  br label %{}\n", end_label));
                }

                self.output.push_str(&format!("{}:\n", end_label));
            },
            Stmt::While { condition, body } => {
                let cond_label = self.next_label("while_cond_");
                let body_label = self.next_label("while_body_");
                let end_label = self.next_label("while_end_");

                self.output.push_str(&format!("  br label %{}\n", cond_label));
                self.output.push_str(&format!("{}:\n", cond_label));

                let cond_reg = self.visit_expr(condition).unwrap_or("0.0".to_string());
                let cond_bool = self.next_reg();
                self.output.push_str(&format!("  {} = fcmp one float {}, 0.0\n", cond_bool, cond_reg));
                
                self.output.push_str(&format!("  br i1 {}, label %{}, label %{}\n", cond_bool, body_label, end_label));

                self.output.push_str(&format!("{}:\n", body_label));
                self.loop_labels.push((cond_label.clone(), end_label.clone()));
                for s in &body.statements { self.visit_stmt(s); }
                self.loop_labels.pop();
                self.output.push_str(&format!("  br label %{}\n", cond_label));

                self.output.push_str(&format!("{}:\n", end_label));
            },
            Stmt::Return { value } => {
                if let Some(expr) = value {
                    let ret_val = self.visit_expr(expr).unwrap_or("0.0".to_string());
                    if self.current_return_type == "i32" {
                        let int_val = self.next_reg();
                        self.output.push_str(&format!("  {} = fptosi float {} to i32\n", int_val, ret_val));
                        self.output.push_str(&format!("  ret i32 {}\n", int_val));
                    } else if self.current_return_type == "float" {
                        self.output.push_str(&format!("  ret float {}\n", ret_val));
                    } else if self.current_return_type == "ptr" {
                        if ret_val.starts_with("ptr:") {
                            self.output.push_str(&format!("  ret ptr {}\n", ret_val.replace("ptr:", "")));
                        } else {
                            let int_val = self.next_reg();
                            let ptr_val = self.next_reg();
                            self.output.push_str(&format!("  {} = fptoui float {} to i64\n", int_val, ret_val));
                            self.output.push_str(&format!("  {} = inttoptr i64 {} to ptr\n", ptr_val, int_val));
                            self.output.push_str(&format!("  ret ptr {}\n", ptr_val));
                        }
                    } else if self.current_return_type == "void" {
                          self.output.push_str("  ret void\n");
                      } else {
                          self.output.push_str(&format!("  ret {} {}\n", self.current_return_type, ret_val));
                      }
                } else {
                    if self.current_return_type == "i32" {
                        self.output.push_str("  ret i32 0\n");
                    } else if self.current_return_type == "float" {
                        self.output.push_str("  ret float 0.0\n");
                    } else if self.current_return_type == "void" {
                        self.output.push_str("  ret void\n");
                    } else {
                        self.output.push_str(&format!("  ret {} null\n", self.current_return_type));
                    }
                }
                let unreachable = self.next_label("unreachable_");
                self.output.push_str(&format!("{}:\n", unreachable));
            },
            Stmt::StructDecl { name: _, fields: _ } => {
                // Handled in Pass 0
            },
            Stmt::VarDecl { name, is_const: _, value } => {
                let val_reg = self.visit_expr(value).unwrap_or("0.0".to_string());
                
                if val_reg.starts_with("struct:") {
                    let parts: Vec<&str> = val_reg.split(':').collect();
                    let struct_name = parts[1];
                    let real_reg = parts[2];
                    self.var_types.insert(name.clone(), format!("%{}", struct_name));
                    self.symbols.insert(name.clone(), real_reg.to_string());
                } else if val_reg.starts_with("array:") {
                    let raw_ptr = val_reg.replace("array:", "");
                    let ptr_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = alloca ptr, align 8\n", ptr_reg));
                    self.output.push_str(&format!("  store ptr {}, ptr {}, align 8\n", raw_ptr, ptr_reg));
                    self.symbols.insert(name.clone(), ptr_reg);
                    self.var_types.insert(name.clone(), "ptr".to_string());
                } else if val_reg.starts_with("string:") {
                    self.symbols.insert(name.clone(), val_reg.replace("string:", ""));
                } else if val_reg.starts_with("ptr:") {
                    let raw_ptr = val_reg.replace("ptr:", "");
                    let ptr_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = alloca ptr, align 8\n", ptr_reg));
                    self.output.push_str(&format!("  store ptr {}, ptr {}, align 8\n", raw_ptr, ptr_reg));
                    self.symbols.insert(name.clone(), ptr_reg);
                    self.var_types.insert(name.clone(), "ptr".to_string());
                } else {
                    let ptr_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = alloca float, align 4\n", ptr_reg));
                    self.output.push_str(&format!("  store float {}, ptr {}, align 4\n", val_reg, ptr_reg));
                    self.symbols.insert(name.clone(), ptr_reg);
                }
            },
            Stmt::Expr(expr) => {
                self.visit_expr(expr);
            },
            Stmt::TensorDecl { name, shape, manifold: _, location: _, backend: _, layout: _ } => {
                  let res_reg = self.next_reg();
                  if shape.len() > 1 && shape.len() <= 4 {
                      let mut dims = [1; 4];
                      for (idx, dim) in shape.iter().enumerate() {
                          if let Expr::Integer(val) = dim {
                              dims[idx] = *val as i32;
                          }
                      }
                      self.output.push_str(&format!(
                          "  {} = call ptr @cartan_tensor_alloc_nd(i32 {}, i32 {}, i32 {}, i32 {}, i32 {})\n",
                          res_reg, shape.len(), dims[0], dims[1], dims[2], dims[3]
                      ));
                  } else {
                      let mut num_elems = 1;
                      for dim in shape {
                          if let Expr::Integer(val) = dim {
                              num_elems *= *val as i32;
                          }
                      }
                      self.output.push_str(&format!("  {} = call ptr @cartan_tensor_alloc(i32 {})\n", res_reg, num_elems));
                  }
                  
                  let ptr_reg = self.next_reg();
                  self.output.push_str(&format!("  {} = alloca ptr, align 8\n", ptr_reg));
                  self.output.push_str(&format!("  store ptr {}, ptr {}, align 8\n", res_reg, ptr_reg));
                  self.symbols.insert(name.clone(), ptr_reg);
                  self.var_types.insert(name.clone(), "ptr".to_string());
              },
            Stmt::SequenceDecl { name, max_len } => {
                let mut size = 1;
                if let Expr::Integer(val) = max_len { size = *val as i32; }
                let res_reg = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_alloc_sequence(i32 {})\n", res_reg, size));
                let ptr_reg = self.next_reg();
                self.output.push_str(&format!("  {} = alloca ptr, align 8\n", ptr_reg));
                self.output.push_str(&format!("  store ptr {}, ptr {}, align 8\n", res_reg, ptr_reg));
                self.symbols.insert(name.clone(), ptr_reg);
                self.var_types.insert(name.clone(), "ptr".to_string());
            },
            Stmt::BlockDecl { name, size: block_size } => {
                let mut size = 1;
                if let Expr::Integer(val) = block_size { size = *val as i32; }
                let res_reg = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_alloc_block(i32 {})\n", res_reg, size));
                let ptr_reg = self.next_reg();
                self.output.push_str(&format!("  {} = alloca ptr, align 8\n", ptr_reg));
                self.output.push_str(&format!("  store ptr {}, ptr {}, align 8\n", res_reg, ptr_reg));
                self.symbols.insert(name.clone(), ptr_reg);
                self.var_types.insert(name.clone(), "ptr".to_string());
            },
            Stmt::ParameterDecl { name, shape, manifold, location: _, backend: _, layout: _, optimizer } => {
                let mut alloc_fn = "cartan_tensor_alloc";
                let mut alloc_nd_fn = "cartan_tensor_alloc_nd";
                if let Some(crate::ast::OptimizerState::Adam) = optimizer {
                    alloc_fn = "cartan_alloc_parameter_adam";
                    alloc_nd_fn = "cartan_alloc_parameter_adam_nd";
                }
                
                let res_reg = self.next_reg();
                if shape.len() > 1 && shape.len() <= 4 {
                    let mut dims = [1; 4];
                    for (i, dim) in shape.iter().enumerate() {
                        if let Expr::Integer(val) = dim {
                            dims[i] = *val as i32;
                        }
                    }
                    self.output.push_str(&format!(
                        "  {} = call ptr @{}(i32 {}, i32 {}, i32 {}, i32 {}, i32 {})\n",
                        res_reg, alloc_nd_fn, shape.len(), dims[0], dims[1], dims[2], dims[3]
                    ));
                } else {
                    let mut num_elems = 1;
                    for dim in shape {
                        if let Expr::Integer(val) = dim {
                            num_elems *= *val as i32;
                        }
                    }
                    self.output.push_str(&format!("  {} = call ptr @{}(i32 {})\n", res_reg, alloc_fn, num_elems));
                }
                
                let ptr_reg = self.next_reg();
                self.output.push_str(&format!("  {} = alloca ptr, align 8\n", ptr_reg));
                self.output.push_str(&format!("  store ptr {}, ptr {}, align 8\n", res_reg, ptr_reg));
                self.symbols.insert(name.clone(), ptr_reg);
                self.var_types.insert(name.clone(), "ptr".to_string());
                self.var_manifolds.insert(name.clone(), manifold.clone());
            },
            Stmt::AbsorbWeights { donor_path, local_tensor } => {
                let id = self.string_counter;
                self.string_counter += 1;
                let clean_s = donor_path.replace("\\n", "\n");
                let mut bytes = Vec::new();
                for b in clean_s.as_bytes() {
                    bytes.push(format!("\\{:02x}", b));
                }
                bytes.push("\\00".to_string());
                let byte_str = bytes.join("");
                let len = clean_s.as_bytes().len() + 1;
                self.globals.push_str(&format!("@.str.{} = private unnamed_addr constant [{} x i8] c\"{}\", align 1\n", id, len, byte_str));
                let path_str_ptr = format!("ptr @.str.{}", id);
                
                if let Some(tensor_ptr) = self.symbols.get(local_tensor).cloned() {
                    let val_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = load ptr, ptr {}, align 8\n", val_reg, tensor_ptr));
                    self.output.push_str(&format!("  call void @cartan_absorb_weights({} {}, ptr {})\n", path_str_ptr.split_whitespace().next().unwrap(), path_str_ptr.split_whitespace().last().unwrap(), val_reg));
                }
            },
            Stmt::ProjectVocab { source_tensor, target_vocab } => {
                if let (Some(src_ptr), Some(tgt_ptr)) = (self.symbols.get(source_tensor).cloned(), self.symbols.get(target_vocab).cloned()) {
                    let val_src = self.next_reg();
                    let val_tgt = self.next_reg();
                    self.output.push_str(&format!("  {} = load ptr, ptr {}, align 8\n", val_src, src_ptr));
                    self.output.push_str(&format!("  {} = load ptr, ptr {}, align 8\n", val_tgt, tgt_ptr));
                    self.output.push_str(&format!("  call void @cartan_project_vocab(ptr {}, ptr {})\n", val_src, val_tgt));
                }
            },
            Stmt::TryCatch { try_block, catch_var: _, catch_block: _ } => {
                for stmt in &try_block.statements {
                    self.visit_stmt(stmt);
                }
            },
            Stmt::AsyncCompute(block) => {
                self.output.push_str("  ; Begin Async Compute Block\n");
                for stmt in &block.statements {
                    self.visit_stmt(stmt);
                }
                self.output.push_str("  ; End Async Compute Block\n");
            },
            Stmt::Backward(expr) => {
                self.output.push_str("  ; --- Begin Backward Pass ---\n");
                let loss_reg = self.visit_expr(expr).unwrap_or("%0".to_string());
                if loss_reg.starts_with("ptr:") || loss_reg.starts_with("array:") || loss_reg.starts_with("struct:") {
                    let clean = loss_reg.split(':').last().unwrap_or(&loss_reg);
                    self.output.push_str(&format!("  call void @cartan_tensor_backward(ptr {})\n", clean));
                    self.output.push_str("  call void @cartan_tensor_step(float 0x3F847AE140000000)\n");
                    self.output.push_str("  call void @cartan_free_compute_graph()\n");
                }
                self.output.push_str("  ; --- End Backward Pass ---\n");
            },
            Stmt::FluidPrecisionBlock { primary_type, fallback_type, block } => {
                self.output.push_str(&format!("  ; --- Fluid Precision: primary={}, fallback={} ---\n", primary_type, fallback_type));
                self.output.push_str("  call void @cartan_fluid_precision_start(ptr null, ptr null)\n");
                for stmt in &block.statements {
                    self.visit_stmt(stmt);
                }
                self.output.push_str("  call void @cartan_fluid_precision_end()\n");
            },
            Stmt::SparsityBlock { block_size, density, block } => {
                self.output.push_str("  ; --- Sparsity Block ---\n");
                let bs_float_reg = self.visit_expr(block_size).unwrap_or("%0".to_string());
                let bs_int_reg = self.next_reg();
                self.output.push_str(&format!("  {} = fptosi float {} to i32\n", bs_int_reg, bs_float_reg));
                let den_reg = self.visit_expr(density).unwrap_or("%0".to_string());
                self.output.push_str(&format!("  call void @cartan_sparsity_start(i32 {}, float {})\n", bs_int_reg, den_reg));
                for stmt in &block.statements {
                    self.visit_stmt(stmt);
                }
                self.output.push_str("  call void @cartan_sparsity_end()\n");
            },
            Stmt::PruneGraph(expr) => {
                self.output.push_str("  ; --- Prune Graph ---\n");
                let thr_reg = self.visit_expr(expr).unwrap_or("%0".to_string());
                self.output.push_str(&format!("  call void @cartan_prune_graph(float {})\n", thr_reg));
            },
            Stmt::EmitSpike { intensity } => {
                self.output.push_str("  ; --- Emit Spike ---\n");
                let int_reg = self.visit_expr(intensity).unwrap_or("%0".to_string());
                self.output.push_str(&format!("  call void @cartan_emit_spike(float {})\n", int_reg));
            },
            Stmt::FunctionDecl(_) => {
                // Handled in a separate pass
            },
            Stmt::ExternFunctionDecl(_) => {
                // Handled in Pass 1
            },
            Stmt::Block(block) => {
                for stmt in &block.statements {
                    self.visit_stmt(stmt);
                }
            },
            Stmt::Break => {
                if let Some((_, end_label)) = self.loop_labels.last() {
                    self.output.push_str(&format!("  br label %{}\n", end_label));
                    let unreachable = self.next_label("unreachable_");
                    self.output.push_str(&format!("{}:\n", unreachable));
                }
            },
            Stmt::Continue => {
                if let Some((cond_label, _)) = self.loop_labels.last() {
                    self.output.push_str(&format!("  br label %{}\n", cond_label));
                    let unreachable = self.next_label("unreachable_");
                    self.output.push_str(&format!("{}:\n", unreachable));
                }
            },
            _ => {}
        }
    }

    fn visit_expr(&mut self, expr: &Expr) -> Option<String> {
        match expr {
            Expr::Identifier(name) => {
                if let Some(ptr_reg) = self.symbols.get(name).cloned() {
                    let val_reg = self.next_reg();
                    let t = self.var_types.get(name).cloned().unwrap_or("float".to_string());
                    if t.starts_with("%") {
                        Some(format!("struct:{}:{}", t.replace("%", ""), ptr_reg))
                    } else if t == "ptr" || t == "string" {
                        self.output.push_str(&format!("  {} = load ptr, ptr {}, align 8\n", val_reg, ptr_reg));
                        Some(format!("{}:{}", t, val_reg))
                    } else {
                        self.output.push_str(&format!("  {} = load {}, ptr {}, align 4\n", val_reg, t, ptr_reg));
                        Some(val_reg)
                    }
                } else if let Some(curr_struct) = &self.current_struct {
                    let mut is_field = false;
                    if let Some(fields) = self.struct_fields.get(curr_struct) {
                        if fields.contains(name) {
                            is_field = true;
                        }
                    }
                    if is_field {
                        return self.visit_expr(&Expr::PropertyAccess {
                            object: Box::new(Expr::Identifier("this".to_string())),
                            property_name: name.clone(),
                        });
                    }
                    Some("0.0".to_string())
                } else {
                    Some("0.0".to_string())
                }
            },
            Expr::ArrayDecl { elements } => {
                let len = elements.len();
                let array_ptr = self.next_reg();
                self.output.push_str(&format!("  {} = alloca [{} x float], align 4\n", array_ptr, len));
                
                for (i, el) in elements.iter().enumerate() {
                    let val_reg = self.visit_expr(el).unwrap_or("0.0".to_string());
                    let elem_ptr = self.next_reg();
                    self.output.push_str(&format!("  {} = getelementptr inbounds [{} x float], ptr {}, i32 0, i32 {}\n", elem_ptr, len, array_ptr, i));
                    self.output.push_str(&format!("  store float {}, ptr {}, align 4\n", val_reg, elem_ptr));
                }
                
                Some(format!("array:{}", array_ptr)) // marker
            },
            Expr::IndexAccess { object, index } => {
                let obj_reg = self.visit_expr(object).unwrap().replace("ptr:", "").replace("string:", "");
                let idx_reg = self.visit_expr(index).unwrap();

                let int_idx = self.next_reg();
                self.output.push_str(&format!("  {} = fptosi float {} to i32\n", int_idx, idx_reg));

                // Check variable type from object identifier if applicable
                let mut is_string = false;
                let mut is_raw_ptr = false;
                if let Expr::Identifier(name) = &**object {
                    if let Some(t) = self.var_types.get(name) {
                        if t == "string" { is_string = true; }
                        else if t == "ptr" { is_raw_ptr = true; }
                    }
                }
                
                let elem_ptr = self.next_reg();
                if is_string {
                    self.output.push_str(&format!("  {} = getelementptr inbounds i8, ptr {}, i32 {}\n", elem_ptr, obj_reg, int_idx));
                    let char_val = self.next_reg();
                    self.output.push_str(&format!("  {} = load i8, ptr {}, align 1\n", char_val, elem_ptr));
                    let val_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = uitofp i8 {} to float\n", val_reg, char_val));
                    Some(val_reg)
                } else if is_raw_ptr {
                    self.output.push_str(&format!("  {} = getelementptr inbounds float, ptr {}, i32 {}\n", elem_ptr, obj_reg, int_idx));
                    let val_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = load float, ptr {}, align 4\n", val_reg, elem_ptr));
                    Some(val_reg)
                } else {
                    self.output.push_str(&format!("  {} = getelementptr inbounds [100 x float], ptr {}, i32 0, i32 {}\n", elem_ptr, obj_reg, int_idx));
                    let val_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = load float, ptr {}, align 4\n", val_reg, elem_ptr));
                    Some(val_reg)
                }
            },
            Expr::PropertyAccess { object, property_name } => {
                let obj_reg = match &**object {
                    Expr::Identifier(name) => self.symbols.get(name).cloned().unwrap_or("null".to_string()),
                    _ => self.visit_expr(object).unwrap_or("null".to_string()),
                };
                let struct_type = match &**object {
                    Expr::Identifier(name) => self.var_types.get(name).cloned().unwrap_or("%StructName".to_string()),
                    _ => {
                        if obj_reg.starts_with("struct:") {
                            format!("%{}", obj_reg.split(':').nth(1).unwrap_or("StructName"))
                        } else {
                            "%StructName".to_string()
                        }
                    }
                };
                let struct_name = struct_type.replace("%", "");
                let field_idx = if let Some(fields) = self.struct_fields.get(&struct_name) {
                    fields.iter().position(|r| r == property_name).unwrap_or(0)
                } else {
                    0
                };
                let field_type = if let Some(types) = self.struct_field_types.get(&struct_name) {
                    types.get(field_idx).cloned().unwrap_or("float".to_string())
                } else {
                    "float".to_string()
                };
                
                let elem_ptr = self.next_reg();
                let mut clean_obj_reg = obj_reg.clone();
                if clean_obj_reg.starts_with("struct:") {
                    clean_obj_reg = clean_obj_reg.split(':').last().unwrap_or(&clean_obj_reg).to_string();
                }
                self.output.push_str(&format!("  {} = getelementptr inbounds {}, ptr {}, i32 0, i32 {}\n", elem_ptr, struct_type, clean_obj_reg, field_idx));
                let val_reg = self.next_reg();
                if field_type == "ptr" {
                    self.output.push_str(&format!("  {} = load ptr, ptr {}, align 8\n", val_reg, elem_ptr));
                    Some(format!("ptr:{}", val_reg))
                } else if field_type.starts_with("%") {
                    Some(format!("struct:{}:{}", field_type.replace("%", ""), elem_ptr))
                } else {
                    self.output.push_str(&format!("  {} = load float, ptr {}, align 4\n", val_reg, elem_ptr));
                    Some(val_reg)
                }
            },
            Expr::Assignment { target, value } => {
                let val_reg = self.visit_expr(value).unwrap_or("0.0".to_string());
                match &**target {
                    Expr::Identifier(name) => {
                        if let Some(ptr_reg) = self.symbols.get(name) {
                            if val_reg.starts_with("ptr:") {
                                self.output.push_str(&format!("  store ptr {}, ptr {}, align 8\n", val_reg.replace("ptr:", ""), ptr_reg));
                            } else {
                                self.output.push_str(&format!("  store float {}, ptr {}, align 4\n", val_reg, ptr_reg));
                            }
                        }
                    },
                    Expr::IndexAccess { object, index } => {
                        let obj_reg = match &**object {
                            Expr::Identifier(name) => {
                                let ptr = self.symbols.get(name).cloned().unwrap_or("null".to_string());
                                let t_opt = self.var_types.get(name).map(|s| s.as_str());
                                if t_opt == Some("ptr") || t_opt == Some("string") {
                                    let loaded_ptr = self.next_reg();
                                    self.output.push_str(&format!("  {} = load ptr, ptr {}, align 8\n", loaded_ptr, ptr));
                                    loaded_ptr
                                } else {
                                    ptr
                                }
                            },
                            _ => self.visit_expr(object).unwrap_or("null".to_string()).replace("ptr:", ""),
                        };
                        let idx_reg = self.visit_expr(index).unwrap_or("0.0".to_string());
                        let int_idx = self.next_reg();
                        self.output.push_str(&format!("  {} = fptosi float {} to i32\n", int_idx, idx_reg));
                        let elem_ptr = self.next_reg();
                        
                        let is_raw_ptr = match &**object {
                            Expr::Identifier(name) => self.var_types.get(name).map(|s| s.as_str()) == Some("ptr"),
                            _ => false,
                        };
                        
                        if is_raw_ptr {
                            self.output.push_str(&format!("  {} = getelementptr inbounds float, ptr {}, i32 {}\n", elem_ptr, obj_reg, int_idx));
                        } else {
                            self.output.push_str(&format!("  {} = getelementptr inbounds [10 x float], ptr {}, i32 0, i32 {}\n", elem_ptr, obj_reg, int_idx));
                        }
                        
                        self.output.push_str(&format!("  store float {}, ptr {}, align 4\n", val_reg, elem_ptr));
                    },
                    Expr::PropertyAccess { object, property_name } => {
                        let obj_reg = match &**object {
                            Expr::Identifier(name) => self.symbols.get(name).cloned().unwrap_or("null".to_string()),
                            _ => self.visit_expr(object).unwrap_or("null".to_string()),
                        };
                        let struct_type = match &**object {
                            Expr::Identifier(name) => self.var_types.get(name).cloned().unwrap_or("%StructName".to_string()),
                            _ => "%StructName".to_string(),
                        };
                        let struct_name = struct_type.replace("%", "");
                        let field_idx = if let Some(fields) = self.struct_fields.get(&struct_name) {
                            fields.iter().position(|r| r == property_name).unwrap_or(0)
                        } else {
                            0
                        };
                        let field_type = if let Some(types) = self.struct_field_types.get(&struct_name) {
                            types.get(field_idx).cloned().unwrap_or("float".to_string())
                        } else {
                            "float".to_string()
                        };
                        let elem_ptr = self.next_reg();
                        self.output.push_str(&format!("  {} = getelementptr inbounds {}, ptr {}, i32 0, i32 {}\n", elem_ptr, struct_type, obj_reg, field_idx));
                        if field_type == "ptr" {
                            let mut clean_val = val_reg.replace("ptr:", "").replace("struct:", "").replace("array:", "");
                            if clean_val.contains(':') {
                                clean_val = clean_val.split(':').last().unwrap().to_string();
                            }
                            self.output.push_str(&format!("  store ptr {}, ptr {}, align 8\n", clean_val, elem_ptr));
                        } else if field_type.starts_with("%") {
                            let mut clean_val = val_reg.replace("ptr:", "").replace("struct:", "").replace("array:", "");
                            if clean_val.contains(':') {
                                clean_val = clean_val.split(':').last().unwrap().to_string();
                            }
                            let val_load = self.next_reg();
                            self.output.push_str(&format!("  {} = load {}, ptr {}, align 8\n", val_load, field_type, clean_val));
                            self.output.push_str(&format!("  store {} {}, ptr {}, align 8\n", field_type, val_load, elem_ptr));
                        } else {
                            self.output.push_str(&format!("  store float {}, ptr {}, align 4\n", val_reg, elem_ptr));
                        }
                    },
                    _ => {}
                }
                Some(val_reg)
            },
            Expr::Float(f) => {
                let bits = ((*f as f32) as f64).to_bits();
                Some(format!("0x{:016X}", bits))
            },
            Expr::Integer(i) => {
                let bits = ((*i as f32) as f64).to_bits();
                Some(format!("0x{:016X}", bits))
            },
            Expr::StringLiteral(s) => {
                let id = self.string_counter;
                self.string_counter += 1;
                // LLVM strings need to be null terminated
                let clean_s = s.replace("\\n", "\n");
                let mut bytes = Vec::new();
                for b in clean_s.as_bytes() {
                    bytes.push(format!("\\{:02x}", b));
                }
                bytes.push("\\00".to_string());
                let byte_str = bytes.join("");
                let len = clean_s.as_bytes().len() + 1;
                
                self.globals.push_str(&format!("@.str.{} = private unnamed_addr constant [{} x i8] c\"{}\", align 1\n", id, len, byte_str));
                
                // Return a getelementptr to the string
                return Some(format!("string:@.str.{}", id));
            },
            Expr::UnaryOp { op, right } => {
                let rhs = self.visit_expr(right).unwrap_or("0.0".to_string());
                let res_reg = self.next_reg();
                if op == "-" {
                    self.output.push_str(&format!("  {} = fsub float 0.0, {}\n", res_reg, rhs));
                } else {
                    // Fallback for other unary ops if added later
                    self.output.push_str(&format!("  {} = fadd float 0.0, {}\n", res_reg, rhs));
                }
                Some(res_reg)
            },
            Expr::BinaryOp { left, op, right } => {
                let mut l_reg = self.visit_expr(left)?;
                let mut r_reg = self.visit_expr(right)?;
                
                let is_l_ptr = l_reg.starts_with("ptr:") || l_reg.starts_with("array:") || l_reg.starts_with("struct:");
                let is_r_ptr = r_reg.starts_with("ptr:") || r_reg.starts_with("array:") || r_reg.starts_with("struct:");
                
                if is_l_ptr && is_r_ptr {
                    let clean_l = l_reg.split(':').last().unwrap_or(&l_reg);
                    let clean_r = r_reg.split(':').last().unwrap_or(&r_reg);
                    
                    let mut func_name = match op.as_str() {
                        "+" => "cartan_tensor_add",
                        "-" => "cartan_tensor_sub",
                        "*" => "cartan_tensor_mul",
                        "@" => "cartan_tensor_matmul",
                        _ => "cartan_tensor_add", // fallback
                    };
                    
                    if let Expr::Identifier(ident_name) = &**left {
                        if let Some(manifold) = self.var_manifolds.get(ident_name) {
                            if op == "@" {
                                match manifold {
                                    crate::ast::ManifoldSpace::Minkowski => {
                                        func_name = "cartan_tensor_matmul_minkowski";
                                    },
                                    crate::ast::ManifoldSpace::PoincareDisk => {
                                        func_name = "cartan_tensor_matmul_poincare";
                                    },
                                    _ => {} // Default to Euclidean
                                }
                            }
                        }
                    }
                    
                    let res_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = call ptr @{}(ptr {}, ptr {})\n", res_reg, func_name, clean_l, clean_r));
                    return Some(format!("ptr:{}", res_reg));
                }
                
                // Fallback to floats if not both pointers
                if is_l_ptr {
                    let clean = l_reg.split(':').last().unwrap_or(&l_reg);
                    let int_reg = self.next_reg();
                    let float_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = ptrtoint ptr {} to i64\n", int_reg, clean));
                    self.output.push_str(&format!("  {} = sitofp i64 {} to float\n", float_reg, int_reg));
                    l_reg = float_reg;
                }
                if is_r_ptr {
                    let clean = r_reg.split(':').last().unwrap_or(&r_reg);
                    let int_reg = self.next_reg();
                    let float_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = ptrtoint ptr {} to i64\n", int_reg, clean));
                    self.output.push_str(&format!("  {} = sitofp i64 {} to float\n", float_reg, int_reg));
                    r_reg = float_reg;
                }
                
                match op.as_str() {
                    "+" => {
                        let res_reg = self.next_reg();
                        self.output.push_str(&format!("  {} = fadd float {}, {}\n", res_reg, l_reg, r_reg));
                        Some(res_reg)
                    },
                    "-" => {
                        let res_reg = self.next_reg();
                        self.output.push_str(&format!("  {} = fsub float {}, {}\n", res_reg, l_reg, r_reg));
                        Some(res_reg)
                    },
                    "*" => {
                        let res_reg = self.next_reg();
                        self.output.push_str(&format!("  {} = fmul float {}, {}\n", res_reg, l_reg, r_reg));
                        Some(res_reg)
                    },
                    "/" => {
                        let res_reg = self.next_reg();
                        self.output.push_str(&format!("  {} = fdiv float {}, {}\n", res_reg, l_reg, r_reg));
                        Some(res_reg)
                    },
                    "<" | ">" | "==" | "!=" | "<=" | ">=" => {
                        let cond_reg = self.next_reg();
                        let op_str = match op.as_str() {
                            "<" => "olt", ">" => "ogt", "==" => "oeq", "!=" => "one", "<=" => "ole", ">=" => "oge", _ => "oeq"
                        };
                        self.output.push_str(&format!("  {} = fcmp {} float {}, {}\n", cond_reg, op_str, l_reg, r_reg));
                        let res_reg = self.next_reg();
                        self.output.push_str(&format!("  {} = uitofp i1 {} to float\n", res_reg, cond_reg));
                        Some(res_reg)
                    },
                    _ => return None,
                }
            },
            Expr::FusedKernel(exprs) => {
                self.output.push_str("  ; --- Begin Fused Kernel ---\n");
                let mut last_reg = None;
                for expr in exprs {
                    last_reg = self.visit_expr(expr);
                }
                self.output.push_str("  ; --- End Fused Kernel ---\n");
                last_reg
            },
            Expr::MethodCall { object, method_name, args } => {
                if method_name == "load_dma" {
                    if let Expr::Identifier(name) = &**object {
                        if name == "Cartan" {
                            self.output.push_str("  ; --- Cartan.load_dma (Zero-Copy SRAM/HBM) ---\n");
                            let res_reg = self.next_reg();
                            self.output.push_str(&format!("  {} = call ptr @cartan_load_dma()\n", res_reg));
                            return Some(res_reg);
                        }
                    }
                } else if method_name == "prune_graph" {
                    if let Expr::Identifier(name) = &**object {
                        if name == "Cartan" {
                            self.output.push_str("  ; --- Prune Graph (Method Call) ---\n");
                            let arg_reg = if args.len() > 0 { self.visit_expr(&args[0]).unwrap_or("%0".to_string()) } else { "%0".to_string() };
                            self.output.push_str(&format!("  call void @cartan_prune_graph(float {})\n", arg_reg));
                            return None;
                        }
                    }
                }
                
                let obj_reg = self.visit_expr(object).unwrap_or("null".to_string());
                if method_name == "poll" {
                    self.output.push_str("  ; --- Stream Poll ---\n");
                    let res_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = call ptr @cartan_poll_stream(ptr {})\n", res_reg, obj_reg));
                    return Some(res_reg);
                }
                
                let struct_type = match &**object {
                    Expr::Identifier(name) => {
                        if let Some(t) = self.var_types.get(name) {
                            t.clone()
                        } else if let Some(curr_struct) = &self.current_struct {
                            if let Some(field_names) = self.struct_fields.get(curr_struct) {
                                if let Some(idx) = field_names.iter().position(|f| f == name) {
                                    self.struct_field_types.get(curr_struct).unwrap()[idx].clone()
                                } else {
                                    "%StructName".to_string()
                                }
                            } else {
                                "%StructName".to_string()
                            }
                        } else {
                            "%StructName".to_string()
                        }
                    },
                    _ => "%StructName".to_string(),
                };
                let struct_name = struct_type.replace("%", "");
                
                let mut arg_regs = Vec::new();
                for arg in args {
                    arg_regs.push(self.visit_expr(arg).unwrap_or("0.0".to_string()));
                }
                
                let mut arg_str = String::new();
                let clean_obj_reg = obj_reg.replace("ptr:", "").replace("struct:", "").replace("array:", "");
                
                let ptr_reg = if clean_obj_reg.contains(':') {
                    clean_obj_reg.split(':').last().unwrap().to_string()
                } else if clean_obj_reg == "0.0" || clean_obj_reg == "null" {
                    "null".to_string()
                } else {
                    clean_obj_reg
                };
                
                if ptr_reg != "null" {
                    let val_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = load %{}, ptr {}, align 8\n", val_reg, struct_name, ptr_reg));
                    arg_str.push_str(&format!("%{} {}", struct_name, val_reg));
                } else {
                    arg_str.push_str(&format!("%{} undef", struct_name));
                }
                
                for r in arg_regs {
                    arg_str.push_str(", ");
                    if r.starts_with("ptr:") || r.starts_with("string:") || r.starts_with("array:") || r.starts_with("struct:") {
                        let mut clean_r = if r.starts_with("struct:") {
                            r.split(':').last().unwrap().to_string()
                        } else {
                            r.replace("ptr:", "").replace("string:", "").replace("array:", "")
                        };
                        if clean_r == "0.0" { clean_r = "null".to_string(); }
                        arg_str.push_str(&format!("ptr {}", clean_r));
                    } else {
                        arg_str.push_str(&format!("float {}", r));
                    }
                }
                
                let method_full_name = format!("{}_{}", struct_name, method_name);
                let ret_type = self.func_return_types.get(&method_full_name).cloned().unwrap_or("float".to_string());
                let res_reg = if ret_type == "void" { String::new() } else { self.next_reg() };
                
                if ret_type == "void" {
                    self.output.push_str(&format!("  call void @{}({})\n", method_full_name, arg_str));
                    return None;
                } else {
                    self.output.push_str(&format!("  {} = call {} @{}({})\n", res_reg, ret_type, method_full_name, arg_str));
                    if ret_type == "ptr" {
                        return Some(format!("ptr:{}", res_reg));
                    } else {
                        return Some(res_reg);
                    }
                }
            },
            Expr::FunctionCall { name, args } => {
                if name == "Cartan.load_dma" {
                    self.output.push_str("  ; --- Cartan.load_dma (Zero-Copy SRAM/HBM) ---\n");
                    let res_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = call ptr @cartan_load_dma()\n", res_reg));
                    return Some(res_reg);
                }
                
                // Generic Function Call
                let mut arg_regs = Vec::new();
                for arg in args {
                    let mut r = self.visit_expr(arg).unwrap_or("null".to_string());
                    if r == "0.0" { r = "null".to_string(); }
                    arg_regs.push(r);
                }
                
                if name.chars().next().unwrap_or(' ').is_uppercase() {
                    self.output.push_str(&format!("  ; --- Struct Instantiation: {} ---\n", name));
                    let ptr_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = alloca %{}\n", ptr_reg, name));
                    let field_stmts = self.struct_field_stmts.get(name).cloned().unwrap_or_default();
                    for (i, stmt) in field_stmts.iter().enumerate() {
                        let r = if i < arg_regs.len() {
                            arg_regs[i].clone()
                        } else {
                            match stmt {
                                Stmt::VarDecl { value, .. } => {
                                    self.visit_expr(value).unwrap_or("0.0".to_string())
                                },
                                Stmt::TensorDecl { shape, .. } => {
                                    let res_reg = self.next_reg();
                                    if shape.len() > 1 && shape.len() <= 4 {
                                        let mut dims = [1; 4];
                                        for (idx, dim) in shape.iter().enumerate() {
                                            if let Expr::Integer(val) = dim {
                                                dims[idx] = *val as i32;
                                            }
                                        }
                                        self.output.push_str(&format!(
                                            "  {} = call ptr @cartan_tensor_alloc_nd(i32 {}, i32 {}, i32 {}, i32 {}, i32 {})\n",
                                            res_reg, shape.len(), dims[0], dims[1], dims[2], dims[3]
                                        ));
                                    } else {
                                        let mut num_elems = 1;
                                        for dim in shape {
                                            if let Expr::Integer(val) = dim {
                                                num_elems *= *val as i32;
                                            }
                                        }
                                        self.output.push_str(&format!("  {} = call ptr @cartan_tensor_alloc(i32 {})\n", res_reg, num_elems));
                                    }
                                    format!("ptr:{}", res_reg)
                                },
                                Stmt::ParameterDecl { shape, optimizer, .. } => {
                                    let mut alloc_fn = "cartan_tensor_alloc";
                                    let mut alloc_nd_fn = "cartan_tensor_alloc_nd";
                                    if let Some(crate::ast::OptimizerState::Adam) = optimizer {
                                        alloc_fn = "cartan_alloc_parameter_adam";
                                        alloc_nd_fn = "cartan_alloc_parameter_adam_nd";
                                    }
                                    let res_reg = self.next_reg();
                                    if shape.len() > 1 && shape.len() <= 4 {
                                        let mut dims = [1; 4];
                                        for (idx, dim) in shape.iter().enumerate() {
                                            if let Expr::Integer(val) = dim {
                                                dims[idx] = *val as i32;
                                            }
                                        }
                                        self.output.push_str(&format!(
                                            "  {} = call ptr @{}(i32 {}, i32 {}, i32 {}, i32 {}, i32 {})\n",
                                            res_reg, alloc_nd_fn, shape.len(), dims[0], dims[1], dims[2], dims[3]
                                        ));
                                    } else {
                                        let mut num_elems = 1;
                                        for dim in shape {
                                            if let Expr::Integer(val) = dim {
                                                num_elems *= *val as i32;
                                            }
                                        }
                                        self.output.push_str(&format!("  {} = call ptr @{}(i32 {})\n", res_reg, alloc_fn, num_elems));
                                    }
                                    format!("ptr:{}", res_reg)
                                },
                                _ => "0.0".to_string(),
                            }
                        };
                        let raw_r = r.clone();
                        let clean_r = raw_r.replace("ptr:", "").replace("string:", "").replace("array:", "").replace("struct:", "");
                        let mut final_r = clean_r.clone();
                        if final_r.contains(':') {
                            final_r = final_r.split(':').last().unwrap_or(&clean_r).to_string();
                        }
                        let field_ptr = self.next_reg();
                        self.output.push_str(&format!("  {} = getelementptr inbounds %{}, ptr {}, i32 0, i32 {}\n", field_ptr, name, ptr_reg, i));
                        if raw_r.starts_with("struct:") {
                            let struct_type_name = raw_r.split(':').nth(1).unwrap_or("StructName");
                            let val_load = self.next_reg();
                            self.output.push_str(&format!("  {} = load %{}, ptr {}, align 8\n", val_load, struct_type_name, final_r));
                            self.output.push_str(&format!("  store %{} {}, ptr {}, align 8\n", struct_type_name, val_load, field_ptr));
                        } else if raw_r.starts_with("ptr:") || raw_r.starts_with("string:") || raw_r.starts_with("array:") {
                            self.output.push_str(&format!("  store ptr {}, ptr {}\n", final_r, field_ptr));
                        } else {
                            self.output.push_str(&format!("  store float {}, ptr {}\n", final_r, field_ptr));
                        }
                    }
                    return Some(format!("struct:{}:{}", name, ptr_reg));
                }

                if name == "printf" {
                    let mut arg_str = String::new();
                    let dbl_instrs = String::new();
                    for (i, raw_r) in arg_regs.iter().enumerate() {
                        if i > 0 { arg_str.push_str(", "); }
                        let r = raw_r.replace("ptr:", "").replace("string:", "").replace("array:", "");
                        if r.starts_with("@.str.") || r.starts_with("%struct.") || raw_r.starts_with("ptr:") {
                            arg_str.push_str(&format!("ptr {}", r));
                        } else if r.starts_with("%") {
                            let dbl_reg = self.next_reg();
                            self.output.push_str(&format!("  {} = fpext float {} to double\n", dbl_reg, r));
                            arg_str.push_str(&format!("double {}", dbl_reg));
                        } else {
                            arg_str.push_str(&format!("double {}", r));
                        }
                    }
                    self.output.push_str(&dbl_instrs);
                    let res_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = call i32 (ptr, ...) @printf({})\n", res_reg, arg_str));
                    Some(res_reg)
                } else if name == "malloc" {
                    let r = arg_regs[0].replace("ptr:", "").replace("string:", "").replace("array:", "");
                    let int_reg = self.next_reg();
                    let i64_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = fptosi float {} to i32\n", int_reg, r));
                    self.output.push_str(&format!("  {} = sext i32 {} to i64\n", i64_reg, int_reg));
                    let res_reg = self.next_reg();
                    self.output.push_str(&format!("  {} = call ptr @malloc(i64 {})\n", res_reg, i64_reg));
                    Some(format!("ptr:{}", res_reg))
                } else if name == "free" {
                    let r = arg_regs[0].replace("ptr:", "").replace("string:", "").replace("array:", "");
                    self.output.push_str(&format!("  call void @free(ptr {})\n", r));
                    Some(String::new())
                } else {
                    let mut arg_str = String::new();
                    for (i, r) in arg_regs.iter().enumerate() {
                        if i > 0 { arg_str.push_str(", "); }
                        
                        let is_ptr = r.starts_with("ptr:") || r.starts_with("string:") || r.starts_with("array:") || r.starts_with("@.str.") || r.starts_with("%struct.");
                        
                        let clean_r = r.replace("ptr:", "").replace("string:", "").replace("array:", "");
                        
                        if is_ptr {
                            arg_str.push_str(&format!("ptr {}", clean_r));
                        } else {
                            arg_str.push_str(&format!("float {}", clean_r));
                        }
                    }
                    let ret_type = self.func_return_types.get(name).cloned().unwrap_or("float".to_string());
                    if ret_type == "void" {
                        self.output.push_str(&format!("  call void @{}({})\n", name, arg_str));
                        Some("0.0".to_string())
                    } else if ret_type == "ptr" || ret_type == "i32" {
                        let ret_reg = self.next_reg();
                        self.output.push_str(&format!("  {} = call {} @{}({})\n", ret_reg, ret_type, name, arg_str));
                        if ret_type == "ptr" {
                            Some(format!("ptr:{}", ret_reg))
                        } else {
                            let float_res = self.next_reg();
                            self.output.push_str(&format!("  {} = sitofp i32 {} to float\n", float_res, ret_reg));
                            Some(float_res)
                        }
                    } else {
                        let res_reg = self.next_reg();
                        self.output.push_str(&format!("  {} = call {} @{}({})\n", res_reg, ret_type, name, arg_str));
                        Some(res_reg)
                    }
                }
            },
            Expr::Attention { target, routing } => {
                self.output.push_str(&format!("  ; --- Attention Routing: {} ---\n", routing));
                self.visit_expr(target)
            },
            Expr::SievingCacheInit => {
                self.output.push_str("  ; --- Init SievingCache ---\n");
                let res = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_init_sieving_cache()\n", res));
                Some(format!("ptr:{}", res))
            },
            Expr::FractalAttentionInit => {
                self.output.push_str("  ; --- Init FractalAttentionBlock ---\n");
                let res = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_init_fractal_attention()\n", res));
                Some(format!("ptr:{}", res))
            },
            Expr::StreamInit { modalities: _modalities, uri: _ } => {
                self.output.push_str("  ; --- Init Native Stream Interconnect ---\n");
                let res = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_stream_init(ptr null, ptr null)\n", res));
                Some(format!("ptr:{}", res))
            },
            Expr::ElasticVocabularyInit => {
                self.output.push_str("  ; --- Init Elastic Vocabulary ---\n");
                let res = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_init_elastic_vocabulary()\n", res));
                Some(format!("ptr:{}", res))
            },
            Expr::TokenizeBPE { text, tokenizer_path } => {
                self.output.push_str("  ; --- Tokenize BPE ---\n");
                let text_reg = self.visit_expr(text).unwrap_or("null".to_string());
                let res = self.next_reg();
                
                let path_str_ptr = self.next_reg();
                let len = tokenizer_path.len() + 1;
                self.output.push_str(&format!("  {} = alloca [{} x i8]\n", path_str_ptr, len));
                self.output.push_str(&format!("  store [{} x i8] c\"{}\\00\", ptr {}\n", len, tokenizer_path, path_str_ptr));
                
                self.output.push_str(&format!("  {} = call ptr @cartan_tokenize_bpe(ptr {}, ptr {})\n", res, text_reg, path_str_ptr));
                Some(format!("ptr:{}", res))
            },
            Expr::AlignSpans { vocab_a, vocab_b, projection_matrix } => {
                self.output.push_str("  ; --- Align Spans (Cross-Tokenizer Projection) ---\n");
                let proj_reg = self.visit_expr(projection_matrix).unwrap_or("null".to_string());
                
                let path_a_ptr = self.next_reg();
                let len_a = vocab_a.len() + 1;
                self.output.push_str(&format!("  {} = alloca [{} x i8]\n", path_a_ptr, len_a));
                self.output.push_str(&format!("  store [{} x i8] c\"{}\\00\", ptr {}\n", len_a, vocab_a, path_a_ptr));
                
                let path_b_ptr = self.next_reg();
                let len_b = vocab_b.len() + 1;
                self.output.push_str(&format!("  {} = alloca [{} x i8]\n", path_b_ptr, len_b));
                self.output.push_str(&format!("  store [{} x i8] c\"{}\\00\", ptr {}\n", len_b, vocab_b, path_b_ptr));
                
                self.output.push_str(&format!("  call void @cartan_align_spans(ptr {}, ptr {}, ptr {})\n", path_a_ptr, path_b_ptr, proj_reg));
                None // AlignSpans doesn't return anything (void)
            },
            Expr::LexAndEmbed(target) => {
                self.output.push_str("  ; --- Hard-Lexing FSA Kernel (LexAndEmbed) ---\n");
                let target_reg = self.visit_expr(target).unwrap_or("null".to_string());
                let res = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_lex_and_embed(ptr {})\n", res, target_reg));
                Some(res)
            },
            Expr::AlignGeodesics(a, b) => {
                self.output.push_str("  ; --- Align Geodesics ---\n");
                let reg_a = self.visit_expr(a).unwrap_or("%0".to_string());
                let reg_b = self.visit_expr(b).unwrap_or("%0".to_string());
                let res = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_align_geodesics(ptr {}, ptr {})\n", res, reg_a, reg_b));
                Some(res)
            },
            Expr::GeometricBridge(a, b) => {
                self.output.push_str("  ; --- Geometric Bridge ---\n");
                let reg_a = self.visit_expr(a).unwrap_or("%0".to_string());
                let reg_b = self.visit_expr(b).unwrap_or("%0".to_string());
                let res = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_geometric_bridge(ptr {}, ptr {})\n", res, reg_a, reg_b));
                Some(res)
            },
            Expr::TransposeWeights(a, b) => {
                self.output.push_str("  ; --- Transpose Weights ---\n");
                let reg_a = self.visit_expr(a).unwrap_or("%0".to_string());
                let reg_b = self.visit_expr(b).unwrap_or("%0".to_string());
                let res = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_transpose_weights(ptr {}, ptr {})\n", res, reg_a, reg_b));
                Some(res)
            },
            Expr::ReflectRepo => {
                self.output.push_str("  ; --- Reflect Repo ---\n");
                let res = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_reflect_repo()\n", res));
                Some(res)
            },
            Expr::HotSwap(target, new_graph) => {
                self.output.push_str("  ; --- Hot Swap ---\n");
                let target_reg = self.visit_expr(target).unwrap_or("null".to_string());
                let new_graph_reg = self.visit_expr(new_graph).unwrap_or("%0".to_string());
                self.output.push_str("  ; Try-Catch Sandbox Safety Boundary\n");
                self.output.push_str(&format!("  call void @cartan_sandbox_hot_swap(ptr {}, ptr {})\n", target_reg, new_graph_reg));
                Some(String::new())
            },
            Expr::SpikePrimitive => {
                let res = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_init_spike()\n", res));
                Some(res)
            },
            Expr::NeuronPrimitive => {
                let res = self.next_reg();
                self.output.push_str(&format!("  {} = call ptr @cartan_init_neuron()\n", res));
                Some(res)
            },
            _ => None
        }
    }
}

