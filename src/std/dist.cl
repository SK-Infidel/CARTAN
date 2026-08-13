// src/std/dist.cl
// CARTAN Standard Library: Distributed Multi-GPU Parallelism Engine

extern fn cartan_dist_init(world_size: float, rank: float) -> float;
extern fn cartan_dist_get_rank() -> float;
extern fn cartan_dist_get_world_size() -> float;
extern fn cartan_dist_all_reduce(tensor_ptr: ptr, op_id: float) -> float;
extern fn cartan_dist_broadcast(tensor_ptr: ptr, root_rank: float) -> float;
extern fn cartan_dist_barrier() -> float;

fn init(world_size: float, rank: float) -> float {
    return cartan_dist_init(world_size, rank);
}

fn get_rank() -> float {
    return cartan_dist_get_rank();
}

fn get_world_size() -> float {
    return cartan_dist_get_world_size();
}

fn all_reduce(tensor_ptr: ptr, op_id: float) -> float {
    return cartan_dist_all_reduce(tensor_ptr, op_id);
}

fn broadcast(tensor_ptr: ptr, root_rank: float) -> float {
    return cartan_dist_broadcast(tensor_ptr, root_rank);
}

fn barrier() -> float {
    return cartan_dist_barrier();
}
