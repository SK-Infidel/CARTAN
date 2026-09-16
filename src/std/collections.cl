// src/std/collections.cl
// CARTAN Standard Library: Layer 1 Generic Collections & Data Structures Module

extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr);
extern fn cartan_vec_create() -> ptr;
extern fn cartan_vec_push_f32(v: ptr, val: float) -> float;
extern fn cartan_vec_get_f32(v: ptr, idx: float) -> float;
extern fn cartan_vec_set_f32(v: ptr, idx: float, val: float) -> float;
extern fn cartan_vec_len(v: ptr) -> float;
extern fn cartan_vec_pop_f32(v: ptr) -> float;
extern fn cartan_vec_clear(v: ptr) -> float;
extern fn cartan_vec_free(v: ptr) -> float;
extern fn cartan_queue_create() -> ptr;
extern fn cartan_queue_enqueue(q: ptr, val: float) -> float;
extern fn cartan_queue_dequeue(q: ptr) -> float;

fn create_list() -> ptr {
    return cartan_vec_create();
}

fn free_list(list: ptr) {
    if (list != 0.0) { free(list); }
}

fn list_push(list: ptr, val: float) -> float {
    return cartan_vec_push_f32(list, val);
}

fn list_get(list: ptr, idx: float) -> float {
    return cartan_vec_get_f32(list, idx);
}

fn list_len(list: ptr) -> float {
    return cartan_vec_len(list);
}

fn create_stack() -> ptr {
    return cartan_vec_create();
}

fn free_stack(stack: ptr) {
    if (stack != 0.0) { free(stack); }
}

fn stack_push(stack: ptr, val: float) -> float {
    return cartan_vec_push_f32(stack, val);
}

fn stack_pop(stack: ptr) -> float {
    return cartan_vec_pop_f32(stack);
}

fn create_queue() -> ptr {
    return cartan_queue_create();
}

fn free_queue(q: ptr) {
    if (q != 0.0) { free(q); }
}

fn queue_enqueue(q: ptr, val: float) -> float {
    return cartan_queue_enqueue(q, val);
}

fn queue_dequeue(q: ptr) -> float {
    return cartan_queue_dequeue(q);
}

// Module prefixed aliases
fn collections_create_list() -> ptr { return create_list(); }
fn collections_free_list(list: ptr) { free_list(list); }
fn collections_list_push(list: ptr, val: float) -> float { return list_push(list, val); }
fn collections_list_get(list: ptr, idx: float) -> float { return list_get(list, idx); }
fn collections_list_len(list: ptr) -> float { return list_len(list); }

fn collections_create_stack() -> ptr { return create_stack(); }
fn collections_free_stack(stack: ptr) { free_stack(stack); }
fn collections_stack_push(stack: ptr, val: float) -> float { return stack_push(stack, val); }
fn collections_stack_pop(stack: ptr) -> float { return stack_pop(stack); }

fn collections_create_queue() -> ptr { return create_queue(); }
fn collections_free_queue(q: ptr) { free_queue(q); }
fn collections_queue_enqueue(q: ptr, val: float) -> float { return queue_enqueue(q, val); }
fn collections_queue_dequeue(q: ptr) -> float { return queue_dequeue(q); }





