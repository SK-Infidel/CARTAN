import os

with open('compiler/src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    code = f.read()

mesh_codegen = '''            },
            Stmt::MeshBlock { name, strategy, body } => {
                self.output.push_str(&format!("  ; --- Begin Mesh Block: {} (Supervisor: {}) ---\\n", name, strategy));
                for stmt in &body.statements {
                    self.visit_stmt(stmt);
                }
                self.output.push_str(&format!("  ; --- End Mesh Block: {} ---\\n", name));
            },
            _ => {}'''

code = code.replace('            },\n            _ => {}', mesh_codegen)

with open('compiler/src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
    f.write(code)
