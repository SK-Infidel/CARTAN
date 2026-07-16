; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"



define i32 @main(i32 %argc, ptr %argv) {
entry:
  store i32 %argc, ptr @global_argc, align 4
  store ptr %argv, ptr @global_argv, align 8
  %1 = alloca float, align 4
  store float 2.000000, ptr %1, align 4
  %2 = alloca float, align 4
  store float 3.000000, ptr %2, align 4
  ; --- Begin Fused Kernel ---
  %3 = load float, ptr %1, align 4
  %4 = load float, ptr %2, align 4
  %5 = fmul float %3, %4
  ; --- End Fused Kernel ---
  %6 = alloca float, align 4
  store float %5, ptr %6, align 4
  ; --- Begin Fused Kernel ---
  %7 = load float, ptr %6, align 4
  %8 = fsub float %7, 5.000000
  ; --- End Fused Kernel ---
  %9 = alloca float, align 4
  store float %8, ptr %9, align 4
  ; --- ones_like ---
  %10 = load float, ptr %9, align 4
  %11 = load ptr, ptr %10, align 8
  %12 = call ptr @cartan_tensor_ones_like(ptr %11)
  %13 = alloca ptr, align 8
  store ptr %12, ptr %13, align 8
  %14 = load ptr, ptr %13, align 8
  %15 = alloca ptr, align 8
  store ptr %14, ptr %15, align 8
  %16 = load ptr, ptr %15, align 8
  %17 = load float, ptr %2, align 4
  %18 = ptrtoint ptr %16 to i64
  %19 = sitofp i64 %18 to float
  %20 = fmul float %19, %17
  %21 = alloca float, align 4
  store float %20, ptr %21, align 4
  %22 = load ptr, ptr %15, align 8
  %23 = load float, ptr %1, align 4
  %24 = ptrtoint ptr %22 to i64
  %25 = sitofp i64 %24 to float
  %26 = fmul float %25, %23
  %27 = alloca float, align 4
  store float %26, ptr %27, align 4
  ; --- Begin Backward Pass ---
  %28 = load float, ptr %9, align 4
  ; --- End Backward Pass ---
  ret i32 0
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

@.str.0 = private unnamed_addr constant [37 x i8] c"\2d\2d\2d\20\41\75\74\6f\2d\47\65\6e\65\72\61\74\65\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.1 = private unnamed_addr constant [26 x i8] c"\2d\2d\2d\20\45\6e\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
