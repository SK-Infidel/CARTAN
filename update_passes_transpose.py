import os

with open('compiler/src/liveness.rs', 'r', encoding='utf-8') as f:
    code = f.read()

liveness_logic = '''            Expr::Transpose(inner) => {
                self.visit_expr_usage(inner, idx);
            },
            Expr::TransposeWeights'''

code = code.replace('            Expr::TransposeWeights', liveness_logic)

with open('compiler/src/liveness.rs', 'w', encoding='utf-8') as f:
    f.write(code)

with open('compiler/src/macro_pass.rs', 'r', encoding='utf-8') as f:
    code = f.read()

macro_logic = '''            Expr::Transpose(inner) => {
                Expr::Transpose(Box::new(self.visit_expr(inner)))
            },
            Expr::TransposeWeights'''

code = code.replace('            Expr::TransposeWeights', macro_logic)

with open('compiler/src/macro_pass.rs', 'w', encoding='utf-8') as f:
    f.write(code)
    
with open('compiler/src/optimizer.rs', 'r', encoding='utf-8') as f:
    code = f.read()

opt_logic = '''            Expr::Transpose(inner) => {
                Expr::Transpose(Box::new(self.visit_expr(inner)))
            },
            Expr::TransposeWeights'''

code = code.replace('            Expr::TransposeWeights', opt_logic)

with open('compiler/src/optimizer.rs', 'w', encoding='utf-8') as f:
    f.write(code)
