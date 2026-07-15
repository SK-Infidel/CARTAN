import os

with open('src/type_checker.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_call = '''            Expr::FunctionCall { name: _name, args } => {
                for arg in args {
                    self.visit_expr(arg)?;
                }
                Ok(CartanType::Unknown)
            },'''

new_call = '''            Expr::FunctionCall { name, args } => {
                let mut arg_manifolds = Vec::new();
                for arg in args {
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
                    *name = mangled;
                }
                
                Ok(CartanType::Unknown)
            },'''

if old_call in code:
    code = code.replace(old_call, new_call)
    with open('src/type_checker.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Mangled FunctionCall")
else:
    print("Could not find Expr::FunctionCall block!")

