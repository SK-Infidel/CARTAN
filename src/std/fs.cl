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

extern fn cartan_byte_at(buf: ptr, offset: float) -> float;
extern fn cartan_set_byte(buf: ptr, offset: float, val: float);

fn cartan_print_string(text: string) {
    if (text != 0.0) {
        printf("%s", text);
    }
}

fn cartan_alloc_binary_buffer(size: float) -> ptr {
    if (size <= 0.0) { return 0.0; }
    return malloc(size + 4.0);
}

fn cartan_free_binary_buffer(buf: ptr) {
    if (buf != 0.0) {
        free(buf);
    }
}

fn cartan_get_binary_file_size(path: string) -> float {
    if (path == 0.0) { return 0.0; }
    let f = fopen(path, "rb");
    if (f == 0.0) { return 0.0; }
    fseek(f, 0.0, 2.0); // SEEK_END = 2
    let sz = ftell(f);
    fclose(f);
    return sz;
}

fn cartan_read_binary_file_data(path: string) -> ptr {
    if (path == 0.0) { return 0.0; }
    let f = fopen(path, "rb");
    if (f == 0.0) { return 0.0; }
    fseek(f, 0.0, 2.0);
    let sz = ftell(f);
    fseek(f, 0.0, 0.0); // SEEK_SET = 0
    if (sz <= 0.0) {
        fclose(f);
        return 0.0;
    }
    let buf = malloc(sz + 4.0);
    if (buf == 0.0) {
        fclose(f);
        return 0.0;
    }
    fread(buf, 1.0, sz, f);
    fclose(f);
    return buf;
}

fn cartan_write_binary_file(path: string, buf: ptr, size: float) -> float {
    if (path == 0.0 || buf == 0.0 || size <= 0.0) { return 0.0; }
    let f = fopen(path, "wb");
    if (f == 0.0) { return 0.0; }
    fwrite(buf, 1.0, size, f);
    fclose(f);
    return 1.0;
}


