import os

type_checker_code = '''            Stmt::Match { condition, arms } => {
                self.visit_expr(condition)?;
                for (pattern, body) in arms {
                    if let Some(p) = pattern {
                        self.visit_expr(p)?;
                    }
                    self.visit_stmt(body)?;
                }
            },'''

liveness_code = '''            Stmt::Match { condition, arms } => {
                self.visit_expr_usage(condition, idx);
                for (pattern, body) in arms {
                    if let Some(p) = pattern {
                        self.visit_expr_usage(p, idx);
                    }
                    self.visit_stmt(body, idx);
                }
            },'''

macro_code = '''            Stmt::Match { condition, arms } => {
                let new_cond = self.visit_expr(condition);
                let mut new_arms = Vec::new();
                for (pattern, body) in arms {
                    let new_p = pattern.clone().map(|p| self.visit_expr(&p));
                    let mut new_body = body.clone();
                    self.visit_stmt(&mut new_body);
                    new_arms.push((new_p, new_body));
                }
                *stmt = Stmt::Match { condition: new_cond, arms: new_arms };
            },'''

opt_code = '''            Stmt::Match { condition, arms } => {
                let new_cond = self.visit_expr(condition);
                let mut new_arms = Vec::new();
                for (pattern, body) in arms {
                    let new_p = pattern.clone().map(|p| self.visit_expr(&p));
                    let mut new_body = body.clone();
                    self.visit_stmt(&mut new_body);
                    new_arms.push((new_p, new_body));
                }
                *stmt = Stmt::Match { condition: new_cond, arms: new_arms };
            },'''

codegen_code = '''            Stmt::Match { condition, arms } => {
                let cond_val = self.visit_expr(condition).unwrap_or("".to_string());
                let end_label = self.next_label("match_end_");
                let mut next_arm_label = self.next_label("match_arm_");

                for (i, (pattern, body)) in arms.iter().enumerate() {
                    self.output.push_str(&format!("{}:\\n", next_arm_label));
                    let is_last = i == arms.len() - 1;
                    let fallthrough_label = if is_last {
                        end_label.clone()
                    } else {
                        self.next_label("match_arm_")
                    };

                    if let Some(p) = pattern {
                        let p_val = self.visit_expr(p).unwrap_or("".to_string());
                        let is_match_reg = self.next_reg();
                        
                        if cond_val.starts_with("ptr:") || p_val.starts_with("ptr:") {
                            let c_p = cond_val.replace("ptr:", "");
                            let p_p = p_val.replace("ptr:", "");
                            let cmp_res = self.next_reg();
                            self.output.push_str(&format!("  {} = call i32 @strcmp(ptr {}, ptr {})\\n", cmp_res, c_p, p_p));
                            self.output.push_str(&format!("  {} = icmp eq i32 {}, 0\\n", is_match_reg, cmp_res));
                        } else {
                            self.output.push_str(&format!("  {} = fcmp oeq float {}, {}\\n", is_match_reg, cond_val, p_val));
                        }
                        
                        let body_label = self.next_label("match_body_");
                        self.output.push_str(&format!("  br i1 {}, label %{}, label %{}\\n", is_match_reg, body_label, fallthrough_label));
                        self.output.push_str(&format!("{}:\\n", body_label));
                    }
                    
                    if let Stmt::Block(b) = &**body {
                        for s in &b.statements { self.visit_stmt(s); }
                    } else {
                        self.visit_stmt(body);
                    }
                    self.output.push_str(&format!("  br label %{}\\n", end_label));
                    next_arm_label = fallthrough_label;
                }
                
                self.output.push_str(&format!("{}:\\n", end_label));
            },'''


def fix(file, bad_insertion, good_insertion):
    with open(file, 'r', encoding='utf-8') as f:
        code = f.read()
    
    # Remove the bad insertion entirely:
    search_str = '            Stmt::If { condition, true_block, false_block } => {\n' + bad_insertion
    code = code.replace(search_str, '            Stmt::If { condition, true_block, false_block } => {')
    
    # Now insert correctly before Stmt::If
    code = code.replace('            Stmt::If { condition, true_block, false_block } => {', good_insertion + '\n            Stmt::If { condition, true_block, false_block } => {')
    
    with open(file, 'w', encoding='utf-8') as f:
        f.write(code)

fix('compiler/src/type_checker.rs', type_checker_code, type_checker_code)
fix('compiler/src/liveness.rs', liveness_code, liveness_code)
fix('compiler/src/macro_pass.rs', macro_code, macro_code)
fix('compiler/src/optimizer.rs', opt_code, opt_code)
fix('compiler/src/llvm_codegen.rs', codegen_code, codegen_code)
print("Done")
