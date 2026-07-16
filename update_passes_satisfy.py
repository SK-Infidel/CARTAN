import os

files_to_patch = [
    'compiler/src/macro_pass.rs',
    'compiler/src/optimizer.rs',
    'compiler/src/autodiff.rs',
    'compiler/src/liveness.rs',
    'compiler/src/type_checker.rs'
]

for file in files_to_patch:
    with open(file, 'r', encoding='utf-8') as f:
        code = f.read()

    # Some passes use mut self, some use Stmt as return type, some return ().
    if 'macro_pass.rs' in file or 'optimizer.rs' in file:
        satisfy_logic = '''            Stmt::Satisfy { condition, body, otherwise } => {
                let mut new_body = body.clone();
                for stmt in &mut new_body.statements {
                    *stmt = self.visit_stmt(stmt);
                }
                let mut new_otherwise = otherwise.clone();
                if let Some(oth) = &mut new_otherwise {
                    for stmt in &mut oth.statements {
                        *stmt = self.visit_stmt(stmt);
                    }
                }
                Stmt::Satisfy {
                    condition: self.visit_expr(condition),
                    body: new_body,
                    otherwise: new_otherwise,
                }
            },
            Stmt::Backtrack => Stmt::Backtrack,
            Stmt::Continue => Stmt::Continue,'''
        code = code.replace('            Stmt::Continue => Stmt::Continue,', satisfy_logic)
    elif 'autodiff.rs' in file:
        satisfy_logic = '''            Stmt::Satisfy { condition, body, otherwise } => {
                let mut new_body = body.clone();
                for stmt in &mut new_body.statements {
                    *stmt = self.visit_stmt(stmt);
                }
                let mut new_otherwise = otherwise.clone();
                if let Some(oth) = &mut new_otherwise {
                    for stmt in &mut oth.statements {
                        *stmt = self.visit_stmt(stmt);
                    }
                }
                Stmt::Satisfy {
                    condition: self.visit_expr(condition),
                    body: new_body,
                    otherwise: new_otherwise,
                }
            },
            Stmt::Backtrack => Stmt::Backtrack,
            Stmt::Continue => Stmt::Continue,'''
        code = code.replace('            Stmt::Continue => Stmt::Continue,', satisfy_logic)
    elif 'liveness.rs' in file or 'type_checker.rs' in file:
        satisfy_logic = '''            Stmt::Satisfy { condition, body, otherwise } => {
                self.visit_expr(condition);
                for stmt in &body.statements {
                    self.visit_stmt(stmt);
                }
                if let Some(oth) = otherwise {
                    for stmt in &oth.statements {
                        self.visit_stmt(stmt);
                    }
                }
            },
            Stmt::Backtrack => {},
            Stmt::Continue => {},'''
        code = code.replace('            Stmt::Continue => {},', satisfy_logic)

    with open(file, 'w', encoding='utf-8') as f:
        f.write(code)
