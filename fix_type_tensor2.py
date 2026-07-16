import os

with open('compiler/src/type_checker.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('''                Ok(CartanType::Tensor(vec![crate::types::Dimension::Fixed(0)], crate::types::ManifoldSpace::Euclidean, None))''', '''                Ok(CartanType::Tensor(vec![crate::types::Dimension::Fixed(0)], crate::ast::ManifoldSpace::Euclidean, None))''')

code = code.replace('''            Expr::Quote(_) => {
                Ok(CartanType::Tensor(vec![Dimension::Fixed(1)], ManifoldSpace::Euclidean, None))
            },''', '')

with open('compiler/src/type_checker.rs', 'w', encoding='utf-8') as f:
    f.write(code)
