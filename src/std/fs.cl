// src/std/fs.cl
// CARTAN Standard Library: Pure Native File System Operations Module

extern fn fopen(path: string, mode: string) -> ptr;
extern fn fclose(file: ptr) -> float;
extern fn fseek(file: ptr, offset: float, origin: float) -> float;
extern fn ftell(file: ptr) -> float;
extern fn fread(buffer: ptr, size: float, count: float, file: ptr) -> float;
extern fn fwrite(buffer: ptr, size: float, count: float, file: ptr) -> float;
extern fn fputs(str: string, file: ptr) -> float;
extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr);

extern fn cartan_file_exists(path: string) -> float;
extern fn cartan_read_file(path: string) -> string;
extern fn cartan_write_file(path: string, content: string) -> float;
extern fn cartan_copy_file(src: string, dst: string) -> float;

fn fs_exists(path: string) -> float {
    return cartan_file_exists(path);
}

fn fs_copy(src: string, dst: string) -> float {
    return cartan_copy_file(src, dst);
}

fn fs_read_all(path: string) -> string {
    return cartan_read_file(path);
}

fn fs_write_all(path: string, content: string) -> float {
    return cartan_write_file(path, content);
}

