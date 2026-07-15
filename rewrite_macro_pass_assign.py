import os

with open('compiler/src/macro_pass.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_code = '''            Expr::MethodCall { object, args, .. } => {
                self.substitute_expr(object, bindings);
                for arg in args {
                    self.substitute_expr(arg, bindings);
                }
            }'''
new_code = '''            Expr::MethodCall { object, args, .. } => {
                self.substitute_expr(object, bindings);
                for arg in args {
                    self.substitute_expr(arg, bindings);
                }
            }
            Expr::Assignment { target, value } => {
                self.substitute_expr(target, bindings);
                self.substitute_expr(value, bindings);
            }'''

if old_code in code:
    code = code.replace(old_code, new_code)
    with open('compiler/src/macro_pass.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added Assignment to substitute_expr")
else:
    print("Failed to find MethodCall")

