; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"



define i32 @main(i32 %argc, ptr %argv) {
entry:
  store i32 %argc, ptr @global_argc, align 4
  store ptr %argv, ptr @global_argv, align 8
  %1 = call ptr @cartan_alloc_parameter_adam_nd(i32 2, i32 16, i32 16, i32 1, i32 1)
  %2 = alloca ptr, align 8
  store ptr %1, ptr %2, align 8
  %3 = call ptr @cartan_alloc_parameter_adam_nd(i32 2, i32 16, i32 16, i32 1, i32 1)
  %4 = alloca ptr, align 8
  store ptr %3, ptr %4, align 8
  ; --- Begin Fused Kernel ---
  %5 = load ptr, ptr %2, align 8
  %6 = load ptr, ptr %4, align 8
  %7 = call ptr @cartan_tensor_mul(ptr %5, ptr %6)
  ; --- End Fused Kernel ---
  %8 = alloca ptr, align 8
  store ptr %7, ptr %8, align 8
  ; --- Begin Fused Kernel ---
  %9 = load ptr, ptr %8, align 8
  %10 = load ptr, ptr %2, align 8
  %11 = call ptr @cartan_tensor_add(ptr %9, ptr %10)
  ; --- End Fused Kernel ---
  %12 = alloca ptr, align 8
  store ptr %11, ptr %12, align 8
  ; --- Begin Fused Kernel ---
  %13 = load ptr, ptr %12, align 8
  %14 = load ptr, ptr %4, align 8
  %15 = call ptr @cartan_tensor_sub(ptr %13, ptr %14)
  ; --- End Fused Kernel ---
  %16 = alloca ptr, align 8
  store ptr %15, ptr %16, align 8
  ; --- Begin Backward Pass ---
  %17 = load ptr, ptr %16, align 8
  call void @cartan_tensor_backward(ptr %17)
  call void @cartan_tensor_step(float 0x3F847AE140000000)
  call void @cartan_free_compute_graph()
  ; --- End Backward Pass ---
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

