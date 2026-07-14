; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"



define dso_local dllexport void @start_model_stitching(ptr %arg_donor, ptr %arg_llama, ptr %arg_local_v) {
entry:
  %1 = alloca ptr, align 4
  store ptr %arg_donor, ptr %1, align 4
  %2 = alloca ptr, align 4
  store ptr %arg_llama, ptr %2, align 4
  %3 = alloca ptr, align 4
  store ptr %arg_local_v, ptr %3, align 4
  %4 = load ptr, ptr %1, align 8
  call void @cartan_absorb_weights(ptr @.str.0, ptr %4)
  %5 = load ptr, ptr %2, align 8
  %6 = load ptr, ptr %3, align 8
  call void @cartan_project_vocab(ptr %5, ptr %6)
  ret void
}

define dso_local dllexport ptr @get_status() {
entry:
  %7 = fptoui float 0x3FF0000000000000 to i64
  %8 = inttoptr i64 %7 to ptr
  ret ptr %8
unreachable_1:
  ret ptr null
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  store i32 %argc, ptr @global_argc, align 4
  store ptr %argv, ptr @global_argv, align 8
  %9 = call ptr @cartan_alloc_parameter_adam_nd(i32 2, i32 1024, i32 1024, i32 1, i32 1)
  %10 = alloca ptr, align 8
  store ptr %9, ptr %10, align 8
  %11 = call ptr @cartan_alloc_parameter_adam_nd(i32 2, i32 1024, i32 1024, i32 1, i32 1)
  %12 = alloca ptr, align 8
  store ptr %11, ptr %12, align 8
  %13 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 32000, i32 1024, i32 1, i32 1)
  %14 = alloca ptr, align 8
  store ptr %13, ptr %14, align 8
  %15 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 32000, i32 1024, i32 1, i32 1)
  %16 = alloca ptr, align 8
  store ptr %15, ptr %16, align 8
  %17 = load ptr, ptr %10, align 8
  %18 = load ptr, ptr %14, align 8
  %19 = load ptr, ptr %16, align 8
  call void @start_model_stitching(ptr %17, ptr %18, ptr %19)
  %20 = call ptr @get_status()
  %21 = alloca ptr, align 8
  store ptr %20, ptr %21, align 8
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
@.str.0 = private unnamed_addr constant [26 x i8] c"\70\61\74\68\2f\74\6f\2f\64\6f\6e\6f\72\5f\77\65\69\67\68\74\73\2e\62\69\6e\00", align 1
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

