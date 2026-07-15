import os

with open('src/type_checker.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_decl = '''            Stmt::FunctionDecl(decl) => {
                // Register function parameters in a new scope
                self.push_scope();'''

new_decl = '''            Stmt::FunctionDecl(decl) => {
                let mut mangled = decl.name.clone();
                for param in &decl.parameters {
                    if let Some(m) = &param.manifold {
                        mangled.push('_');
                        mangled.push_str(&format!("{:?}", m).to_lowercase());
                    }
                }
                decl.name = mangled;
                
                // Register function parameters in a new scope
                self.push_scope();'''

if old_decl in code:
    code = code.replace(old_decl, new_decl)
    with open('src/type_checker.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Mangled FunctionDecl")
else:
    print("Could not find Stmt::FunctionDecl block!")

