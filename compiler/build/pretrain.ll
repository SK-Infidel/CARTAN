; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

%HttpStream = type { float, ptr }
%WebScraper = type { float }


define float @HttpStream_fetch(%HttpStream %arg_this, ptr %arg_url) {
entry:
  %1 = alloca %HttpStream, align 8
  store %HttpStream %arg_this, ptr %1, align 8
  %2 = alloca ptr, align 4
  store ptr %arg_url, ptr %2, align 4
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds %HttpStream, ptr %1, i32 0, i32 1
  %5 = load ptr, ptr %4, align 8
  %6 = call float @cartan_net_fetch_tokens(ptr %3, ptr %5)
  %7 = alloca float, align 4
  store float %6, ptr %7, align 4
  %8 = load float, ptr %7, align 4
  ret float %8
unreachable_1:
  ret float 0.0
}

define float @WebScraper_pull_text(%WebScraper %arg_this, ptr %arg_url) {
entry:
  %9 = alloca %WebScraper, align 8
  store %WebScraper %arg_this, ptr %9, align 8
  %10 = alloca ptr, align 4
  store ptr %arg_url, ptr %10, align 4
  %11 = getelementptr inbounds %WebScraper, ptr %9, i32 0, i32 0
  %12 = load float, ptr %11, align 4
  %13 = load ptr, ptr %10, align 8
  %14 = load %float, ptr %12, align 8
  %15 = call float @float_fetch(%float %14, ptr %13)
  %16 = alloca float, align 4
  store float %15, ptr %16, align 4
  %17 = load float, ptr %16, align 4
  ret float %17
unreachable_2:
  ret float 0.0
}

define i32 @user_main() {
entry:
  ; --- Struct Instantiation: GeoMindHybridEngine ---
  %18 = alloca %GeoMindHybridEngine
  %19 = alloca float, align 4
  store float 0x4070000000000000, ptr %19, align 4
  %20 = alloca float, align 4
  store float 0x4020000000000000, ptr %20, align 4
  ; --- Begin Fused Kernel ---
  %21 = load float, ptr %19, align 4
  %22 = load float, ptr %20, align 4
  %23 = fmul float %21, %22
  ; --- End Fused Kernel ---
  %24 = alloca float, align 4
  store float %23, ptr %24, align 4
  %25 = call ptr @cartan_alloc_sequence(i32 1)
  %26 = alloca ptr, align 8
  store ptr %25, ptr %26, align 8
  %27 = call ptr @cartan_alloc_sequence(i32 1)
  %28 = alloca ptr, align 8
  store ptr %27, ptr %28, align 8
  %29 = alloca float, align 4
  store float 0x3FF0000000000000, ptr %29, align 4
  %30 = alloca float, align 4
  store float 0x4024000000000000, ptr %30, align 4
  %31 = alloca float, align 4
  store float 0x0000000000000000, ptr %31, align 4
  %32 = alloca float, align 4
  store float 0x3F8EB851E0000000, ptr %32, align 4
  %33 = alloca float, align 4
  store float 0x3F50624DE0000000, ptr %33, align 4
  %34 = alloca float, align 4
  store float 0x3F1A36E2E0000000, ptr %34, align 4
  %35 = alloca float, align 4
  store float 0x3F847AE140000000, ptr %35, align 4
  br label %while_cond_3
while_cond_3:
  %36 = load float, ptr %29, align 4
  %37 = load float, ptr %30, align 4
  %38 = fcmp ole float %36, %37
  %39 = uitofp i1 %38 to float
  %40 = fcmp one float %39, 0.0
  br i1 %40, label %while_body_4, label %while_end_5
while_body_4:
  %41 = load float, ptr %26, align 4
  %42 = load float, ptr @.str.0, align 4
  %43 = call float @cartan_file_read_tokens(float %41, float 0x40A0000000000000, float %42)
  %44 = alloca float, align 4
  store float %43, ptr %44, align 4
  %46 = load float, ptr %26, align 4
  %47 = load %GeoMindHybridEngine, ptr %18, align 8
  %48 = call float @GeoMindHybridEngine_process_trajectory(%GeoMindHybridEngine %47, float %46, float 0.0, float 0.0)
  %49 = alloca float, align 4
  store float %48, ptr %49, align 4
  %50 = load float, ptr %49, align 4
  %51 = load float, ptr %28, align 4
  %52 = call float @cartan_tensor_cross_entropy_loss(float %50, float %51)
  %53 = alloca float, align 4
  store float %52, ptr %53, align 4
  ; --- Begin Backward Pass ---
  %54 = load float, ptr %53, align 4
  ; --- End Backward Pass ---
  %55 = load float, ptr %53, align 4
  %56 = fcmp ogt float %55, 0x3FB99999A0000000
  %57 = uitofp i1 %56 to float
  %58 = fcmp one float %57, 0.0
  br i1 %58, label %then_6, label %end_8
then_6:
  ; --- Begin Fused Kernel ---
  %59 = load float, ptr %33, align 4
  %60 = fmul float %59, 0x3FE8000000000000
  ; --- End Fused Kernel ---
  store float %60, ptr %33, align 4
  %61 = load float, ptr %33, align 4
  %62 = load float, ptr %34, align 4
  %63 = fcmp olt float %61, %62
  %64 = uitofp i1 %63 to float
  %65 = fcmp one float %64, 0.0
  br i1 %65, label %then_9, label %end_11
then_9:
  %66 = load float, ptr %34, align 4
  store float %66, ptr %33, align 4
  br label %end_11
end_11:
  br label %end_8
end_8:
  %67 = load float, ptr %53, align 4
  %68 = load float, ptr %32, align 4
  %69 = fcmp olt float %67, %68
  %70 = uitofp i1 %69 to float
  %71 = fcmp one float %70, 0.0
  br i1 %71, label %then_12, label %end_14
then_12:
  ; --- Begin Fused Kernel ---
  %72 = load float, ptr %30, align 4
  %73 = fadd float %72, 0x3FF0000000000000
  ; --- End Fused Kernel ---
  store float %73, ptr %29, align 4
  br label %end_14
end_14:
  ; --- Begin Fused Kernel ---
  %74 = load float, ptr %31, align 4
  %75 = fadd float %74, 0x3FF0000000000000
  ; --- End Fused Kernel ---
  store float %75, ptr %31, align 4
  ; --- Begin Fused Kernel ---
  %76 = load float, ptr %29, align 4
  %77 = fadd float %76, 0x3FF0000000000000
  ; --- End Fused Kernel ---
  store float %77, ptr %29, align 4
  br label %while_cond_3
while_end_5:
  %78 = fptosi float 0x0000000000000000 to i32
  ret i32 %78
unreachable_15:
  ret i32 0
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
@.str.0 = private unnamed_addr constant [22 x i8] c"\64\61\74\61\73\65\74\5f\65\38\5f\63\6f\6f\72\64\73\2e\6e\70\79\00", align 1
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

