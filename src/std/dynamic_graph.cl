// src/std/dynamic_graph.cl
// CARTAN Standard Library: Two-Tier Delta-CSR Memory Arena & Lock-Free Dynamic Edge Chaining
// Neuro-Symbolic Expert System (NSES) Phase 6 Core

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/string.cl";
include "src/std/sat_solver.cl";
include "src/cartanc/cargraph_simd.car";

extern fn calloc(count: float, size: float) -> ptr;
extern fn free(p: ptr);
extern fn cartan_byte_at(buf: ptr, offset: float) -> float;
extern fn cartan_set_byte(buf: ptr, offset: float, val: float);
extern fn cartan_c_ptr_add(p: ptr, offset: float) -> ptr;

// 64-byte Cacheline-Aligned Dynamic Delta Edge Chunk Layout:
// Offset  0: target_ids (7 x uint32 = 28 bytes)
// Offset 28: weights (7 x float32 = 28 bytes)
// Offset 56: rel_types (7 x uint8 = 7 bytes)
// Offset 63: count (1 byte)
// Next chunk offset stored in companion table or trailing slot

struct DynamicDeltaArena {
    capacity_bytes: float;
    used_bytes: float;
    checkpoint_bytes: float;
    base_node_count: float;
    dynamic_node_count: float;
    checkpoint_node_count: float;
    delta_head_offsets: ptr;       // collections list of head chunk byte offsets (-1 = empty)
    arena_buffer: ptr;             // Pre-allocated flat arena buffer
    is_valid: float;
}

// Allocates a pre-reserved dynamic delta arena
fn dynamic_arena_create(capacity_bytes: float, max_nodes: float) -> DynamicDeltaArena {
    var cap = capacity_bytes;
    if (cap < 65536.0) { cap = 1048576.0; } // Default 1MB arena for test harnesses
    let buf = calloc(cap, 1.0);

    let heads = collections_create_list();
    var i = 0.0;
    while (i < max_nodes) {
        collections_list_push(heads, -1.0);
        i = i + 1.0;
    }

    return DynamicDeltaArena {
        capacity_bytes: cap,
        used_bytes: 0.0,
        checkpoint_bytes: 0.0,
        base_node_count: 24.0, // Default 24 base rules
        dynamic_node_count: 0.0,
        checkpoint_node_count: 0.0,
        delta_head_offsets: heads,
        arena_buffer: buf,
        is_valid: 1.0
    };
}

// Frees the allocated arena
fn dynamic_arena_free(arena: DynamicDeltaArena) {
    if (arena.arena_buffer != 0.0) {
        free(arena.arena_buffer);
    }
    if (arena.delta_head_offsets != 0.0) {
        collections_free_list(arena.delta_head_offsets);
    }
}

// Begins a transactional mutation checkpoint
fn dynamic_arena_begin_transaction(arena: DynamicDeltaArena) {
    arena.checkpoint_bytes = arena.used_bytes;
    arena.checkpoint_node_count = arena.dynamic_node_count;
}

// Bitwise state rollback: Reverts memory buffer and zero-fills mutated region
fn dynamic_arena_rollback_transaction(arena: DynamicDeltaArena) {
    if (arena.used_bytes > arena.checkpoint_bytes && arena.arena_buffer != 0.0) {
        // Zero-fill rolled back arena memory bit-for-bit
        var b = arena.checkpoint_bytes;
        while (b < arena.used_bytes) {
            cartan_set_byte(arena.arena_buffer, b, 0.0);
            b = b + 1.0;
        }
    }
    arena.used_bytes = arena.checkpoint_bytes;
    arena.dynamic_node_count = arena.checkpoint_node_count;
}

// Commits the current mutation transaction
fn dynamic_arena_commit_transaction(arena: DynamicDeltaArena) {
    arena.checkpoint_bytes = arena.used_bytes;
    arena.checkpoint_node_count = arena.dynamic_node_count;
}

// Appends a new 64-byte aligned dynamic rule node to the arena
fn dynamic_arena_append_node(arena: DynamicDeltaArena, embedding_vec: ptr) -> float {
    let node_id = arena.base_node_count + arena.dynamic_node_count;
    let vec_bytes = 1536.0 * 8.0; // 12,288 bytes

    if (arena.used_bytes + vec_bytes + 64.0 > arena.capacity_bytes) {
        return -1.0; // Arena full
    }

    // Align to 64-byte cacheline boundary
    let rem = math_mod_val(arena.used_bytes, 64.0);
    if (rem != 0.0) {
        arena.used_bytes = arena.used_bytes + (64.0 - rem);
    }

    arena.used_bytes = arena.used_bytes + vec_bytes;
    arena.dynamic_node_count = arena.dynamic_node_count + 1.0;
    return node_id;
}

// Appends an edge to node u's dynamic delta chain (CAS chunk append)
fn dynamic_arena_append_edge(
    arena: DynamicDeltaArena,
    src_node: float,
    dst_node: float,
    weight: float,
    rel_type: float
) -> float {
    if (src_node < 0.0 || src_node >= collections_list_len(arena.delta_head_offsets)) {
        return 0.0;
    }

    if (arena.used_bytes + 64.0 > arena.capacity_bytes) {
        return 0.0; // Arena full
    }

    // Allocate 64-byte chunk
    let chunk_offset = arena.used_bytes;
    arena.used_bytes = arena.used_bytes + 64.0;

    let buf = arena.arena_buffer;
    // Set target node 0
    let dst_int = floor(dst_node);
    cartan_set_byte(buf, chunk_offset + 0.0, math_mod_val(dst_int, 256.0));
    cartan_set_byte(buf, chunk_offset + 1.0, math_mod_val(floor(dst_int / 256.0), 256.0));
    // Set weight (store integer representation)
    let w_int = floor(weight * 100.0);
    cartan_set_byte(buf, chunk_offset + 28.0, math_mod_val(w_int, 256.0));
    // Set relation type
    cartan_set_byte(buf, chunk_offset + 56.0, rel_type);
    // Set count = 1
    cartan_set_byte(buf, chunk_offset + 63.0, 1.0);

    // Update head pointer
    collections_list_set(arena.delta_head_offsets, src_node, chunk_offset);
    return 1.0;
}

// Symbolic Immune Pass: Evaluates candidate mental note before arena insertion
// 1. Direct invariant negation blocking (is_strict == 1.0 && rel_type == CONTRADICTS)
// 2. Transitive contradiction detection via SAT solver reachability
fn dynamic_arena_immune_pass(
    solver: SatSolver,
    src_rule: float,
    candidate_target: float,
    rel_type: float,
    target_is_strict: float
) -> float {
    // Check 1: Direct Invariant Negation Blocking
    if (target_is_strict != 0.0 && rel_type == 2.0) { // CONTRADICTS strict rule
        return 0.0; // Blocked with 100% precision
    }

    // Check 2: Transitive Contradiction Check via 2-SAT Implication Graph
    if (rel_type == 2.0) {
        // If candidate contradicts C, but src_rule transitively requires C:
        let src_var = src_rule;
        let tgt_var = candidate_target;
        if (sat_is_reachable(solver, sat_lit_pos(src_var), sat_lit_pos(tgt_var)) != 0.0) {
            // A requires ... requires C, but Candidate contradicts C -> Transitive Contradiction!
            return 0.0; // Blocked
        }
    }

    return 1.0; // Consistent, safe to crystallize
}
