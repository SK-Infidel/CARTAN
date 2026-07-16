import os

with open('compiler/src/llvm_codegen.rs', 'r', encoding='utf-8') as f:
    code = f.read()

satisfy_logic = '''            Stmt::Satisfy { condition, body, otherwise } => {
                let start_label = self.next_label("satisfy_start_");
                let end_label = self.next_label("satisfy_end_");
                let otherwise_label = self.next_label("satisfy_otherwise_");

                self.loop_labels.push((start_label.clone(), end_label.clone()));

                self.output.push_str(&format!("  br label %{}\\n", start_label));
                self.output.push_str(&format!("{}:\\n", start_label));

                for stmt in &body.statements {
                    self.visit_stmt(stmt);
                }
                
                let cond_reg = self.visit_expr(condition).unwrap_or("0.0".to_string());
                let clean_cond = cond_reg.split(':').last().unwrap_or(&cond_reg).to_string();
                let is_true = self.next_reg();
                self.output.push_str(&format!("  {} = fcmp une float {}, 0.0\\n", is_true, clean_cond));
                self.output.push_str(&format!("  br i1 {}, label %{}, label %{}\\n", is_true, end_label, otherwise_label));

                self.output.push_str(&format!("{}:\\n", otherwise_label));
                if let Some(oth) = otherwise {
                    for stmt in &oth.statements {
                        self.visit_stmt(stmt);
                    }
                }
                self.output.push_str(&format!("  br label %{}\\n", start_label));
                self.output.push_str(&format!("{}:\\n", end_label));

                self.loop_labels.pop();
            },
            Stmt::Backtrack => {
                if let Some((cond_label, _)) = self.loop_labels.last() {
                    self.output.push_str(&format!("  br label %{}\\n", cond_label));
                    let unreachable = self.next_label("unreachable_");
                    self.output.push_str(&format!("{}:\\n", unreachable));
                }
            },
            Stmt::Continue => {'''

code = code.replace('            Stmt::Continue => {', satisfy_logic)

with open('compiler/src/llvm_codegen.rs', 'w', encoding='utf-8') as f:
    f.write(code)
