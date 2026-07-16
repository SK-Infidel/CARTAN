; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"



define i32 @tier2_tests() {
entry:
  %1 = alloca float, align 4
  store float 10.000000, ptr %1, align 4
  %2 = alloca ptr, align 8
  store ptr %1, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = load ptr, ptr %3, align 8
  %5 = alloca ptr, align 8
  store ptr %4, ptr %5, align 8
  %6 = call ptr @cartan_internal_import_onnx(ptr @.str.model.uri.0)
  %7 = alloca ptr, align 8
  store ptr %6, ptr %7, align 8
  %8 = load ptr, ptr %7, align 8
  %9 = call ptr @cartan_tensor_quantize_int8(ptr %8)
  %10 = alloca ptr, align 8
  store ptr %9, ptr %10, align 8
  %11 = alloca ptr, align 8
  store ptr @.str.prompt.1, ptr %11, align 8
  %12 = call ptr @cartan_internal_import_onnx(ptr @.str.model.uri.2)
  %13 = alloca ptr, align 8
  store ptr %12, ptr %13, align 8
  %14 = alloca ptr, align 8
  %15 = call ptr @cartan_tensor_alloc_nd(i32 3, i32 224, i32 224, i32 3, i32 1)
  %16 = alloca ptr, align 8
  store ptr %15, ptr %16, align 8
  %17 = load ptr, ptr %16, align 8
  %18 = load ptr, ptr %10, align 8
  call void @cartan_project_vocab(ptr %17, ptr %18)
  %19 = alloca float, align 4
  store float 0.0, ptr %19, align 4
  %20 = load ptr, ptr %11, align 8
  %21 = call i32 @cartan_pattern_match(ptr %20, ptr @.str.prompt.3)
  %22 = icmp sgt i32 %21, 0
  br i1 %22, label %match_arm_2, label %match_next_3
match_arm_2:
  %23 = alloca float, align 4
  store float 1, ptr %23, align 4
  br label %match_end_1
match_next_3:
  br label %match_end_1
match_end_1:
  %24 = load ptr, ptr %10, align 8
  call void @cartan_weight_decay(ptr %24, float 0.01)
  ; JIT BLOCK BEGIN
  %25 = alloca float, align 4
  store float 42, ptr %25, align 4
  ; JIT BLOCK END
  %26 = fptosi float 0 to i32
  ret i32 %26
unreachable_4:
  ret i32 0
}

define i32 @user_main() {
entry:
  %27 = call i32 @tier2_tests()
  %28 = sitofp i32 %27 to float
  %29 = alloca float, align 4
  store float %28, ptr %29, align 4
  %30 = load float, ptr %29, align 4
  %31 = fpext float %30 to double
  %32 = call i32 (ptr, ...) @printf(ptr @.str.4, double %31)
  %33 = fptosi float 0 to i32
  ret i32 %33
unreachable_5:
  ret i32 0
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
declare i32 @cartan_pattern_match(ptr, ptr)
declare ptr @cartan_rt_transform(ptr, ptr)
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
@.str.model.uri.0 = private unnamed_addr constant [11 x i8] c"dummy.onnx\00", align 1
@.str.prompt.1 = private unnamed_addr constant [10 x i8] c"hello {x}\00", align 1
@.str.model.uri.2 = private unnamed_addr constant [16 x i8] c"hf://meta-llama\00", align 1
@.str.prompt.3 = private unnamed_addr constant [10 x i8] c"hello {x}\00", align 1
@.str.4 = private unnamed_addr constant [28 x i8] c"\54\69\65\72\20\32\20\74\65\73\74\73\20\63\6f\6d\70\6c\65\74\65\64\21\20\25\64\0a\00", align 1
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

