import os

with open('src/type_checker.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_code = '''                let mut body_clone = Stmt::Block(decl.body.clone()); self.visit_stmt(&mut body_clone)?;
                self.pop_scope();'''

new_code = '''                for stmt in &mut decl.body.statements {
                    self.visit_stmt(stmt)?;
                }
                self.pop_scope();'''

if old_code in code:
    code = code.replace(old_code, new_code)
    with open('src/type_checker.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Fixed clone bug!")
else:
    print("Could not find body_clone line!")

