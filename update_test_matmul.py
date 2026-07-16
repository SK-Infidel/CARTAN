import os
with open('test_autodiff_matmul.ctn', 'w', encoding='utf-8') as f:
    f.write('tensor A[2, 3];\ntensor B[3, 4];\nlet C = A @ B;\nbackward C;\n')
