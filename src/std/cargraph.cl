// src/std/cargraph.cl
// CARTAN Standard Library: Native .car_graph Flat Binary Storage Engine & Zero-Copy Loader
// Neuro-Symbolic Expert System (NSES) Phase 1 Core

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/fs.cl";

extern fn cartan_read_binary_file_data(path: string) -> ptr;
extern fn cartan_get_binary_file_size(path: string) -> float;
extern fn cartan_byte_at(buf: ptr, offset: float) -> float;
extern fn cartan_set_byte(buf: ptr, offset: float, val: float);
extern fn cartan_alloc_binary_buffer(size: float) -> ptr;
extern fn cartan_free_binary_buffer(buf: ptr);
extern fn cartan_write_binary_file(path: string, buf: ptr, size: float) -> float;
extern fn cartan_c_ptr_add(p: ptr, offset: float) -> ptr;
extern fn malloc(size: float) -> ptr;
extern fn free(p: ptr);

// --- Section & Layout Alignment Constants ---
// 64-byte Header Magic: "CARGRAPH" (ASCII: 67, 65, 82, 71, 82, 65, 80, 72)
fn cargraph_magic_byte(idx: float) -> float {
    if (idx == 0.0) { return 67.0; } // 'C'
    if (idx == 1.0) { return 65.0; } // 'A'
    if (idx == 2.0) { return 82.0; } // 'R'
    if (idx == 3.0) { return 71.0; } // 'G'
    if (idx == 4.0) { return 82.0; } // 'R'
    if (idx == 5.0) { return 65.0; } // 'A'
    if (idx == 6.0) { return 80.0; } // 'P'
    if (idx == 7.0) { return 72.0; } // 'H'
    return 0.0;
}

// 64-byte File Header Definition
struct CarGraphHeader {
    version: float;              // 1.0
    flags: float;                // 0.0 = FP64 Little-Endian
    file_size: float;            // Total bytes
    embedding_dim: float;        // 1536.0
    num_domains: float;          // Active domain count (Domain 0 + N)
    num_rules: float;            // Total rules
    num_strict_rules: float;     // Strict unbreachable guardrails
    num_edges: float;            // CSR edges count
    num_fragments: float;        // Burroughs fragment count
    offset_domains: float;       // Page-aligned (4096B) offset
    offset_rules: float;         // Rules section offset
    offset_csr_ptrs: float;      // CSR row pointers offset
    offset_csr_edges: float;     // CSR edge list offset
    offset_fragments: float;     // Burroughs fragments offset
    offset_embeddings: float;    // 64-byte cacheline aligned embeddings
    offset_string_pool: float;   // String pool offset
}

// 32-byte Rule Element Metadata
struct RuleElementMeta {
    element_id: float;
    domain_idx: float;           // 0 = SYSTEM_CORE, >= 1 = domain
    element_type: float;         // 0 = guardrail_hard, 1 = fact_grounding, 2 = episodic
    is_strict: float;            // 1.0 = strict invariant, 0.0 = associative
    string_offset: float;        // Offset in string pool
    string_len: float;           // Byte length of text
    embedding_idx: float;        // Vector index in embedding matrix
    flags: float;
}

// Domain Partition Metadata
struct DomainPartitionMeta {
    domain_id: float;            // 0 = SYSTEM_CORE
    rule_start_idx: float;
    rule_count: float;
    strict_count: float;
    name_offset: float;
    name_len: float;
}

// Dynamic Delta Arena 64-byte CAS Chunk
struct NSES_EdgeChunk {
    target_node_0: float;
    target_node_1: float;
    target_node_2: float;
    target_node_3: float;
    weight_0: float;
    weight_1: float;
    weight_2: float;
    weight_3: float;
    relation_0: float;
    relation_1: float;
    relation_2: float;
    relation_3: float;
    timestamp: float;
    next_chunk_offset: float;
}

// Loaded Zero-Copy Graph View
struct CarGraphFile {
    is_valid: float;
    raw_buffer: ptr;
    raw_size: float;
    header: CarGraphHeader;
    domains_ptr: ptr;
    rules_ptr: ptr;
    csr_ptrs: ptr;
    csr_edges: ptr;
    embeddings_ptr: ptr;
    string_pool_ptr: ptr;
}

// Structure-of-Arrays (SoA) In-Memory Builder for Native Flat Performance
struct CarGraphBuilder {
    embedding_dim: float;
    domain_ids: ptr;
    domain_rule_starts: ptr;
    domain_rule_counts: ptr;
    domain_strict_counts: ptr;
    rule_domain_indices: ptr;
    rule_element_types: ptr;
    rule_is_stricts: ptr;
    rule_strings: ptr;
    rule_embeddings: ptr;
    num_strict: float;
}

// Helper: 4096-byte page alignment calculation
fn cargraph_align_page(offset: float) -> float {
    let rem = math_mod_val(offset, 4096.0);
    if (rem == 0.0) { return offset; }
    return offset + (4096.0 - rem);
}

// Helper: 64-byte cacheline alignment calculation
fn cargraph_align_cacheline(offset: float) -> float {
    let rem = math_mod_val(offset, 64.0);
    if (rem == 0.0) { return offset; }
    return offset + (64.0 - rem);
}

// Helper: write 32-bit float/uint to buffer in Little-Endian
fn cargraph_write_u32(buf: ptr, offset: float, val: float) {
    let v_int = floor(val);
    let b0 = math_mod_val(v_int, 256.0);
    let b1 = math_mod_val(floor(v_int / 256.0), 256.0);
    let b2 = math_mod_val(floor(v_int / 65536.0), 256.0);
    let b3 = math_mod_val(floor(v_int / 16777216.0), 256.0);
    cartan_set_byte(buf, offset + 0.0, b0);
    cartan_set_byte(buf, offset + 1.0, b1);
    cartan_set_byte(buf, offset + 2.0, b2);
    cartan_set_byte(buf, offset + 3.0, b3);
}

// Helper: read 32-bit float/uint from buffer in Little-Endian
fn cargraph_read_u32(buf: ptr, offset: float) -> float {
    let b0 = cartan_byte_at(buf, offset + 0.0);
    let b1 = cartan_byte_at(buf, offset + 1.0);
    let b2 = cartan_byte_at(buf, offset + 2.0);
    let b3 = cartan_byte_at(buf, offset + 3.0);
    return b0 + (b1 * 256.0) + (b2 * 65536.0) + (b3 * 16777216.0);
}

// Helper: write 64-bit float/uint to buffer in Little-Endian (low + high u32)
fn cargraph_write_u64(buf: ptr, offset: float, val: float) {
    let low = math_mod_val(floor(val), 4294967296.0);
    let high = floor(val / 4294967296.0);
    cargraph_write_u32(buf, offset + 0.0, low);
    cargraph_write_u32(buf, offset + 4.0, high);
}

// Helper: read 64-bit float/uint from buffer in Little-Endian
fn cargraph_read_u64(buf: ptr, offset: float) -> float {
    let low = cargraph_read_u32(buf, offset + 0.0);
    let high = cargraph_read_u32(buf, offset + 4.0);
    return low + (high * 4294967296.0);
}

// Create a new CarGraphBuilder instance
fn cargraph_builder_create(embedding_dim: float) -> CarGraphBuilder {
    var dim = 1536.0;
    if (embedding_dim > 0.0) { dim = embedding_dim; }
    return CarGraphBuilder {
        embedding_dim: dim,
        domain_ids: collections_create_list(),
        domain_rule_starts: collections_create_list(),
        domain_rule_counts: collections_create_list(),
        domain_strict_counts: collections_create_list(),
        rule_domain_indices: collections_create_list(),
        rule_element_types: collections_create_list(),
        rule_is_stricts: collections_create_list(),
        rule_strings: cartan_tree_create(),
        rule_embeddings: cartan_tree_create(),
        num_strict: 0.0
    };
}

// Register a domain partition (Domain 0 = SYSTEM_CORE)
fn cargraph_builder_add_domain(b: CarGraphBuilder, domain_id: float, rule_start: float, rule_cnt: float, strict_cnt: float) -> float {
    collections_list_push(b.domain_ids, domain_id);
    collections_list_push(b.domain_rule_starts, rule_start);
    collections_list_push(b.domain_rule_counts, rule_cnt);
    collections_list_push(b.domain_strict_counts, strict_cnt);
    return collections_list_len(b.domain_ids);
}

// Add a rule element to builder
fn cargraph_builder_add_rule(b: CarGraphBuilder, domain_idx: float, elem_type: float, is_strict: float, text: string, emb_vec: ptr) -> float {
    let rule_id = collections_list_len(b.rule_domain_indices);
    if (is_strict > 0.0) {
        b.num_strict = b.num_strict + 1.0;
    }
    collections_list_push(b.rule_domain_indices, domain_idx);
    collections_list_push(b.rule_element_types, elem_type);
    collections_list_push(b.rule_is_stricts, is_strict);
    cartan_tree_push(b.rule_strings, text);
    cartan_tree_push(b.rule_embeddings, emb_vec);
    return rule_id;
}

// Serialize in-memory builder data into flat .car_graph binary file
fn cargraph_serialize_to_file(b: CarGraphBuilder, filepath: string) -> float {
    let num_domains = collections_list_len(b.domain_ids);
    let num_rules = collections_list_len(b.rule_domain_indices);
    let emb_dim = b.embedding_dim;

    // Compute layout offsets with 4096-byte section alignment and 64-byte vector alignment
    let off_header = 0.0;
    let hdr_size = 128.0; // 128 bytes reserved for header

    let off_domains = cargraph_align_page(hdr_size);
    let domains_size = num_domains * 32.0;

    let off_rules = cargraph_align_page(off_domains + domains_size);
    let rules_size = num_rules * 32.0;

    let off_csr_ptrs = cargraph_align_page(off_rules + rules_size);
    let off_csr_edges = cargraph_align_page(off_csr_ptrs + ((num_rules + 1.0) * 8.0));
    let off_fragments = cargraph_align_page(off_csr_edges + 64.0);

    // Embeddings matrix: 64-byte aligned (each vector = emb_dim * 8 bytes)
    let off_embeddings = cargraph_align_page(off_fragments + 64.0);
    let vec_bytes = emb_dim * 8.0;
    let embeddings_size = num_rules * vec_bytes;

    let off_string_pool = cargraph_align_page(off_embeddings + embeddings_size);

    // Calculate string pool size
    var str_pool_len = 0.0;
    var i = 0.0;
    while (i < num_rules) {
        let s = cartan_tree_get(b.rule_strings, i);
        str_pool_len = str_pool_len + cartan_string_length(s) + 1.0;
        i = i + 1.0;
    }
    let total_file_size = off_string_pool + str_pool_len + 64.0;

    // Allocate binary output buffer
    let raw = cartan_alloc_binary_buffer(total_file_size);
    if (raw == 0.0) { return 0.0; }

    // 1. Write Header Magic "CARGRAPH"
    var m_idx = 0.0;
    while (m_idx < 8.0) {
        cartan_set_byte(raw, m_idx, cargraph_magic_byte(m_idx));
        m_idx = m_idx + 1.0;
    }

    // Write Header fields
    cargraph_write_u32(raw, 8.0, 1.0);             // version = 1
    cargraph_write_u32(raw, 12.0, 0.0);            // flags = 0 (FP64 Little-Endian)
    cargraph_write_u64(raw, 16.0, total_file_size);
    cargraph_write_u32(raw, 24.0, emb_dim);
    cargraph_write_u32(raw, 28.0, num_domains);
    cargraph_write_u32(raw, 32.0, num_rules);
    cargraph_write_u32(raw, 36.0, b.num_strict);
    cargraph_write_u32(raw, 40.0, 0.0);            // num_edges
    cargraph_write_u32(raw, 44.0, 0.0);            // num_fragments
    cargraph_write_u64(raw, 48.0, off_domains);
    cargraph_write_u64(raw, 56.0, off_rules);
    cargraph_write_u64(raw, 64.0, off_csr_ptrs);
    cargraph_write_u64(raw, 72.0, off_csr_edges);
    cargraph_write_u64(raw, 80.0, off_fragments);
    cargraph_write_u64(raw, 88.0, off_embeddings);
    cargraph_write_u64(raw, 96.0, off_string_pool);

    // 2. Write Domains Section
    var d_i = 0.0;
    while (d_i < num_domains) {
        let d_id = collections_list_get(b.domain_ids, d_i);
        let d_start = collections_list_get(b.domain_rule_starts, d_i);
        let d_cnt = collections_list_get(b.domain_rule_counts, d_i);
        let d_strict = collections_list_get(b.domain_strict_counts, d_i);
        let d_off = off_domains + (d_i * 32.0);
        cargraph_write_u32(raw, d_off + 0.0, d_id);
        cargraph_write_u32(raw, d_off + 4.0, d_start);
        cargraph_write_u32(raw, d_off + 8.0, d_cnt);
        cargraph_write_u32(raw, d_off + 12.0, d_strict);
        cargraph_write_u32(raw, d_off + 16.0, 0.0);
        cargraph_write_u32(raw, d_off + 20.0, 0.0);
        d_i = d_i + 1.0;
    }

    // 3. Write Rules Section & String Pool
    var cur_str_off = off_string_pool;
    var r_i = 0.0;
    while (r_i < num_rules) {
        let d_idx = collections_list_get(b.rule_domain_indices, r_i);
        let e_type = collections_list_get(b.rule_element_types, r_i);
        let is_str = collections_list_get(b.rule_is_stricts, r_i);
        let s = cartan_tree_get(b.rule_strings, r_i);
        let s_len = cartan_string_length(s);
        let rel_str_off = cur_str_off - off_string_pool;

        // Write rule metadata (32 bytes)
        let r_off = off_rules + (r_i * 32.0);
        cargraph_write_u32(raw, r_off + 0.0, r_i);
        cargraph_write_u32(raw, r_off + 4.0, d_idx);
        cargraph_write_u32(raw, r_off + 8.0, e_type);
        cargraph_write_u32(raw, r_off + 12.0, is_str);
        cargraph_write_u32(raw, r_off + 16.0, rel_str_off);
        cargraph_write_u32(raw, r_off + 20.0, s_len);
        cargraph_write_u32(raw, r_off + 24.0, r_i);
        cargraph_write_u32(raw, r_off + 28.0, 0.0);

        // Copy string chars into string pool
        var c_idx = 0.0;
        while (c_idx < s_len) {
            let ch = c_cartan_string_char_at(s, c_idx);
            cartan_set_byte(raw, cur_str_off + c_idx, ch);
            c_idx = c_idx + 1.0;
        }
        cartan_set_byte(raw, cur_str_off + s_len, 0.0); // Null terminator
        cur_str_off = cur_str_off + s_len + 1.0;

        // 4. Write Embedding Vector into 64-byte aligned embedding matrix
        let emb_vec = cartan_tree_get(b.rule_embeddings, r_i);
        if (emb_vec != 0.0) {
            let vec_dst = cartan_c_ptr_add(raw, off_embeddings + (r_i * vec_bytes));
            cartan_c_memcpy(vec_dst, emb_vec, vec_bytes);
        }
        r_i = r_i + 1.0;
    }

    // Write binary buffer to file
    let write_ok = cartan_write_binary_file(filepath, raw, total_file_size);
    cartan_free_binary_buffer(raw);
    return write_ok;
}

// Returns an empty/invalid CarGraphFile view
fn cargraph_empty() -> CarGraphFile {
    return CarGraphFile {
        is_valid: 0.0,
        raw_buffer: 0.0,
        raw_size: 0.0,
        header: CarGraphHeader {
            version: 0.0, flags: 0.0, file_size: 0.0, embedding_dim: 0.0,
            num_domains: 0.0, num_rules: 0.0, num_strict_rules: 0.0,
            num_edges: 0.0, num_fragments: 0.0, offset_domains: 0.0,
            offset_rules: 0.0, offset_csr_ptrs: 0.0, offset_csr_edges: 0.0,
            offset_fragments: 0.0, offset_embeddings: 0.0, offset_string_pool: 0.0
        },
        domains_ptr: 0.0,
        rules_ptr: 0.0,
        csr_ptrs: 0.0,
        csr_edges: 0.0,
        embeddings_ptr: 0.0,
        string_pool_ptr: 0.0
    };
}

// Zero-copy binary file loader & validator
fn cargraph_load_binary(filepath: string) -> CarGraphFile {
    let invalid_view = cargraph_empty();

    let sz = cartan_get_binary_file_size(filepath);
    if (sz < 128.0) { return invalid_view; } // File too small for header

    let buf = cartan_read_binary_file_data(filepath);
    if (buf == 0.0) { return invalid_view; }

    // 1. Sanity check magic bytes "CARGRAPH"
    var m_i = 0.0;
    while (m_i < 8.0) {
        if (cartan_byte_at(buf, m_i) != cargraph_magic_byte(m_i)) {
            cartan_free_binary_buffer(buf);
            return invalid_view;
        }
        m_i = m_i + 1.0;
    }

    // 2. Parse Header fields
    let ver = cargraph_read_u32(buf, 8.0);
    if (ver != 1.0) {
        cartan_free_binary_buffer(buf);
        return invalid_view;
    }
    let flags = cargraph_read_u32(buf, 12.0);
    let f_size = cargraph_read_u64(buf, 16.0);
    if (f_size > sz) {
        cartan_free_binary_buffer(buf);
        return invalid_view;
    }
    let emb_dim = cargraph_read_u32(buf, 24.0);
    let n_domains = cargraph_read_u32(buf, 28.0);
    let n_rules = cargraph_read_u32(buf, 32.0);
    let n_strict = cargraph_read_u32(buf, 36.0);
    let n_edges = cargraph_read_u32(buf, 40.0);
    let n_frags = cargraph_read_u32(buf, 44.0);
    let off_domains = cargraph_read_u64(buf, 48.0);
    let off_rules = cargraph_read_u64(buf, 56.0);
    let off_csr_ptrs = cargraph_read_u64(buf, 64.0);
    let off_csr_edges = cargraph_read_u64(buf, 72.0);
    let off_fragments = cargraph_read_u64(buf, 80.0);
    let off_embeddings = cargraph_read_u64(buf, 88.0);
    let off_string_pool = cargraph_read_u64(buf, 96.0);

    // 3. Section bounds checking against buffer size
    if (off_domains >= sz || off_rules >= sz || off_embeddings >= sz || off_string_pool >= sz) {
        cartan_free_binary_buffer(buf);
        return invalid_view;
    }

    let hdr = CarGraphHeader {
        version: ver,
        flags: flags,
        file_size: f_size,
        embedding_dim: emb_dim,
        num_domains: n_domains,
        num_rules: n_rules,
        num_strict_rules: n_strict,
        num_edges: n_edges,
        num_fragments: n_frags,
        offset_domains: off_domains,
        offset_rules: off_rules,
        offset_csr_ptrs: off_csr_ptrs,
        offset_csr_edges: off_csr_edges,
        offset_fragments: off_fragments,
        offset_embeddings: off_embeddings,
        offset_string_pool: off_string_pool
    };

    return CarGraphFile {
        is_valid: 1.0,
        raw_buffer: buf,
        raw_size: sz,
        header: hdr,
        domains_ptr: cartan_c_ptr_add(buf, off_domains),
        rules_ptr: cartan_c_ptr_add(buf, off_rules),
        csr_ptrs: cartan_c_ptr_add(buf, off_csr_ptrs),
        csr_edges: cartan_c_ptr_add(buf, off_csr_edges),
        embeddings_ptr: cartan_c_ptr_add(buf, off_embeddings),
        string_pool_ptr: cartan_c_ptr_add(buf, off_string_pool)
    };
}

// Read Rule metadata record at index
fn cargraph_get_rule(cg: CarGraphFile, idx: float) -> RuleElementMeta {
    if (cg.is_valid == 0.0 || idx < 0.0 || idx >= cg.header.num_rules) {
        return RuleElementMeta {
            element_id: -1.0, domain_idx: 0.0, element_type: 0.0,
            is_strict: 0.0, string_offset: 0.0, string_len: 0.0,
            embedding_idx: 0.0, flags: 0.0
        };
    }
    let r_off = idx * 32.0;
    let r_buf = cg.rules_ptr;
    return RuleElementMeta {
        element_id: cargraph_read_u32(r_buf, r_off + 0.0),
        domain_idx: cargraph_read_u32(r_buf, r_off + 4.0),
        element_type: cargraph_read_u32(r_buf, r_off + 8.0),
        is_strict: cargraph_read_u32(r_buf, r_off + 12.0),
        string_offset: cargraph_read_u32(r_buf, r_off + 16.0),
        string_len: cargraph_read_u32(r_buf, r_off + 20.0),
        embedding_idx: cargraph_read_u32(r_buf, r_off + 24.0),
        flags: cargraph_read_u32(r_buf, r_off + 28.0)
    };
}

// Get string text for a rule
fn cargraph_get_rule_text(cg: CarGraphFile, idx: float) -> string {
    let r = cargraph_get_rule(cg, idx);
    if (r.element_id < 0.0) { return ""; }
    let s_ptr = cartan_c_ptr_add(cg.string_pool_ptr, r.string_offset);
    return s_ptr;
}

// Get direct pointer to 1536-D vector for a rule
fn cargraph_get_rule_embedding(cg: CarGraphFile, idx: float) -> ptr {
    if (cg.is_valid == 0.0 || idx < 0.0 || idx >= cg.header.num_rules) { return 0.0; }
    let vec_bytes = cg.header.embedding_dim * 8.0;
    return cartan_c_ptr_add(cg.embeddings_ptr, idx * vec_bytes);
}

// Free allocated binary file view
fn cargraph_free(cg: CarGraphFile) {
    if (cg.raw_buffer != 0.0) {
        cartan_free_binary_buffer(cg.raw_buffer);
    }
}
