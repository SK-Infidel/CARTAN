struct DistributedContext {
    world_size: float;
    rank: float;
}

var g_distributed_world_size = 1.0;
var g_distributed_rank = 0.0;

fn dist_init(world_size: float, rank: float) -> float {
    if (world_size > 0.0) {
        g_distributed_world_size = world_size;
    }
    if (rank >= 0.0) {
        g_distributed_rank = rank;
    }
    return 0.0;
}

fn dist_get_rank() -> float {
    return g_distributed_rank;
}

fn dist_get_world_size() -> float {
    return g_distributed_world_size;
}

fn dist_all_reduce_sum(tensor_data: ptr, size: float) -> float {
    return 0.0;
}

fn dist_broadcast(tensor_data: ptr, size: float, root_rank: float) -> float {
    return 0.0;
}

fn dist_barrier() -> float {
    return 0.0;
}

fn cartan_dist_init(world_size: float, rank: float) -> float {
    return dist_init(world_size, rank);
}

fn cartan_dist_get_rank() -> float {
    return dist_get_rank();
}

fn cartan_dist_get_world_size() -> float {
    return dist_get_world_size();
}

fn cartan_dist_all_reduce(tensor_ptr: ptr, op_id: float) -> float {
    return dist_all_reduce_sum(tensor_ptr, 0.0);
}

fn cartan_dist_broadcast(tensor_ptr: ptr, root_rank: float) -> float {
    return dist_broadcast(tensor_ptr, 0.0, root_rank);
}

fn cartan_dist_barrier() -> float {
    return dist_barrier();
}

