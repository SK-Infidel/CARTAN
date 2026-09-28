// src/std/sqlite_vec.cl
// CARTAN Standard Library: Embedded SQLite-Vec Tier 2 Cognitive Memory Engine
// Neuro-Symbolic Expert System (NSES) Two-Tier Memory Substrate

include "src/std/math.cl";
include "src/std/collections.cl";
include "src/std/string.cl";
include "src/std/cargraph.cl";

extern fn cartan_sqlite_open(path: string) -> ptr;
extern fn cartan_sqlite_close(db: ptr) -> float;
extern fn cartan_sqlite_exec(db: ptr, sql: string) -> float;
extern fn cartan_sqlite_prepare(db: ptr, sql: string) -> ptr;
extern fn cartan_sqlite_step(stmt: ptr) -> float;
extern fn cartan_sqlite_column_text(stmt: ptr, col: float) -> string;
extern fn cartan_sqlite_column_double(stmt: ptr, col: float) -> float;
extern fn cartan_sqlite_finalize(stmt: ptr) -> float;
extern fn cartan_sqlite_errmsg(db: ptr) -> string;

extern fn cartan_sqlite_init_schema(db: ptr) -> float;
extern fn cartan_sqlite_upsert_domain(db: ptr, domain_id: float, name: string, desc: string) -> float;
extern fn cartan_sqlite_upsert_entity_state(db: ptr, domain_id: float, entity: string, attr: string, val: string, conf: float) -> float;
extern fn cartan_sqlite_upsert_rule(db: ptr, elem_id: float, domain_id: float, elem_type: string, content: string, is_strict: float, conf: float) -> float;
extern fn cartan_sqlite_add_dependency(db: ptr, src_id: float, tgt_id: float, rel_type: string, weight: float) -> float;
extern fn cartan_sqlite_add_randomicity_fragment(db: ptr, domain_id: float, text: string, entropy: float) -> float;
extern fn cartan_sqlite_add_episode(db: ptr, session_id: string, domain_id: float, speaker: string, content: string) -> float;
extern fn cartan_sqlite_get_entity_state(db: ptr, domain_id: float, entity: string, attr: string) -> string;
extern fn cartan_sqlite_get_rule_count(db: ptr, domain_id: float) -> float;
extern fn cartan_sqlite_get_entity_count(db: ptr, domain_id: float) -> float;
extern fn cartan_sqlite_prepare_domain_rules(db: ptr, domain_id: float) -> ptr;
extern fn cartan_sqlite_prepare_domain_entities(db: ptr, domain_id: float) -> ptr;
extern fn cartan_sqlite_get_unconsolidated_count(db: ptr, domain_id: float) -> float;
extern fn cartan_sqlite_consolidate_unprocessed_episodes(db: ptr, domain_id: float) -> float;
extern fn cartan_sqlite_supersede_rule(db: ptr, old_elem_id: float, new_elem_id: float) -> float;
extern fn cartan_sqlite_apply_ebbinghaus_decay(db: ptr, domain_id: float, min_confidence_thresh: float) -> float;
extern fn cartan_sqlite_flush_hebbian_weight(db: ptr, src_id: float, tgt_id: float, weight: float) -> float;

// Open embedded SQLite database file (or ":memory:")
fn sqlite_vec_open(filepath: string) -> ptr {
    return cartan_sqlite_open(filepath);
}

// Close embedded SQLite database
fn sqlite_vec_close(db: ptr) -> float {
    if (db == 0.0) { return 0.0; }
    let rc = cartan_sqlite_close(db);
    if (rc == 0.0) { return 1.0; }
    return 0.0;
}

// Execute arbitrary SQL statement
fn sqlite_vec_exec(db: ptr, sql: string) -> float {
    if (db == 0.0) { return 0.0; }
    let rc = cartan_sqlite_exec(db, sql);
    if (rc == 0.0) { return 1.0; }
    return 0.0;
}

// Initialize the 6-table Cognitive Memory Schema
fn sqlite_vec_init_schema(db: ptr) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_init_schema(db);
}

// Upsert a domain record
fn sqlite_vec_upsert_domain(db: ptr, domain_id: float, name: string, desc: string) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_upsert_domain(db, domain_id, name, desc);
}

// Upsert an active entity state
fn sqlite_vec_upsert_entity_state(db: ptr, domain_id: float, entity_name: string, attr_name: string, attr_val: string, confidence: float) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_upsert_entity_state(db, domain_id, entity_name, attr_name, attr_val, confidence);
}

// Upsert a semantic or guardrail rule element
fn sqlite_vec_upsert_rule(db: ptr, element_id: float, domain_id: float, elem_type: string, content: string, is_strict: float, conf: float) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_upsert_rule(db, element_id, domain_id, elem_type, content, is_strict, conf);
}

// Add a dependency causal edge
fn sqlite_vec_add_dependency(db: ptr, src_id: float, tgt_id: float, rel_type: string, weight: float) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_add_dependency(db, src_id, tgt_id, rel_type, weight);
}

// Add a Burroughs randomicity fragment
fn sqlite_vec_add_randomicity_fragment(db: ptr, domain_id: float, text: string, entropy: float) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_add_randomicity_fragment(db, domain_id, text, entropy);
}

// Add an episodic conversation turn
fn sqlite_vec_add_episode(db: ptr, session_id: string, domain_id: float, speaker: string, content: string) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_add_episode(db, session_id, domain_id, speaker, content);
}

// Query an active entity state attribute value
fn sqlite_vec_get_entity_state(db: ptr, domain_id: float, entity_name: string, attr_name: string) -> string {
    if (db == 0.0) { return ""; }
    return cartan_sqlite_get_entity_state(db, domain_id, entity_name, attr_name);
}

// Query count of active rules in a domain
fn sqlite_vec_get_rule_count(db: ptr, domain_id: float) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_get_rule_count(db, domain_id);
}

// Query count of active entity states in a domain
fn sqlite_vec_get_entity_count(db: ptr, domain_id: float) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_get_entity_count(db, domain_id);
}

// Phase A Two-Way Sync Bridge: Materialize active domain rules & entity states from Tier 2 DB into Tier 1 .car_graph v2 binary file
fn sqlite_vec_materialize_to_cargraph(db: ptr, domain_id: float, out_path: string) -> float {
    if (db == 0.0) { return 0.0; }

    let b = cargraph_builder_create(1536.0);

    // 1. Fetch domain rules via prepared statement
    let stmt = cartan_sqlite_prepare_domain_rules(db, domain_id);
    var rule_cnt = 0.0;
    var strict_cnt = 0.0;

    if (stmt != 0.0) {
        while (cartan_sqlite_step(stmt) == 100.0) {
            let is_str = cartan_sqlite_column_double(stmt, 3.0);
            let content = cartan_sqlite_column_text(stmt, 4.0);
            let e_type_str = cartan_sqlite_column_text(stmt, 2.0);
            var e_type = 1.0; // fact_grounding
            if (cartan_string_contains(e_type_str, "guardrail") != 0.0) { e_type = 0.0; }
            if (is_str > 0.0) { strict_cnt = strict_cnt + 1.0; }

            cargraph_builder_add_rule(b, domain_id, e_type, is_str, content, 0.0);
            rule_cnt = rule_cnt + 1.0;
        }
        cartan_sqlite_finalize(stmt);
    }

    // Register domain partition
    cargraph_builder_add_domain(b, domain_id, 0.0, rule_cnt, strict_cnt);

    // 2. Fetch active entity states via prepared statement
    let e_stmt = cartan_sqlite_prepare_domain_entities(db, domain_id);
    if (e_stmt != 0.0) {
        while (cartan_sqlite_step(e_stmt) == 100.0) {
            let ent_name = cartan_sqlite_column_text(e_stmt, 1.0);
            let ent_attr = cartan_sqlite_column_text(e_stmt, 2.0);
            let ent_val = cartan_sqlite_column_text(e_stmt, 3.0);
            let ent_conf = cartan_sqlite_column_double(e_stmt, 4.0);
            cargraph_builder_add_entity(b, domain_id, ent_name, ent_attr, ent_val, ent_conf);
        }
        cartan_sqlite_finalize(e_stmt);
    }

    // 3. Serialize to .car_graph v2 with strict 64-byte alignment
    let ok = cargraph_serialize_to_file(b, out_path);
    cargraph_builder_free(b);
    return ok;
}

// Query count of unconsolidated episodes in a domain
fn sqlite_vec_get_unconsolidated_count(db: ptr, domain_id: float) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_get_unconsolidated_count(db, domain_id);
}

// Consolidate unprocessed episodes into rule_elements and mark consolidated
fn sqlite_vec_consolidate_episodes(db: ptr, domain_id: float) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_consolidate_unprocessed_episodes(db, domain_id);
}

// Mark an old belief as superseded and link superseding dependency
fn sqlite_vec_supersede_rule(db: ptr, old_elem_id: float, new_elem_id: float) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_supersede_rule(db, old_elem_id, new_elem_id);
}

// Apply Ebbinghaus synaptic decay to non-strict rules and prune low confidence
fn sqlite_vec_apply_ebbinghaus_decay(db: ptr, domain_id: float, min_confidence_thresh: float) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_apply_ebbinghaus_decay(db, domain_id, min_confidence_thresh);
}

// Flush Hebbian dynamic CSR weight back to dependencies table
fn sqlite_vec_flush_hebbian_weight(db: ptr, src_id: float, tgt_id: float, weight: float) -> float {
    if (db == 0.0) { return 0.0; }
    return cartan_sqlite_flush_hebbian_weight(db, src_id, tgt_id, weight);
}

