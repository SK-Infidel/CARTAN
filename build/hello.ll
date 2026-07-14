; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"



define i32 @main(i32 %argc, ptr %argv) {
entry:
  store i32 %argc, ptr @global_argc, align 4
  store ptr %argv, ptr @global_argv, align 8
  %1 = alloca float, align 4
  store float 0x4024000000000000, ptr %1, align 4
  %2 = alloca float, align 4
  store float 0x4034000000000000, ptr %2, align 4
  ; --- Begin Fused Kernel ---
  %3 = load float, ptr %1, align 4
  %4 = load float, ptr %2, align 4
  %5 = fmul float %4, 0x4000000000000000
  %6 = fadd float %3, %5
  ; --- End Fused Kernel ---
  %7 = alloca float, align 4
  store float %6, ptr %7, align 4
  %8 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 2, i32 3, i32 1, i32 1)
  %9 = alloca ptr, align 8
  store ptr %8, ptr %9, align 8
  %10 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 3, i32 2, i32 1, i32 1)
  %11 = alloca ptr, align 8
  store ptr %10, ptr %11, align 8
  %12 = load ptr, ptr %9, align 8
  %13 = load ptr, ptr %11, align 8
  %14 = call ptr @cartan_tensor_matmul(ptr %12, ptr %13)
  %15 = alloca ptr, align 8
  store ptr %14, ptr %15, align 8
  ; --- Begin Fused Kernel ---
  %16 = load ptr, ptr %15, align 8
  %17 = ptrtoint ptr %16 to i64
  %18 = sitofp i64 %17 to float
  %19 = fmul float %18, 0x4000000000000000
  ; --- End Fused Kernel ---
  %20 = alloca float, align 4
  store float %19, ptr %20, align 4
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
declare void @cartan_tensor_backward(ptr)
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

