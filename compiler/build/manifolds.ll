; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"



define void @user_main() {
entry:
  %1 = call float @print(ptr @.str.0)
  %2 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 4, i32 4, i32 1, i32 1)
  %3 = alloca ptr, align 8
  store ptr %2, ptr %3, align 8
  %4 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 4, i32 4, i32 1, i32 1)
  %5 = alloca ptr, align 8
  store ptr %4, ptr %5, align 8
  %6 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 4, i32 4, i32 1, i32 1)
  %7 = alloca ptr, align 8
  store ptr %6, ptr %7, align 8
  %8 = load ptr, ptr %3, align 8
  %9 = load ptr, ptr %5, align 8
  %10 = call ptr @cartan_tensor_matmul(ptr %8, ptr %9)
  store float ptr:%10, ptr %7, align 4
  %11 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 4, i32 4, i32 1, i32 1)
  %12 = alloca ptr, align 8
  store ptr %11, ptr %12, align 8
  %13 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 4, i32 4, i32 1, i32 1)
  %14 = alloca ptr, align 8
  store ptr %13, ptr %14, align 8
  %15 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 4, i32 4, i32 1, i32 1)
  %16 = alloca ptr, align 8
  store ptr %15, ptr %16, align 8
  %17 = load ptr, ptr %12, align 8
  %18 = load ptr, ptr %14, align 8
  %19 = call ptr @cartan_tensor_matmul_minkowski(ptr %17, ptr %18)
  store float ptr:%19, ptr %16, align 4
  %20 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 4, i32 4, i32 1, i32 1)
  %21 = alloca ptr, align 8
  store ptr %20, ptr %21, align 8
  %22 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 4, i32 4, i32 1, i32 1)
  %23 = alloca ptr, align 8
  store ptr %22, ptr %23, align 8
  %24 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 4, i32 4, i32 1, i32 1)
  %25 = alloca ptr, align 8
  store ptr %24, ptr %25, align 8
  %26 = load ptr, ptr %21, align 8
  %27 = load ptr, ptr %23, align 8
  %28 = call ptr @cartan_tensor_matmul_poincare(ptr %26, ptr %27)
  store float ptr:%28, ptr %25, align 4
  %29 = call float @print(ptr @.str.1)
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
@.str.0 = private unnamed_addr constant [59 x i8] c"\54\65\73\74\69\6e\67\20\45\75\63\6c\69\64\65\61\6e\2c\20\4d\69\6e\6b\6f\77\73\6b\69\2c\20\61\6e\64\20\50\6f\69\6e\63\61\72\65\20\43\6f\6e\74\72\61\63\74\69\6f\6e\73\2e\2e\2e\00", align 1
@.str.1 = private unnamed_addr constant [47 x i8] c"\41\6c\6c\20\6d\61\6e\69\66\6f\6c\64\20\74\79\70\65\73\74\61\74\65\73\20\63\6f\6d\70\69\6c\65\64\20\73\75\63\63\65\73\73\66\75\6c\6c\79\21\00", align 1
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

