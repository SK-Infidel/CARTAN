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

    if 'macro_pass.rs' in file or 'optimizer.rs' in file or 'autodiff.rs' in file:
        quote_logic = '''            Expr::Quote(block) => {
                let mut new_block = block.clone();
                for stmt in &mut new_block.statements {
                    *stmt = self.visit_stmt(stmt);
                }
                Expr::Quote(new_block)
            },
            Expr::HotSwap'''
        code = code.replace('            Expr::HotSwap', quote_logic)
    elif 'liveness.rs' in file or 'type_checker.rs' in file:
        quote_logic = '''            Expr::Quote(block) => {
                for stmt in &block.statements {
                    self.visit_stmt(stmt);
                }
            },
            Expr::HotSwap'''
        code = code.replace('            Expr::HotSwap', quote_logic)

    with open(file, 'w', encoding='utf-8') as f:
        f.write(code)
