@echo off
set "INCLUDE=C:\PROGRA~1\MIB055~1\18\Community\VC\Tools\MSVC\14.51.36231\include;C:\PROGRA~2\WI3CF2~1\10\Include\10.0.22621.0\ucrt;C:\PROGRA~2\WI3CF2~1\10\Include\10.0.22621.0\shared;C:\PROGRA~2\WI3CF2~1\10\Include\10.0.22621.0\um"
set "LIB=C:\PROGRA~1\MIB055~1\18\Community\VC\Tools\MSVC\14.51.36231\lib\x64;C:\PROGRA~2\WI3CF2~1\10\lib\10.0.22621.0\ucrt\x64;C:\PROGRA~2\WI3CF2~1\10\lib\10.0.22621.0\um\x64"
set "PATH=C:\PROGRA~1\MIB055~1\18\Community\VC\Tools\MSVC\14.51.36231\bin\Hostx64\x64;%PATH%"
nvcc -O3 -c src/cartanc/cartan_cuda_kernels.cu -o build/cartan_cuda_kernels.obj
