; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"



define void @user_main() {
entry:
  %1 = alloca [17 x float], align 4
  %2 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 0
  store float 0x0000000000000000, ptr %2, align 4
  %3 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 1
  store float 0x3FF0000000000000, ptr %3, align 4
  %4 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 2
  store float 0x4000000000000000, ptr %4, align 4
  %5 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 3
  store float 0x4008000000000000, ptr %5, align 4
  %6 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 4
  store float 0x4010000000000000, ptr %6, align 4
  %7 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 5
  store float 0x4014000000000000, ptr %7, align 4
  %8 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 6
  store float 0x4018000000000000, ptr %8, align 4
  %9 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 7
  store float 0x401C000000000000, ptr %9, align 4
  %10 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 8
  store float 0x4020000000000000, ptr %10, align 4
  %11 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 9
  store float 0x4022000000000000, ptr %11, align 4
  %12 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 10
  store float 0x4024000000000000, ptr %12, align 4
  %13 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 11
  store float 0x4026000000000000, ptr %13, align 4
  %14 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 12
  store float 0x4028000000000000, ptr %14, align 4
  %15 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 13
  store float 0x402A000000000000, ptr %15, align 4
  %16 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 14
  store float 0x402C000000000000, ptr %16, align 4
  %17 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 15
  store float 0x402E000000000000, ptr %17, align 4
  %18 = getelementptr inbounds [17 x float], ptr %1, i32 0, i32 16
  store float 0x4030000000000000, ptr %18, align 4
  %19 = alloca ptr, align 8
  store ptr %1, ptr %19, align 8
  %20 = alloca [13 x float], align 4
  %21 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 0
  store float 0x0000000000000000, ptr %21, align 4
  %22 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 1
  store float 0x3FF0000000000000, ptr %22, align 4
  %23 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 2
  store float 0x4000000000000000, ptr %23, align 4
  %24 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 3
  store float 0x4008000000000000, ptr %24, align 4
  %25 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 4
  store float 0x4010000000000000, ptr %25, align 4
  %26 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 5
  store float 0x4014000000000000, ptr %26, align 4
  %27 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 6
  store float 0x4018000000000000, ptr %27, align 4
  %28 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 7
  store float 0x401C000000000000, ptr %28, align 4
  %29 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 8
  store float 0x4020000000000000, ptr %29, align 4
  %30 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 9
  store float 0x4022000000000000, ptr %30, align 4
  %31 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 10
  store float 0x4024000000000000, ptr %31, align 4
  %32 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 11
  store float 0x4026000000000000, ptr %32, align 4
  %33 = getelementptr inbounds [13 x float], ptr %20, i32 0, i32 12
  store float 0x4028000000000000, ptr %33, align 4
  %34 = alloca ptr, align 8
  store ptr %20, ptr %34, align 8
  %35 = load ptr, ptr %19, align 8
  %36 = fptosi float 0.0 to i32
  %37 = getelementptr inbounds float, ptr %35, i32 %36
  %38 = load float, ptr %37, align 4
  %39 = call ptr @cartan_tensor_graft(ptr null)
  %40 = alloca ptr, align 8
  store ptr %39, ptr %40, align 8
  %41 = load ptr, ptr %34, align 8
  %42 = fptosi float 0x4028000000000000 to i32
  %43 = getelementptr inbounds float, ptr %41, i32 %42
  %44 = load float, ptr %43, align 4
  %45 = load ptr, ptr %40, align 8
  %46 = call ptr @cartan_tensor_translation_barrier(ptr null, ptr null)
  %47 = alloca ptr, align 8
  store ptr %46, ptr %47, align 8
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
declare ptr @cartan_tensor_alloc(i32)
declare ptr @cartan_tensor_alloc_nd(i32, i32, i32, i32, i32)
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

