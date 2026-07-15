; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"



define void @test_math_minkowski(ptr %arg_t1) {
entry:
  %1 = alloca ptr, align 4
  store ptr %arg_t1, ptr %1, align 4
  %2 = load ptr, ptr %1, align 8
  ret void
unreachable_1:
  ret void
}

define void @test_math_poincaredisk(ptr %arg_t1) {
entry:
  %3 = alloca ptr, align 4
  store ptr %arg_t1, ptr %3, align 4
  %4 = load ptr, ptr %3, align 8
  ret void
unreachable_2:
  ret void
}

define void @user_main() {
entry:
  %5 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 10, i32 10, i32 1, i32 1)
  %6 = alloca ptr, align 8
  store ptr %5, ptr %6, align 8
  %7 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 10, i32 10, i32 1, i32 1)
  %8 = alloca ptr, align 8
  store ptr %7, ptr %8, align 8
  %9 = load ptr, ptr %6, align 8
  call void @test_math_minkowski(ptr %9)
  %10 = load ptr, ptr %8, align 8
  call void @test_math_poincaredisk(ptr %10)
  ret void
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  store i32 %argc, ptr @global_argc, align 4
  store ptr %argv, ptr @global_argv, align 8
  %exit_code = call i32 @user_main()
  ret i32 %exit_code
}

declare ptr @malloc(i64)
declare void @free(ptr)
declare i32 @strcmp(ptr, ptr)
declare ptr @cartan_tensor_alloc(i32, i32)
declare ptr @cartan_tensor_alloc_nd(i32, i32, i32, i32, i32, i32)
declare ptr @cartan_tensor_add(ptr, ptr)
declare ptr @cartan_tensor_sub(ptr, ptr)
declare ptr @cartan_tensor_mul(ptr, ptr)
declare ptr @cartan_tensor_matmul(ptr, ptr)
declare ptr @cartan_tensor_matmul_minkowski(ptr, ptr)
declare ptr @cartan_tensor_matmul_poincare(ptr, ptr)
declare void @cartan_tensor_backward(ptr)
declare void @cartan_tensor_print(ptr)
declare void @cartan_tensor_step(float)
declare float @cartan_file_read_tokens(ptr, float, ptr)
declare float @cartan_net_fetch_tokens(ptr, ptr)
declare float @cartan_file_read_batch(ptr, ptr, float, ptr)
declare float @cartan_tensor_mse_loss(ptr, ptr)
declare float @cartan_tensor_cross_entropy_loss(ptr, ptr)
declare float @cartan_tensor_spherical_cosine_loss(ptr, ptr)
declare float @cartan_tensor_finsler_randers_loss(ptr, ptr)
declare float @cartan_tensor_betti_homology_loss(ptr, ptr)
declare ptr @cartan_tensor_embed(ptr, ptr)
declare void @cartan_emit_spike(float)
declare ptr @cartan_init_elastic_vocabulary()
declare ptr @cartan_init_sieving_cache()
declare ptr @cartan_init_fractal_attention()
declare ptr @cartan_stream_init(ptr, ptr)
declare ptr @cartan_init_spike()
declare ptr @cartan_init_neuron()
declare ptr @cartan_tensor_graft(ptr)
declare ptr @cartan_tensor_translation_barrier(ptr, ptr)
declare ptr @cartan_alloc_parameter_adam(i32)
declare ptr @cartan_alloc_parameter_adam_nd(i32, i32, i32, i32, i32)
declare ptr @cartan_alloc_sequence(i32)
declare ptr @cartan_alloc_block(i32)
declare ptr @cartan_tensor_transpose(ptr)
declare ptr @cartan_tensor_ones_like(ptr)
declare void @cartan_absorb_weights(ptr, ptr)
declare void @cartan_project_vocab(ptr, ptr)
declare ptr @cartan_tokenize_bpe(ptr, ptr)
declare void @cartan_align_spans(ptr, ptr, ptr)
declare void @cartan_free_compute_graph()
declare void @cartan_fluid_precision_start(ptr, ptr)
declare void @cartan_fluid_precision_end()
declare void @cartan_sparsity_start(i32, float)
declare void @cartan_sparsity_end()
declare void @cartan_prune_graph(float)
@global_argc = global i32 0, align 4
@global_argv = global ptr null, align 8

define ptr @sys_get_arg(float %index) {
entry:
  %int_idx = fptosi float %index to i32
  %argv_base = load ptr, ptr @global_argv, align 8
  %arg_ptr = getelementptr inbounds ptr, ptr %argv_base, i32 %int_idx
  %arg_str = load ptr, ptr %arg_ptr, align 8
  ret ptr %arg_str
}

