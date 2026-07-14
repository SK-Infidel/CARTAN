; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"



define void @forward_pass(ptr %arg_input) {
entry:
  %1 = alloca ptr, align 4
  store ptr %arg_input, ptr %1, align 4
  ; --- Fluid Precision: primary=fp8, fallback=fp32 ---
  call void @cartan_fluid_precision_start(ptr null, ptr null)
  %2 = load ptr, ptr %1, align 8
  %3 = ptrtoint ptr %2 to i64
  %4 = sitofp i64 %3 to float
  %5 = fmul float %4, 0.0
  %6 = alloca float, align 4
  store float %5, ptr %6, align 4
  ; --- Sparsity Block ---
  %7 = fptosi float 0x4010000000000000 to i32
  call void @cartan_sparsity_start(i32 %7, float 0x3FE0000000000000)
  %8 = load float, ptr %6, align 4
  call void @cartan_sparsity_end()
  call void @cartan_fluid_precision_end()
  ret void
unreachable_1:
  ret void
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  store i32 %argc, ptr @global_argc, align 4
  store ptr %argv, ptr @global_argv, align 8
  %9 = call ptr @cartan_alloc_parameter_adam_nd(i32 3, i32 8, i32 256, i32 248, i32 1)
  %10 = alloca ptr, align 8
  store ptr %9, ptr %10, align 8
  %11 = call ptr @cartan_alloc_sequence(i32 4096)
  %12 = alloca ptr, align 8
  store ptr %11, ptr %12, align 8
  %13 = call ptr @cartan_alloc_block(i32 128)
  %14 = alloca ptr, align 8
  store ptr %13, ptr %14, align 8
  ret i32 0
}

declare ptr @malloc(i64)
declare void @free(ptr)
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
declare float @cartan_file_read_batch(ptr, ptr, float, ptr)
declare float @cartan_tensor_mse_loss(ptr, ptr)
declare float @cartan_tensor_cross_entropy_loss(ptr, ptr)
declare ptr @cartan_tensor_embed(ptr, ptr)
declare void @cartan_emit_spike(float)
declare ptr @cartan_init_elastic_vocabulary()
declare ptr @cartan_init_sieving_cache()
declare ptr @cartan_init_fractal_attention()
declare ptr @cartan_stream_init(ptr, ptr)
declare ptr @cartan_init_spike()
declare ptr @cartan_init_neuron()
declare ptr @cartan_alloc_parameter_adam(i32)
declare ptr @cartan_alloc_parameter_adam_nd(i32, i32, i32, i32, i32)
declare ptr @cartan_alloc_sequence(i32)
declare ptr @cartan_alloc_block(i32)
declare void @cartan_absorb_weights(ptr, ptr)
declare void @cartan_project_vocab(ptr, ptr)
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

