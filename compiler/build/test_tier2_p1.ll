; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"



define void @test_tier2() {
entry:
  %1 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 10, i32 10, i32 1, i32 1)
  %2 = alloca ptr, align 8
  store ptr %1, ptr %2, align 8
  %3 = alloca float, align 4
  store float %2, ptr %3, align 4
  %4 = load ptr, ptr %2, align 8
  %5 = load float, ptr %4, align 4
  %6 = alloca float, align 4
  store float %5, ptr %6, align 4
  %7 = load ptr, ptr %2, align 8
  %8 = alloca float, align 4
  store float fn_ptr:grad, ptr %8, align 4
  %9 = load ptr, ptr %2, align 8
  %10 = alloca float, align 4
  store float fn_ptr:vmap, ptr %10, align 4
  %11 = call float @cartan_internal_import_onnx(ptr @.str.0)
  %12 = alloca float, align 4
  store float %11, ptr %12, align 4
  %13 = load ptr, ptr %2, align 8
  %14 = call ptr @cartan_tensor_quantize_int8(ptr %13)
  %15 = alloca ptr, align 8
  store ptr %14, ptr %15, align 8
  ret void
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  store i32 %argc, ptr @global_argc, align 4
  store ptr %argv, ptr @global_argv, align 8
  ret i32 0
}

declare ptr @malloc(i64)
declare void @free(ptr)
declare i32 @strcmp(ptr, ptr)
declare ptr @cartan_tensor_alloc(i32, i32)
declare ptr @cartan_tensor_alloc_nd(i32, i32, i32, i32, i32, i32)
declare ptr @cartan_tensor_linear_relu(ptr, ptr, ptr)
declare ptr @cartan_tensor_add(ptr, ptr)
declare ptr @cartan_tensor_sub(ptr, ptr)
declare ptr @cartan_tensor_mul(ptr, ptr)
declare ptr @cartan_tensor_matmul(ptr, ptr)
declare ptr @cartan_tensor_matmul_dynamic(ptr, ptr)
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
declare ptr @cartan_rt_parallel_transport(ptr, ptr, ptr)
declare void @cartan_emit_spike(float)
declare ptr @cartan_init_elastic_vocabulary()
declare ptr @cartan_init_sieving_cache()
declare ptr @cartan_init_fractal_attention()
declare ptr @cartan_stream_init(ptr, ptr)
declare ptr @cartan_init_spike()
declare ptr @cartan_init_neuron()
declare void @cartan_rt_register_capability(ptr, ptr)
declare ptr @cartan_rt_load_aer(ptr)
declare void @cartan_sandbox_hot_swap(ptr, ptr)
declare ptr @cartan_tensor_graft(ptr)
declare ptr @cartan_tensor_translation_barrier(ptr, ptr)
declare ptr @cartan_alloc_parameter_adam(i32)
declare ptr @cartan_alloc_parameter_adam_nd(i32, i32, i32, i32, i32)
declare ptr @cartan_alloc_sequence(i32)
declare ptr @cartan_alloc_block(i32)
declare ptr @cartan_rt_alloc_lattice(i32, i32)
declare ptr @cartan_rt_alloc_tree(i32)
declare ptr @cartan_rt_tree_search_mcts(ptr, ptr)
declare void @cartan_rt_multimodal_sync_start()
declare void @cartan_rt_multimodal_sync_end()
declare void @cartan_rt_vmap_begin()
declare void @cartan_rt_vmap_end()
declare void @cartan_rt_doubt_begin()
declare void @cartan_rt_doubt_end()
declare void @cartan_rt_chain_begin()
declare void @cartan_rt_chain_end()
declare void @cartan_rt_route_begin()
declare void @cartan_rt_route_end()
declare void @cartan_rt_grok_begin()
declare void @cartan_rt_grok_end()
declare void @cartan_rt_override_begin()
declare void @cartan_rt_override_end()
declare ptr @cartan_rt_paged_attention(ptr, ptr, ptr)
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
declare ptr @cartan_tensor_quantize_int8(ptr)
declare ptr @cartan_internal_import_onnx(ptr)
@.str.0 = private unnamed_addr constant [11 x i8] c"\6d\6f\64\65\6c\2e\6f\6e\6e\78\00", align 1
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

