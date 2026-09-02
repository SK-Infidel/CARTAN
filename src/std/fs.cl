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

fn cartan_file_exists(path: string) -> float {
    let f = fopen(path, "rb");
    if (f == 0.0) { return 0.0; }
    fclose(f);
    return 1.0;
}

extern fn c_cartan_read_file(path: string) -> string;

fn cartan_read_file(path: string) -> string {
    return c_cartan_read_file(path);
}

fn cartan_write_file(path: string, content: string) -> float {
    let f = fopen(path, "w");
    if (f == 0.0) { return 0.0; }
    fputs(content, f);
    fclose(f);
    return 1.0;
}

fn cartan_copy_file(src: string, dst: string) -> float {
    let in_f = fopen(src, "rb");
    if (in_f == 0.0) { return 0.0; }
    let out_f = fopen(dst, "wb");
    if (out_f == 0.0) {
        fclose(in_f);
        return 0.0;
    }
    let buf = malloc(65536.0);
    if (buf == 0.0) {
        fclose(in_f);
        fclose(out_f);
        return 0.0;
    }
    var bytes = fread(buf, 1.0, 65536.0, in_f);
    while (bytes > 0.0) {
        fwrite(buf, 1.0, bytes, out_f);
        bytes = fread(buf, 1.0, 65536.0, in_f);
    }
    free(buf);
    fclose(in_f);
    fclose(out_f);
    return 1.0;
}

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
