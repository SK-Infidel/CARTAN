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
  store float 0x40A0000000000000, ptr %19, align 4
  %20 = alloca float, align 4
  store float 0x4030000000000000, ptr %20, align 4
  ; --- Struct Instantiation: WebScraper ---
  %21 = alloca %WebScraper
  %22 = getelementptr inbounds %WebScraper, ptr %21, i32 0, i32 0
  store float 0.0, ptr %22
  %24 = load %WebScraper, ptr %21, align 8
  %25 = call float @WebScraper_pull_text(%WebScraper %24, ptr @.str.0)
  %26 = alloca float, align 4
  store float %25, ptr %26, align 4
  %27 = alloca float, align 4
  store float 0x4024000000000000, ptr %27, align 4
  %28 = alloca float, align 4
  store float 0x3FF0000000000000, ptr %28, align 4
  %29 = alloca float, align 4
  store float 0x0000000000000000, ptr %29, align 4
  br label %while_cond_3
while_cond_3:
  %30 = load float, ptr %28, align 4
  %31 = load float, ptr %27, align 4
  %32 = fcmp ole float %30, %31
  %33 = uitofp i1 %32 to float
  %34 = fcmp one float %33, 0.0
  br i1 %34, label %while_body_4, label %while_end_5
while_body_4:
  %36 = load %GeoMindHybridEngine, ptr %18, align 8
  %37 = call float @GeoMindHybridEngine_process_trajectory(%GeoMindHybridEngine %36, float 0.0, float 0.0, float 0.0)
  %38 = alloca float, align 4
  store float %37, ptr %38, align 4
  %39 = load float, ptr %38, align 4
  %40 = call float @cartan_tensor_spherical_cosine_loss(float %39, float null)
  %41 = alloca float, align 4
  store float %40, ptr %41, align 4
  ; --- Begin Backward Pass ---
  %42 = load float, ptr %41, align 4
  ; --- End Backward Pass ---
  ; --- Begin Fused Kernel ---
  %43 = load float, ptr %29, align 4
  %44 = fadd float %43, 0x3FF0000000000000
  ; --- End Fused Kernel ---
  store float %44, ptr %29, align 4
  ; --- Begin Fused Kernel ---
  %45 = load float, ptr %28, align 4
  %46 = fadd float %45, 0x3FF0000000000000
  ; --- End Fused Kernel ---
  store float %46, ptr %28, align 4
  br label %while_cond_3
while_end_5:
  %47 = fptosi float 0x0000000000000000 to i32
  ret i32 %47
unreachable_6:
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
@.str.0 = private unnamed_addr constant [49 x i8] c"\68\74\74\70\73\3a\2f\2f\69\6e\74\65\72\6e\61\6c\2d\64\61\74\61\73\65\74\73\2f\67\65\6f\6d\65\74\72\79\5f\72\65\67\69\73\74\72\79\2e\6a\73\6f\6e\00", align 1
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

