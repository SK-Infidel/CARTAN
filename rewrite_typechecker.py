import os

with open('compiler/src/type_checker.rs', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Replace struct TypeChecker
code = code.replace(
'''pub struct TypeChecker {
    symbol_table: Vec<HashMap<String, CartanType>>,
    symbolic_dims: HashMap<String, Option<u32>>,
}''',
'''pub struct TypeChecker {
    functions: HashMap<String, Vec<crate::ast::FunctionDecl>>,
    symbol_table: Vec<HashMap<String, CartanType>>,
    symbolic_dims: HashMap<String, Option<u32>>,
}''')

# 2. Replace TypeChecker::new()
code = code.replace(
'''    pub fn new() -> Self {
        Self {
            symbol_table: vec![HashMap::new()],
            symbolic_dims: HashMap::new(),
        }
    }''',
'''    pub fn new() -> Self {
        Self {
            functions: HashMap::new(),
            symbol_table: vec![HashMap::new()],
            symbolic_dims: HashMap::new(),
        }
    }''')

# 3. Replace TypeChecker::check
code = code.replace(
'''    pub fn check(&mut self, ast: &mut [Stmt]) -> Result<(), Diagnostic> {
        for stmt in ast {
            self.visit_stmt(stmt)?;
        }
        Ok(())
    }''',
'''    pub fn check(&mut self, ast: &mut [Stmt]) -> Result<(), Diagnostic> {
        for stmt in ast.iter() {
            if let Stmt::FunctionDecl(decl) = stmt {
                self.functions.entry(decl.name.clone()).or_default().push(decl.clone());
            }
        }
        for stmt in ast {
            self.visit_stmt(stmt)?;
        }
        Ok(())
    }''')

# 4. Replace Expr::FunctionCall
old_func_call = '''            Expr::FunctionCall { name, args } => {
                let mut arg_types = Vec::new();
                for arg in args {
                    arg_types.push(self.visit_expr(arg)?);
                }
                if name == "ones_like" && arg_types.len() == 1 {
                    return Ok(arg_types[0].clone());
                }
                Ok(CartanType::Unknown)
            },'''

new_func_call = '''            Expr::FunctionCall { name, args } => {
                let mut arg_types = Vec::new();
                for arg in args.iter_mut() {
                    arg_types.push(self.visit_expr(arg)?);
                }
                if name == "ones_like" && arg_types.len() == 1 {
                    return Ok(arg_types[0].clone());
                }
                
                if let Some(funcs) = self.functions.get(name).cloned() {
                    for func in funcs {
                        if func.parameters.len() == arg_types.len() {
                            let mut matches = true;
                            for (i, param) in func.parameters.iter().enumerate() {
                                let arg_t = &arg_types[i];
                                if let CartanType::Tensor(_, arg_manifold, _) = arg_t {
                                    if let Some(param_manifold) = &param.manifold {
                                        if param_manifold != arg_manifold {
                                            matches = false;
                                            break;
                                        }
                                    }
                                }
                            }
                            if matches {
                                let mut mangled = name.clone();
                                for param in &func.parameters {
                                    if let Some(m) = &param.manifold {
                                        mangled.push('_');
                                        mangled.push_str(&format!("{:?}", m).to_lowercase());
                                    }
                                }
                                *name = mangled;
                                return Ok(CartanType::Unknown);
                            }
                        }
                    }
                }
                
                Ok(CartanType::Unknown)
            },'''

code = code.replace(old_func_call, new_func_call)

with open('compiler/src/type_checker.rs', 'w', encoding='utf-8') as f:
    f.write(code)

print("done")
