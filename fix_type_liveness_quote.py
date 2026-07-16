import os

with open('compiler/src/type_checker.rs', 'r', encoding='utf-8') as f:
    code = f.read()

typecheck_logic = '''            Expr::Quote(block) => {
                for stmt in &mut block.statements {
                    self.visit_stmt(stmt)?;
                }
                Ok(CartanType::Tensor(vec![0]))
            },
            Expr::HotSwap'''

code = code.replace('''            Expr::Quote(block) => {
                for stmt in &block.statements {
                    self.visit_stmt(stmt);
                }
            },
            Expr::HotSwap''', typecheck_logic)

with open('compiler/src/type_checker.rs', 'w', encoding='utf-8') as f:
    f.write(code)

with open('compiler/src/liveness.rs', 'r', encoding='utf-8') as f:
    code = f.read()

liveness_logic = '''            Expr::Quote(_) => {},
            Expr::HotSwap'''

code = code.replace('''            Expr::Quote(block) => {
                for stmt in &block.statements {
                    self.visit_stmt(stmt);
                }
            },
            Expr::HotSwap''', liveness_logic)

with open('compiler/src/liveness.rs', 'w', encoding='utf-8') as f:
    f.write(code)
