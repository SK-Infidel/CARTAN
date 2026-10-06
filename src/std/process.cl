// src/std/process.cl
// CARTAN Standard Library: Sandboxed Native Process Execution & Host Operation Engine

include "src/std/string.cl";

extern fn cartan_system(cmd: string) -> float;
extern fn cartan_file_exists(path: string) -> float;
extern fn cartan_read_file(path: string) -> string;
extern fn remove(path: string) -> float;
extern fn free(p: ptr) -> void;
extern fn cartan_string_length(s: string) -> float;
extern fn cartan_string_substring(s: string, start: float, end_idx: float) -> string;
extern fn cartan_string_concat(s1: string, s2: string) -> string;
extern fn cartan_string_contains(s: string, sub: string) -> float;
extern fn cartan_string_starts_with(s: string, prefix: string) -> float;
extern fn cartan_float_to_string(v: float) -> string;

// Global tracking the exit code of the most recently executed process
var g_process_last_exit_code: float = 0.0;

// Returns the exit code of the last process execution
fn process_last_exit_code() -> float {
    return g_process_last_exit_code;
}

// Determines the most reliable temporary file location for redirected command output
fn process_get_scratch_path() -> string {
    if (cartan_file_exists("scratch") == 1.0) {
        return "scratch\\_cartan_proc_out.tmp";
    }
    return "_cartan_proc_out.tmp";
}

// Validates that a file system path does not contain directory traversal sequences (..)
// and stays strictly within the allowed root boundary
fn process_is_path_safe(path: string, allowed_root: string) -> float {
    if (path == 0.0 || cartan_string_length(path) == 0.0) { return 0.0; }

    // Reject directory traversal indicators
    if (cartan_string_contains(path, "..") == 1.0) {
        return 0.0;
    }

    // Reject absolute Windows drive letters if an allowed root is enforced
    if (allowed_root != 0.0 && cartan_string_length(allowed_root) > 0.0) {
        if (cartan_string_contains(path, ":") == 1.0) {
            // Check if it strictly starts with the allowed root
            if (cartan_string_starts_with(path, allowed_root) == 0.0) {
                return 0.0;
            }
        } else {
            // Normalized relative path must stay under allowed root
            if (cartan_string_starts_with(path, "/") == 1.0 || cartan_string_starts_with(path, "\\") == 1.0) {
                return 0.0;
            }
        }
    }
    return 1.0;
}

// Executes a shell command, redirecting stdout and stderr directly to a destination file
fn process_exec_to_file(cmd: string, out_path: string) -> float {
    if (cmd == 0.0 || cartan_string_length(cmd) == 0.0) { return -1.0; }
    if (out_path == 0.0 || cartan_string_length(out_path) == 0.0) { return -1.0; }

    if (cartan_file_exists(out_path) == 1.0) {
        remove(out_path);
    }

    var full_cmd = "cmd.exe /c \"(";
    full_cmd = cartan_string_concat(full_cmd, cmd);
    full_cmd = cartan_string_concat(full_cmd, ") > \"");
    full_cmd = cartan_string_concat(full_cmd, out_path);
    full_cmd = cartan_string_concat(full_cmd, "\" 2>&1\"");

    let rc = cartan_system(full_cmd);
    free(full_cmd);
    g_process_last_exit_code = rc;
    return rc;
}

// Executes a shell command with full stdout/stderr capture, exit code tagging, and scratch cleanup
fn process_exec(cmd: string) -> string {
    if (cmd == 0.0 || cartan_string_length(cmd) == 0.0) { return ""; }

    let scratch_file = process_get_scratch_path();
    if (cartan_file_exists(scratch_file) == 1.0) {
        remove(scratch_file);
    }

    var full_cmd = "cmd.exe /c \"(";
    full_cmd = cartan_string_concat(full_cmd, cmd);
    full_cmd = cartan_string_concat(full_cmd, ") > \"");
    full_cmd = cartan_string_concat(full_cmd, scratch_file);
    full_cmd = cartan_string_concat(full_cmd, "\" 2>&1\"");

    let rc = cartan_system(full_cmd);
    free(full_cmd);
    g_process_last_exit_code = rc;

    var out_text = "";
    if (cartan_file_exists(scratch_file) == 1.0) {
        out_text = cartan_read_file(scratch_file);
        remove(scratch_file);
    }

    // Prepend exit code indicator on non-zero exit
    if (rc != 0.0) {
        var err_prefix = "[Exit code: ";
        let rc_raw = cartan_float_to_string(rc);
        let dot_pos = string_index_of_offset(rc_raw, ".", 0.0);
        var rc_str = rc_raw;
        if (dot_pos >= 0.0) {
            rc_str = cartan_string_substring(rc_raw, 0.0, dot_pos);
            free(rc_raw);
        }
        err_prefix = cartan_string_concat(err_prefix, rc_str);
        free(rc_str);
        err_prefix = cartan_string_concat(err_prefix, "]\n");

        let combined = cartan_string_concat(err_prefix, out_text);
        free(err_prefix);
        if (cartan_string_length(out_text) > 0.0) {
            free(out_text);
        }
        out_text = combined;
    }

    // Cap output at 65,536 bytes to prevent downstream buffer exhaustion
    let out_len = cartan_string_length(out_text);
    if (out_len > 65536.0) {
        let truncated = cartan_string_substring(out_text, 0.0, 65536.0);
        let final_str = cartan_string_concat(truncated, "\n[... output truncated at 64 KB ...]\n");
        free(truncated);
        free(out_text);
        return final_str;
    }

    return out_text;
}
