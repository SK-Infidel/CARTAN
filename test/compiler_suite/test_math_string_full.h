// CARTAN Auto-Generated C/C++ FFI Header
#ifndef CARTAN_GENERATED_FFI_H
#define CARTAN_GENERATED_FFI_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

double cartan_export_malloc(double* args);
double cartan_export_calloc(double* args);
double cartan_export_free(double* args);
double cartan_export_memcpy(double* args);
double cartan_export_strlen(double* args);
double cartan_export_strcpy(double* args);
double cartan_export_strcat(double* args);
double cartan_export_strcmp(double* args);
double cartan_export_strncmp(double* args);
double cartan_export_c_cartan_string_char_at(double* args);
double cartan_export_cartan_c_memcpy(double* args);
double cartan_export_cartan_c_strncmp(double* args);
double cartan_export_cartan_c_ptr_add(double* args);
double cartan_export_cartan_c_tree_create(double* args);
double cartan_export_cartan_c_tree_len_f(double* args);
double cartan_export_cartan_c_tree_get(double* args);
double cartan_export_cartan_c_tree_push(double* args);
double cartan_export_cartan_c_tree_set(double* args);
double cartan_export_cartan_c_tree_remove(double* args);
double cartan_export_strstr(double* args);
double cartan_export_atof(double* args);
double cartan_export_cartan_c_int_to_string(double* args);
double cartan_export_cartan_c_float_to_string(double* args);
double cartan_export_cartan_c_sprintf_hex_byte(double* args);
double cartan_export_sprintf(double* args);
double cartan_export_printf(double* args);
double cartan_export_exit(double* args);
double cartan_export_fopen(double* args);
double cartan_export_fclose(double* args);
double cartan_export_fseek(double* args);
double cartan_export_ftell(double* args);
double cartan_export_fread(double* args);
double cartan_export_fwrite(double* args);
double cartan_export_fputs(double* args);
double cartan_export_fgets(double* args);
double cartan_export_getenv(double* args);
double cartan_export_system(double* args);
double cartan_export_remove(double* args);
double cartan_export_rename(double* args);
double cartan_export_floor(double* args);
double cartan_export_fflush(double* args);
double cartan_export___acrt_iob_func(double* args);
double cartan_export_cartan_string_length(double* args);
double cartan_export_cartan_string_concat(double* args);
double cartan_export_cartan_string_eq(double* args);
double cartan_export_cartan_string_substring(double* args);
double cartan_export_cartan_string_starts_with(double* args);
double cartan_export_cartan_string_contains(double* args);
double cartan_export_cartan_string_get_char(double* args);
double cartan_export_cartan_string_replace(double* args);
double cartan_export_cartan_strip_prefix(double* args);
double cartan_export_cartan_int_to_string(double* args);
double cartan_export_cartan_float_to_string(double* args);
double cartan_export_cartan_hash_string(double* args);
double cartan_export_cartan_llvm_format_string_literal(double* args);
double cartan_export_cartan_tree_create(double* args);
double cartan_export_cartan_tree_len_f(double* args);
double cartan_export_cartan_tree_len(double* args);
double cartan_export_cartan_tree_push(double* args);
double cartan_export_cartan_tree_get_f32(double* args);
double cartan_export_cartan_tree_get(double* args);
double cartan_export_cartan_tree_set(double* args);
double cartan_export_cartan_tree_remove(double* args);
double cartan_export_cartan_tree_push_f32(double* args);
double cartan_export_cartan_tree_set_f32(double* args);
double cartan_export_cartan_tree_has(double* args);
double cartan_export_contains_string(double* args);
double cartan_export_cartan_tree_write_file(double* args);
double cartan_export_cartan_slice_tree(double* args);
double cartan_export_cartan_slice_nd(double* args);
double cartan_export_cartan_vec_create(double* args);
double cartan_export_cartan_vec_push_f32(double* args);
double cartan_export_cartan_vec_get_f32(double* args);
double cartan_export_cartan_vec_len(double* args);
double cartan_export_cartan_vec_set_f32(double* args);
double cartan_export_cartan_vec_scale(double* args);
double cartan_export_cartan_tensor_add(double* args);
double cartan_export_cartan_tensor_sub(double* args);
double cartan_export_cartan_tensor_mul(double* args);
double cartan_export_cartan_tensor_div(double* args);
double cartan_export_cartan_tensor_alloc(double* args);
double cartan_export_cartan_file_exists(double* args);
double cartan_export_cartan_read_file(double* args);
double cartan_export_cartan_write_file(double* args);
double cartan_export_cartan_copy_file(double* args);
double cartan_export_cartan_get_env(double* args);
double cartan_export_cartan_getenv(double* args);
double cartan_export_cartan_null_stream(double* args);
double cartan_export_cartan_flush(double* args);
double cartan_export_cartan_read_line(double* args);
double cartan_export_cartan_assert(double* args);
double cartan_export_cartan_static_assert(double* args);
double cartan_export_cartan_next_reg(double* args);
double cartan_export_cartan_get_quote(double* args);
double cartan_export_cartan_jit_eval(double* args);
double cartan_export_cartan_system(double* args);
double cartan_export_cartan_async_spawn(double* args);
double cartan_export_cartan_async_yield(double* args);
double cartan_export_cartan_async_await(double* args);
double cartan_export_cartan_rt_vram_lock_parameters(double* args);
double cartan_export_cartan_rt_vram_unlock_parameters(double* args);
double cartan_export_cartan_rt_check_vram_access(double* args);
double cartan_export_cartan_rt_lock_swmr(double* args);
double cartan_export_cartan_rt_unlock_swmr(double* args);
double cartan_export_cartan_rt_atomic_swap_graph(double* args);
double cartan_export_cartan_export_c_headers(double* args);
double cartan_export_c_cartan_string_concat(double* args);
double cartan_export_cartan_ast_string_concat(double* args);
double cartan_export_c_cartan_string_eq(double* args);
double cartan_export_geomind_crt_streq(double* args);
double cartan_export_c_cartan_string_substring(double* args);
double cartan_export_cartan_ast_string_substring(double* args);
double cartan_export_c_cartan_string_length(double* args);
double cartan_export_c_cartan_string_contains(double* args);
double cartan_export_c_cartan_string_replace(double* args);
double cartan_export_c_cartan_float_to_string(double* args);
double cartan_export_cartan_double_to_string(double* args);
double cartan_export_c_cartan_read_file(double* args);
double cartan_export_cartan_ast_tree_push(double* args);
double cartan_export_cartan_ast_tree_set(double* args);
double cartan_export_cartan_ast_tree_write_file(double* args);
double cartan_export_cartan_ast_tree_get_f32(double* args);
double cartan_export_cartan_ast_get_ptr(double* args);
double cartan_export_c_sys_get_arg_count(double* args);
double cartan_export_c_sys_get_arg(double* args);
double cartan_export_main(double* args);

#ifdef __cplusplus
}
#endif

#endif // CARTAN_GENERATED_FFI_H
