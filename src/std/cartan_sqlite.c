// src/std/cartan_sqlite.c
// Embedded SQLite C-FFI Bridge for CARTAN Runtime & GeoMind Cognitive Memory

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Forward declare SQLite3 C API types & functions from winsqlite3
typedef struct sqlite3 sqlite3;
typedef struct sqlite3_stmt sqlite3_stmt;

typedef void (*sqlite3_destructor_type)(void*);
#define SQLITE_STATIC_DESTRUCTOR    ((sqlite3_destructor_type)0)
#define SQLITE_TRANSIENT_DESTRUCTOR ((sqlite3_destructor_type)-1)

extern int sqlite3_open(const char *filename, sqlite3 **ppDb);
extern int sqlite3_close(sqlite3 *db);
extern int sqlite3_exec(sqlite3 *db, const char *sql, int (*callback)(void*,int,char**,char**), void *arg, char **errmsg);
extern int sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail);
extern int sqlite3_step(sqlite3_stmt *pStmt);
extern int sqlite3_finalize(sqlite3_stmt *pStmt);
extern int sqlite3_reset(sqlite3_stmt *pStmt);
extern int sqlite3_bind_int64(sqlite3_stmt *pStmt, int iCol, long long iValue);
extern int sqlite3_bind_double(sqlite3_stmt *pStmt, int iCol, double rValue);
extern int sqlite3_bind_text(sqlite3_stmt *pStmt, int iCol, const char *zData, int nData, sqlite3_destructor_type xDel);
extern const unsigned char *sqlite3_column_text(sqlite3_stmt *pStmt, int iCol);
extern double sqlite3_column_double(sqlite3_stmt *pStmt, int iCol);
extern int sqlite3_column_int(sqlite3_stmt *pStmt, int iCol);
extern const char *sqlite3_errmsg(sqlite3 *db);

void* cartan_sqlite_open(const char* path) {
    if (!path) return NULL;
    sqlite3* db = NULL;
    int rc = sqlite3_open(path, &db);
    if (rc != 0) {
        if (db) sqlite3_close(db);
        return NULL;
    }
    return (void*)db;
}

double cartan_sqlite_close(void* db) {
    if (!db) return 0.0;
    int rc = sqlite3_close((sqlite3*)db);
    return (double)rc;
}

double cartan_sqlite_exec(void* db, const char* sql) {
    if (!db || !sql) return -1.0;
    int rc = sqlite3_exec((sqlite3*)db, sql, NULL, NULL, NULL);
    return (double)rc;
}

void* cartan_sqlite_prepare(void* db, const char* sql) {
    if (!db || !sql) return NULL;
    sqlite3_stmt* stmt = NULL;
    int rc = sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL);
    if (rc != 0) return NULL;
    return (void*)stmt;
}

double cartan_sqlite_step(void* stmt) {
    if (!stmt) return -1.0;
    int rc = sqlite3_step((sqlite3_stmt*)stmt);
    return (double)rc;
}

const char* cartan_sqlite_column_text(void* stmt, double col) {
    if (!stmt) return "";
    const unsigned char* text = sqlite3_column_text((sqlite3_stmt*)stmt, (int)col);
    if (!text) return "";
    size_t len = strlen((const char*)text);
    char* copy = (char*)malloc(len + 1);
    if (!copy) return "";
    memcpy(copy, text, len + 1);
    return copy;
}

double cartan_sqlite_column_double(void* stmt, double col) {
    if (!stmt) return 0.0;
    return sqlite3_column_double((sqlite3_stmt*)stmt, (int)col);
}

double cartan_sqlite_finalize(void* stmt) {
    if (!stmt) return 0.0;
    int rc = sqlite3_finalize((sqlite3_stmt*)stmt);
    return (double)rc;
}

const char* cartan_sqlite_errmsg(void* db) {
    if (!db) return "";
    const char* msg = sqlite3_errmsg((sqlite3*)db);
    if (!msg) return "";
    return msg;
}

// -------------------------------------------------------------------------
// 6-Table Cognitive Memory Substrate C Operations
// -------------------------------------------------------------------------

double cartan_sqlite_init_schema(void* db) {
    if (!db) return 0.0;
    const char* schema =
        "CREATE TABLE IF NOT EXISTS domains ("
        "  domain_id INTEGER PRIMARY KEY, "
        "  name TEXT UNIQUE NOT NULL, "
        "  description TEXT, "
        "  is_active INTEGER DEFAULT 1, "
        "  created_at DATETIME DEFAULT CURRENT_TIMESTAMP"
        ");"
        "CREATE TABLE IF NOT EXISTS rule_elements ("
        "  element_id INTEGER PRIMARY KEY, "
        "  domain_id INTEGER, "
        "  element_type TEXT NOT NULL, "
        "  content TEXT NOT NULL, "
        "  is_strict INTEGER DEFAULT 0, "
        "  confidence REAL DEFAULT 1.0, "
        "  status TEXT DEFAULT 'active', "
        "  access_count INTEGER DEFAULT 0, "
        "  created_at DATETIME DEFAULT CURRENT_TIMESTAMP, "
        "  last_accessed_at DATETIME DEFAULT CURRENT_TIMESTAMP, "
        "  decay_half_life_days REAL DEFAULT 30.0"
        ");"
        "CREATE TABLE IF NOT EXISTS dependencies ("
        "  dependency_id INTEGER PRIMARY KEY, "
        "  source_element_id INTEGER, "
        "  target_element_id INTEGER, "
        "  relationship_type TEXT NOT NULL, "
        "  weight REAL DEFAULT 1.0, "
        "  last_traversed DATETIME DEFAULT CURRENT_TIMESTAMP, "
        "  UNIQUE(source_element_id, target_element_id, relationship_type)"
        ");"
        "CREATE TABLE IF NOT EXISTS randomicity_fragments ("
        "  fragment_id INTEGER PRIMARY KEY, "
        "  domain_id INTEGER, "
        "  fragment_text TEXT NOT NULL, "
        "  entropy_tier INTEGER DEFAULT 1, "
        "  usage_count INTEGER DEFAULT 0"
        ");"
        "CREATE TABLE IF NOT EXISTS episodes ("
        "  episode_id INTEGER PRIMARY KEY, "
        "  session_id TEXT NOT NULL, "
        "  domain_id INTEGER, "
        "  speaker TEXT NOT NULL, "
        "  content TEXT NOT NULL, "
        "  consolidated INTEGER DEFAULT 0, "
        "  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP"
        ");"
        "CREATE TABLE IF NOT EXISTS entity_states ("
        "  state_id INTEGER PRIMARY KEY, "
        "  domain_id INTEGER, "
        "  entity_name TEXT NOT NULL, "
        "  attribute_name TEXT NOT NULL, "
        "  attribute_value TEXT NOT NULL, "
        "  confidence REAL DEFAULT 1.0, "
        "  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP, "
        "  UNIQUE(domain_id, entity_name, attribute_name)"
        ");";

    int rc = sqlite3_exec((sqlite3*)db, schema, NULL, NULL, NULL);
    return (rc == 0) ? 1.0 : 0.0;
}

double cartan_sqlite_upsert_domain(void* db, double domain_id, const char* name, const char* desc) {
    if (!db || !name) return 0.0;
    const char* sql = "INSERT INTO domains (domain_id, name, description, is_active) VALUES (?, ?, ?, 1) "
                      "ON CONFLICT(name) DO UPDATE SET description = excluded.description, is_active = 1;";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_int64(stmt, 1, (long long)domain_id);
    sqlite3_bind_text(stmt, 2, name, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    sqlite3_bind_text(stmt, 3, desc ? desc : "", -1, SQLITE_TRANSIENT_DESTRUCTOR);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return (rc == 101) ? 1.0 : 0.0; // 101 == SQLITE_DONE
}

double cartan_sqlite_upsert_entity_state(void* db, double domain_id, const char* entity, const char* attr, const char* val, double conf) {
    if (!db || !entity || !attr || !val) return 0.0;
    const char* sql = "INSERT INTO entity_states (domain_id, entity_name, attribute_name, attribute_value, confidence, updated_at) "
                      "VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP) "
                      "ON CONFLICT(domain_id, entity_name, attribute_name) DO UPDATE SET "
                      "attribute_value = excluded.attribute_value, confidence = excluded.confidence, updated_at = CURRENT_TIMESTAMP;";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_int64(stmt, 1, (long long)domain_id);
    sqlite3_bind_text(stmt, 2, entity, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    sqlite3_bind_text(stmt, 3, attr, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    sqlite3_bind_text(stmt, 4, val, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    sqlite3_bind_double(stmt, 5, conf);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return (rc == 101) ? 1.0 : 0.0;
}

double cartan_sqlite_upsert_rule(void* db, double elem_id, double domain_id, const char* elem_type, const char* content, double is_strict, double conf) {
    if (!db || !elem_type || !content) return 0.0;
    const char* sql = "INSERT INTO rule_elements (element_id, domain_id, element_type, content, is_strict, confidence, status) "
                      "VALUES (?, ?, ?, ?, ?, ?, 'active');";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_int64(stmt, 1, (long long)elem_id);
    sqlite3_bind_int64(stmt, 2, (long long)domain_id);
    sqlite3_bind_text(stmt, 3, elem_type, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    sqlite3_bind_text(stmt, 4, content, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    sqlite3_bind_int64(stmt, 5, (long long)is_strict);
    sqlite3_bind_double(stmt, 6, conf);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return (rc == 101) ? 1.0 : 0.0;
}

double cartan_sqlite_add_dependency(void* db, double src_id, double tgt_id, const char* rel_type, double weight) {
    if (!db || !rel_type) return 0.0;
    const char* sql = "INSERT OR REPLACE INTO dependencies (source_element_id, target_element_id, relationship_type, weight, last_traversed) "
                      "VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP);";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_int64(stmt, 1, (long long)src_id);
    sqlite3_bind_int64(stmt, 2, (long long)tgt_id);
    sqlite3_bind_text(stmt, 3, rel_type, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    sqlite3_bind_double(stmt, 4, weight);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return (rc == 101) ? 1.0 : 0.0;
}

double cartan_sqlite_add_randomicity_fragment(void* db, double domain_id, const char* text, double entropy) {
    if (!db || !text) return 0.0;
    const char* sql = "INSERT INTO randomicity_fragments (domain_id, fragment_text, entropy_tier) VALUES (?, ?, ?);";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_int64(stmt, 1, (long long)domain_id);
    sqlite3_bind_text(stmt, 2, text, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    sqlite3_bind_int64(stmt, 3, (long long)entropy);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return (rc == 101) ? 1.0 : 0.0;
}

double cartan_sqlite_add_episode(void* db, const char* session_id, double domain_id, const char* speaker, const char* content) {
    if (!db || !session_id || !speaker || !content) return 0.0;
    const char* sql = "INSERT INTO episodes (session_id, domain_id, speaker, content, consolidated) VALUES (?, ?, ?, ?, 0);";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_text(stmt, 1, session_id, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    sqlite3_bind_int64(stmt, 2, (long long)domain_id);
    sqlite3_bind_text(stmt, 3, speaker, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    sqlite3_bind_text(stmt, 4, content, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return (rc == 101) ? 1.0 : 0.0;
}

const char* cartan_sqlite_get_entity_state(void* db, double domain_id, const char* entity, const char* attr) {
    if (!db || !entity || !attr) return "";
    const char* sql = "SELECT attribute_value FROM entity_states WHERE domain_id = ? AND entity_name = ? AND attribute_name = ? LIMIT 1;";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return "";
    sqlite3_bind_int64(stmt, 1, (long long)domain_id);
    sqlite3_bind_text(stmt, 2, entity, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    sqlite3_bind_text(stmt, 3, attr, -1, SQLITE_TRANSIENT_DESTRUCTOR);
    int rc = sqlite3_step(stmt);
    char* result = "";
    if (rc == 100) { // SQLITE_ROW
        const unsigned char* txt = sqlite3_column_text(stmt, 0);
        if (txt) {
            size_t len = strlen((const char*)txt);
            char* copy = (char*)malloc(len + 1);
            if (copy) {
                memcpy(copy, txt, len + 1);
                result = copy;
            }
        }
    }
    sqlite3_finalize(stmt);
    return result;
}

double cartan_sqlite_get_rule_count(void* db, double domain_id) {
    if (!db) return 0.0;
    const char* sql = "SELECT COUNT(*) FROM rule_elements WHERE domain_id = ? AND status = 'active';";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_int64(stmt, 1, (long long)domain_id);
    double count = 0.0;
    int rc = sqlite3_step(stmt);
    if (rc == 100) {
        count = sqlite3_column_double(stmt, 0);
    }
    sqlite3_finalize(stmt);
    return count;
}

double cartan_sqlite_get_entity_count(void* db, double domain_id) {
    if (!db) return 0.0;
    const char* sql = "SELECT COUNT(*) FROM entity_states WHERE domain_id = ?;";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_int64(stmt, 1, (long long)domain_id);
    double count = 0.0;
    int rc = sqlite3_step(stmt);
    if (rc == 100) {
        count = sqlite3_column_double(stmt, 0);
    }
    sqlite3_finalize(stmt);
    return count;
}

void* cartan_sqlite_prepare_domain_rules(void* db, double domain_id) {
    if (!db) return NULL;
    const char* sql = "SELECT element_id, domain_id, element_type, is_strict, content FROM rule_elements "
                      "WHERE domain_id = ? AND status = 'active' ORDER BY is_strict DESC, element_id ASC;";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return NULL;
    sqlite3_bind_int64(stmt, 1, (long long)domain_id);
    return (void*)stmt;
}

void* cartan_sqlite_prepare_domain_entities(void* db, double domain_id) {
    if (!db) return NULL;
    const char* sql = "SELECT domain_id, entity_name, attribute_name, attribute_value, confidence FROM entity_states "
                      "WHERE domain_id = ? ORDER BY entity_name ASC, attribute_name ASC;";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return NULL;
    sqlite3_bind_int64(stmt, 1, (long long)domain_id);
    return (void*)stmt;
}

double cartan_sqlite_get_unconsolidated_count(void* db, double domain_id) {
    if (!db) return 0.0;
    const char* sql = "SELECT COUNT(*) FROM episodes WHERE domain_id = ? AND consolidated = 0;";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_int64(stmt, 1, (long long)domain_id);
    double count = 0.0;
    if (sqlite3_step(stmt) == 100) {
        count = sqlite3_column_double(stmt, 0);
    }
    sqlite3_finalize(stmt);
    return count;
}

double cartan_sqlite_consolidate_unprocessed_episodes(void* db, double domain_id) {
    if (!db) return 0.0;
    // 1. Fetch unconsolidated episodes for the domain
    const char* sql_fetch = "SELECT episode_id, speaker, content FROM episodes WHERE domain_id = ? AND consolidated = 0;";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql_fetch, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_int64(stmt, 1, (long long)domain_id);

    double count = 0.0;
    while (sqlite3_step(stmt) == 100) {
        const unsigned char* speaker = sqlite3_column_text(stmt, 1);
        const unsigned char* content = sqlite3_column_text(stmt, 2);

        // If speaker is user and has content, extract fact rule
        if (speaker && (strcmp((const char*)speaker, "user") == 0 || strcmp((const char*)speaker, "User") == 0)) {
            if (content && strlen((const char*)content) > 3) {
                const char* sql_ins = "INSERT INTO rule_elements (domain_id, element_type, content, is_strict, confidence, status) "
                                      "VALUES (?, 'fact_grounding', ?, 0, 0.95, 'active');";
                sqlite3_stmt* ins_stmt = NULL;
                if (sqlite3_prepare_v2((sqlite3*)db, sql_ins, -1, &ins_stmt, NULL) == 0) {
                    sqlite3_bind_int64(ins_stmt, 1, (long long)domain_id);
                    sqlite3_bind_text(ins_stmt, 2, (const char*)content, -1, SQLITE_TRANSIENT_DESTRUCTOR);
                    sqlite3_step(ins_stmt);
                    sqlite3_finalize(ins_stmt);
                }
            }
        }
        count += 1.0;
    }
    sqlite3_finalize(stmt);

    // 2. Mark episodes as consolidated
    const char* sql_mark = "UPDATE episodes SET consolidated = 1 WHERE domain_id = ? AND consolidated = 0;";
    sqlite3_stmt* mark_stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql_mark, -1, &mark_stmt, NULL) == 0) {
        sqlite3_bind_int64(mark_stmt, 1, (long long)domain_id);
        sqlite3_step(mark_stmt);
        sqlite3_finalize(mark_stmt);
    }

    return count;
}

double cartan_sqlite_supersede_rule(void* db, double old_elem_id, double new_elem_id) {
    if (!db) return 0.0;
    // Mark old element as superseded
    const char* sql_upd = "UPDATE rule_elements SET status = 'superseded', confidence = 0.0 WHERE element_id = ?;";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql_upd, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_int64(stmt, 1, (long long)old_elem_id);
    sqlite3_step(stmt);
    sqlite3_finalize(stmt);

    // Record superseding dependency if new_elem_id is specified
    if (new_elem_id > 0.0) {
        const char* sql_dep = "INSERT OR REPLACE INTO dependencies (source_element_id, target_element_id, relationship_type, weight, last_traversed) "
                              "VALUES (?, ?, 'supersedes', 1.0, CURRENT_TIMESTAMP);";
        sqlite3_stmt* dep_stmt = NULL;
        if (sqlite3_prepare_v2((sqlite3*)db, sql_dep, -1, &dep_stmt, NULL) == 0) {
            sqlite3_bind_int64(dep_stmt, 1, (long long)new_elem_id);
            sqlite3_bind_int64(dep_stmt, 2, (long long)old_elem_id);
            sqlite3_step(dep_stmt);
            sqlite3_finalize(dep_stmt);
        }
    }
    return 1.0;
}

double cartan_sqlite_apply_ebbinghaus_decay(void* db, double domain_id, double min_confidence_thresh) {
    if (!db) return 0.0;
    double thresh = min_confidence_thresh;
    if (thresh <= 0.0) thresh = 0.20;

    // Apply 10% decay step to non-strict active rules with access_count < 5
    const char* sql_decay = "UPDATE rule_elements SET confidence = confidence * 0.90 "
                            "WHERE domain_id = ? AND is_strict = 0 AND status = 'active' AND access_count < 5;";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql_decay, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_int64(stmt, 1, (long long)domain_id);
    sqlite3_step(stmt);
    sqlite3_finalize(stmt);

    // Prune rules whose confidence dropped below min_confidence_thresh
    const char* sql_prune = "UPDATE rule_elements SET status = 'pruned' "
                            "WHERE domain_id = ? AND is_strict = 0 AND status = 'active' AND confidence < ?;";
    sqlite3_stmt* prune_stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql_prune, -1, &prune_stmt, NULL) == 0) {
        sqlite3_bind_int64(prune_stmt, 1, (long long)domain_id);
        sqlite3_bind_double(prune_stmt, 2, thresh);
        sqlite3_step(prune_stmt);
        sqlite3_finalize(prune_stmt);
    }
    return 1.0;
}

double cartan_sqlite_flush_hebbian_weight(void* db, double src_id, double tgt_id, double weight) {
    if (!db) return 0.0;
    const char* sql = "INSERT INTO dependencies (source_element_id, target_element_id, relationship_type, weight, last_traversed) "
                      "VALUES (?, ?, 'hebbian_association', ?, CURRENT_TIMESTAMP) "
                      "ON CONFLICT(source_element_id, target_element_id, relationship_type) DO UPDATE SET "
                      "weight = excluded.weight, last_traversed = CURRENT_TIMESTAMP;";
    sqlite3_stmt* stmt = NULL;
    if (sqlite3_prepare_v2((sqlite3*)db, sql, -1, &stmt, NULL) != 0) return 0.0;
    sqlite3_bind_int64(stmt, 1, (long long)src_id);
    sqlite3_bind_int64(stmt, 2, (long long)tgt_id);
    sqlite3_bind_double(stmt, 3, weight);
    int rc = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    return (rc == 101) ? 1.0 : 0.0;
}

