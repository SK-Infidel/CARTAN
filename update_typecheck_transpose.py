import os

with open('compiler/src/type_checker.rs', 'r', encoding='utf-8') as f:
    code = f.read()

transpose_logic = '''            Expr::Transpose(inner) => {
                let inner_type = self.visit_expr(inner)?;
                match inner_type {
                    CartanType::Tensor(dims, space, layout) => {
                        let mut new_dims = dims.clone();
                        if new_dims.len() >= 2 {
                            let len = new_dims.len();
                            new_dims.swap(len - 1, len - 2);
                        }
                        Ok(CartanType::Tensor(new_dims, space, layout))
                    },
                    _ => Ok(inner_type)
                }
            },
            Expr::TransposeWeights'''

code = code.replace('            Expr::TransposeWeights', transpose_logic)

with open('compiler/src/type_checker.rs', 'w', encoding='utf-8') as f:
    f.write(code)
