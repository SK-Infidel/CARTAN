// src/std/collections.cl
// CARTAN Standard Library: Layer 1 Generic Collections & Data Structures Module

extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr);
extern fn cartan_tree_create() -> ptr;
extern fn cartan_tree_len_f(t: ptr) -> float;
extern fn cartan_tree_push(t: ptr, item: ptr) -> void;
extern fn cartan_tree_get_f32(t: ptr, idx: float) -> ptr;

fn create_list() -> ptr {
    var list = malloc(16384.0);
    if (list == 0.0) { return list; }
    list[0] = 0.0;    // len
    list[1] = 2000.0; // capacity (2000 * 8 bytes <= 16384 bytes)
    return list;
}

fn free_list(list: ptr) {
    if (list != 0.0) { free(list); }
}

fn list_push(list: ptr, val: float) -> float {
    if (list == 0.0) { return 0.0; }
    let len = list[0];
    let cap = list[1];
    if (len >= cap) { return len; } // bounds check guard
    list[2.0 + len] = val;
    list[0] = len + 1.0;
    return list[0];
}

fn list_get(list: ptr, idx: float) -> float {
    if (list == 0.0) { return 0.0; }
    let len = list[0];
    if (idx < 0.0 || idx >= len) { return 0.0; } // bounds check
    return list[2.0 + idx];
}

fn list_len(list: ptr) -> float {
    if (list == 0.0) { return 0.0; }
    return list[0];
}

fn create_stack() -> ptr {
    return create_list();
}

fn free_stack(stack: ptr) {
    free_list(stack);
}

fn stack_push(stack: ptr, val: float) -> float {
    return list_push(stack, val);
}

fn stack_pop(stack: ptr) -> float {
    let len = list_len(stack);
    if (len <= 0.0) { return 0.0; }
    let val = list_get(stack, len - 1.0);
    stack[0] = len - 1.0;
    return val;
}

fn create_queue() -> ptr {
    var q = malloc(16384.0);
    if (q == 0.0) { return q; }
    q[0] = 0.0;    // head
    q[1] = 0.0;    // tail
    q[2] = 2000.0; // capacity
    return q;
}

fn free_queue(q: ptr) {
    if (q != 0.0) { free(q); }
}

fn queue_enqueue(q: ptr, val: float) -> float {
    if (q == 0.0) { return 0.0; }
    let tail = q[1];
    let cap = q[2];
    if (tail >= cap) { return tail - q[0]; } // bounds check
    q[3.0 + tail] = val;
    q[1] = tail + 1.0;
    return q[1] - q[0];
}

fn queue_dequeue(q: ptr) -> float {
    if (q == 0.0) { return 0.0; }
    let head = q[0];
    let tail = q[1];
    if (head >= tail) { return 0.0; }
    let val = q[3.0 + head];
    q[0] = head + 1.0;
    return val;
}


