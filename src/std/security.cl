// src/std/security.cl
// CARTAN Standard Library: SWMR Memory Fences & VRAM Write-Lock Sandboxing

fn vram_lock_parameters() -> void {
    cartan_rt_vram_lock_parameters();
}

fn vram_unlock_parameters() -> void {
    cartan_rt_vram_unlock_parameters();
}

fn check_vram_access(ptr_val: float, is_write: float) -> float {
    return cartan_rt_check_vram_access(ptr_val, is_write);
}

fn lock_swmr(ptr_val: float, read_only: float) -> float {
    return cartan_rt_lock_swmr(ptr_val, read_only);
}

fn unlock_swmr(ptr_val: float) -> void {
    cartan_rt_unlock_swmr(ptr_val);
}
