; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

%Compiler = type { ptr }


define i32 @user_main() {
entry:
  %1 = call i32 (ptr, ...) @printf(ptr @.str.0)
  %2 = call i32 (ptr, ...) @printf(ptr @.str.2, ptr @.str.1)
  %3 = alloca %Lexer, align 8
  %5 = load %Lexer, ptr %3, align 8
  %6 = call float @Lexer_tokenize(%Lexer %5)
  %7 = alloca float, align 4
  store float %6, ptr %7, align 4
  %8 = alloca %Parser, align 8
  %10 = load %Parser, ptr %8, align 8
  %11 = call float @Parser_parse(%Parser %10)
  %12 = alloca float, align 4
  store float %11, ptr %12, align 4
  %13 = alloca %KernelFusionPass, align 8
  %15 = load float, ptr %12, align 4
  %16 = load %KernelFusionPass, ptr %13, align 8
  %17 = call float @KernelFusionPass_optimize(%KernelFusionPass %16, float %15)
  store float %17, ptr %12, align 4
  %18 = alloca %LLVMGenerator, align 8
  %20 = load float, ptr %12, align 4
  %21 = load %LLVMGenerator, ptr %18, align 8
  %22 = call float @LLVMGenerator_generate(%LLVMGenerator %21, float %20)
  %23 = alloca float, align 4
  store float %22, ptr %23, align 4
  %24 = call i32 (ptr, ...) @printf(ptr @.str.3)
  ret i32 0
unreachable_1:
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
@.str.0 = private unnamed_addr constant [45 x i8] c"\43\41\52\54\41\4e\20\4e\61\74\69\76\65\20\43\6f\6d\70\69\6c\65\72\20\76\30\2e\32\2e\30\20\28\53\65\6c\66\2d\48\6f\73\74\65\64\29\0a\00", align 1
@.str.1 = private unnamed_addr constant [31 x i8] c"\2e\2e\2f\63\61\72\74\61\6e\5f\73\72\63\2f\74\65\73\74\5f\70\68\61\73\65\31\32\2e\63\61\72\00", align 1
@.str.2 = private unnamed_addr constant [17 x i8] c"\43\6f\6d\70\69\6c\69\6e\67\20\25\73\2e\2e\2e\0a\00", align 1
@.str.3 = private unnamed_addr constant [37 x i8] c"\43\6f\6d\70\69\6c\61\74\69\6f\6e\20\63\6f\6d\70\6c\65\74\65\64\20\73\75\63\63\65\73\73\66\75\6c\6c\79\2e\0a\00", align 1
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

