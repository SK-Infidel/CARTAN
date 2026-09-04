// src/std/async.cl
// CARTAN Standard Library: Async/Await Coroutines & Event Loop Primitives

fn async_spawn(task: ptr) -> float {
    return cartan_async_spawn(task);
}

fn async_yield() -> float {
    return cartan_async_yield();
}

fn async_await(task_id: float) -> float {
    return cartan_async_await(task_id);
}
