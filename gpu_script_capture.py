import sys

def modify_file():
    with open('..\\\\CARTAN\\\\gpu_runtime\\\\src\\\\lib.rs', 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix add, sub, mul closure captures in gpu_runtime
    content = content.replace(
        'let idx_a = get_tensor_index(i, &target_shape, &a_strides, &(*a).shape);',
        'let idx_a = get_tensor_index(i, &target_shape, &a_strides, &a_shape);'
    )
    content = content.replace(
        'let idx_b = get_tensor_index(i, &target_shape, &b_strides, &(*b).shape);',
        'let idx_b = get_tensor_index(i, &target_shape, &b_strides, &b_shape);'
    )

    with open('..\\\\CARTAN\\\\gpu_runtime\\\\src\\\\lib.rs', 'w', encoding='utf-8') as f:
        f.write(content)

modify_file()
