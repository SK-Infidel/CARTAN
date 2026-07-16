import os

with open('compiler/src/type_checker.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('''                Ok(CartanType::Tensor(vec![0]))''', '''                Ok(CartanType::Tensor(vec![crate::types::Dimension::Fixed(0)], crate::types::ManifoldSpace::Euclidean, None))''')

with open('compiler/src/type_checker.rs', 'w', encoding='utf-8') as f:
    f.write(code)
