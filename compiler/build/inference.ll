; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

%ConsoleStream = type {  }
%ArgParser = type {  }

declare i32 @printf(ptr, ...)
declare ptr @fopen(ptr, ptr)
declare i32 @fread(ptr, i32, i32, ptr)
declare i32 @fseek(ptr, i32, i32)
declare i32 @fclose(ptr)
declare i32 @clock()
declare i32 @cartan_console_read(ptr, i32)
declare i32 @cartan_get_arg_int(ptr, i32)
declare ptr @cartan_get_arg_float(ptr, ptr)
declare ptr @cartan_get_arg_string(ptr, ptr)

define ptr @ConsoleStream_read_line(%ConsoleStream %arg_this, ptr %arg_buffer, ptr %arg_max_len) {
entry:
  %1 = alloca %ConsoleStream, align 8
  store %ConsoleStream %arg_this, ptr %1, align 8
  %2 = alloca ptr, align 4
  store ptr %arg_buffer, ptr %2, align 4
  %3 = alloca ptr, align 4
  store ptr %arg_max_len, ptr %3, align 4
  %4 = load ptr, ptr %2, align 8
  %5 = load ptr, ptr %3, align 8
  %6 = call i32 @cartan_console_read(ptr %4, ptr %5)
  %7 = sitofp i32 %6 to float
  %8 = fptoui float %7 to i64
  %9 = inttoptr i64 %8 to ptr
  ret ptr %9
unreachable_1:
  ret ptr null
}

define void @ConsoleStream_print(%ConsoleStream %arg_this, ptr %arg_text) {
entry:
  %10 = alloca %ConsoleStream, align 8
  store %ConsoleStream %arg_this, ptr %10, align 8
  %11 = alloca ptr, align 4
  store ptr %arg_text, ptr %11, align 4
  %12 = load ptr, ptr %11, align 8
  %13 = fpext float %12 to double
  %14 = call i32 (ptr, ...) @printf(double %13)
  ret void
}

define ptr @ArgParser_get_int(%ArgParser %arg_this, ptr %arg_key, ptr %arg_default_val) {
entry:
  %15 = alloca %ArgParser, align 8
  store %ArgParser %arg_this, ptr %15, align 8
  %16 = alloca ptr, align 4
  store ptr %arg_key, ptr %16, align 4
  %17 = alloca ptr, align 4
  store ptr %arg_default_val, ptr %17, align 4
  %18 = load ptr, ptr %16, align 8
  %19 = load ptr, ptr %17, align 8
  %20 = call i32 @cartan_get_arg_int(ptr %18, ptr %19)
  %21 = sitofp i32 %20 to float
  %22 = fptoui float %21 to i64
  %23 = inttoptr i64 %22 to ptr
  ret ptr %23
unreachable_2:
  ret ptr null
}

define ptr @ArgParser_get_float(%ArgParser %arg_this, ptr %arg_key, ptr %arg_default_val) {
entry:
  %24 = alloca %ArgParser, align 8
  store %ArgParser %arg_this, ptr %24, align 8
  %25 = alloca ptr, align 4
  store ptr %arg_key, ptr %25, align 4
  %26 = alloca ptr, align 4
  store ptr %arg_default_val, ptr %26, align 4
  %27 = load ptr, ptr %25, align 8
  %28 = load ptr, ptr %26, align 8
  %29 = call ptr @cartan_get_arg_float(ptr %27, ptr %28)
  ret ptr %29
unreachable_3:
  ret ptr null
}

define ptr @ArgParser_get_string(%ArgParser %arg_this, ptr %arg_key, ptr %arg_default_val) {
entry:
  %30 = alloca %ArgParser, align 8
  store %ArgParser %arg_this, ptr %30, align 8
  %31 = alloca ptr, align 4
  store ptr %arg_key, ptr %31, align 4
  %32 = alloca ptr, align 4
  store ptr %arg_default_val, ptr %32, align 4
  %33 = load ptr, ptr %31, align 8
  %34 = load ptr, ptr %32, align 8
  %35 = call ptr @cartan_get_arg_string(ptr %33, ptr %34)
  ret ptr %35
unreachable_4:
  ret ptr null
}

define i32 @user_main() {
entry:
  ; --- Struct Instantiation: GeoMindHybridEngine ---
  %36 = alloca %GeoMindHybridEngine
  ; --- Struct Instantiation: ConsoleStream ---
  %37 = alloca %ConsoleStream
  ; --- Struct Instantiation: ArgParser ---
  %38 = alloca %ArgParser
  %40 = load %ArgParser, ptr %38, align 8
  %41 = call ptr @ArgParser_get_int(%ArgParser %40, ptr @.str.0, float 0x4049000000000000)
  %42 = alloca ptr, align 8
  store ptr %41, ptr %42, align 8
  %44 = load %ArgParser, ptr %38, align 8
  %45 = call ptr @ArgParser_get_float(%ArgParser %44, ptr @.str.1, float 0x3FB99999A0000000)
  %46 = alloca ptr, align 8
  store ptr %45, ptr %46, align 8
  %48 = load %ArgParser, ptr %38, align 8
  %49 = call ptr @ArgParser_get_string(%ArgParser %48, ptr @.str.2, ptr @.str.3)
  %50 = alloca ptr, align 8
  store ptr %49, ptr %50, align 8
  %52 = load %ConsoleStream, ptr %37, align 8
  call void @ConsoleStream_print(%ConsoleStream %52, ptr @.str.4)
  %53 = alloca float, align 4
  store float 0x0000000000000000, ptr %53, align 4
  %54 = call ptr @cartan_alloc_sequence(i32 4096)
  %55 = alloca ptr, align 8
  store ptr %54, ptr %55, align 8
  %56 = call ptr @cartan_alloc_sequence(i32 2048)
  %57 = alloca ptr, align 8
  store ptr %56, ptr %57, align 8
  br label %while_cond_5
while_cond_5:
  %58 = fcmp one float 0.0, 0.0
  br i1 %58, label %while_body_6, label %while_end_7
while_body_6:
  %60 = load %ConsoleStream, ptr %37, align 8
  call void @ConsoleStream_print(%ConsoleStream %60, ptr @.str.5)
  %62 = load float, ptr %57, align 4
  %63 = load %ConsoleStream, ptr %37, align 8
  %64 = call ptr @ConsoleStream_read_line(%ConsoleStream %63, float %62, float 0x40A0000000000000)
  %65 = alloca ptr, align 8
  store ptr %64, ptr %65, align 8
  %66 = load ptr, ptr %65, align 8
  %67 = ptrtoint ptr %66 to i64
  %68 = sitofp i64 %67 to float
  %69 = fcmp ole float %68, 0x0000000000000000
  %70 = uitofp i1 %69 to float
  %71 = fcmp one float %70, 0.0
  br i1 %71, label %then_8, label %end_10
then_8:
  br label %while_end_7
unreachable_11:
  br label %end_10
end_10:
  %73 = load %ConsoleStream, ptr %37, align 8
  call void @ConsoleStream_print(%ConsoleStream %73, ptr @.str.6)
  %74 = alloca float, align 4
  store float 0x0000000000000000, ptr %74, align 4
  br label %while_cond_12
while_cond_12:
  %75 = load float, ptr %74, align 4
  %76 = load ptr, ptr %42, align 8
  %77 = ptrtoint ptr %76 to i64
  %78 = sitofp i64 %77 to float
  %79 = fcmp olt float %75, %78
  %80 = uitofp i1 %79 to float
  %81 = fcmp one float %80, 0.0
  br i1 %81, label %while_body_13, label %while_end_14
while_body_13:
  %83 = load float, ptr %55, align 4
  %84 = load %GeoMindHybridEngine, ptr %36, align 8
  %85 = call float @GeoMindHybridEngine_process_trajectory(%GeoMindHybridEngine %84, float %83, float 0.0, float 0.0)
  %86 = alloca float, align 4
  store float %85, ptr %86, align 4
  %87 = load float, ptr %86, align 4
  %88 = load ptr, ptr %46, align 8
  %89 = call float @cartan_sample_top_k(float %87, ptr %88, float 0x4044000000000000)
  %90 = alloca float, align 4
  store float %89, ptr %90, align 4
  %91 = load float, ptr %90, align 4
  %92 = call float @cartan_print_token(float %91)
  %93 = load float, ptr %90, align 4
  %94 = fcmp oeq float %93, 0x3FF0000000000000
  %95 = uitofp i1 %94 to float
  %96 = fcmp one float %95, 0.0
  br i1 %96, label %then_15, label %end_17
then_15:
  br label %while_end_14
unreachable_18:
  br label %end_17
end_17:
  ; --- Begin Fused Kernel ---
  %97 = load float, ptr %74, align 4
  %98 = fadd float %97, 0x3FF0000000000000
  ; --- End Fused Kernel ---
  store float %98, ptr %74, align 4
  br label %while_cond_12
while_end_14:
  %100 = load %ConsoleStream, ptr %37, align 8
  call void @ConsoleStream_print(%ConsoleStream %100, ptr @.str.7)
  br label %while_cond_5
while_end_7:
  %102 = load %ConsoleStream, ptr %37, align 8
  call void @ConsoleStream_print(%ConsoleStream %102, ptr @.str.8)
  %103 = fptosi float 0x0000000000000000 to i32
  ret i32 %103
unreachable_19:
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
@.str.0 = private unnamed_addr constant [8 x i8] c"\2d\2d\72\61\6e\67\65\00", align 1
@.str.1 = private unnamed_addr constant [14 x i8] c"\2d\2d\74\65\6d\70\65\72\61\74\75\72\65\00", align 1
@.str.2 = private unnamed_addr constant [13 x i8] c"\2d\2d\63\68\65\63\6b\70\6f\69\6e\74\00", align 1
@.str.3 = private unnamed_addr constant [39 x i8] c"\63\68\65\63\6b\70\6f\69\6e\74\73\2f\65\38\5f\61\67\65\6e\74\5f\6d\6f\64\65\6c\2e\73\61\66\65\74\65\6e\73\6f\72\73\00", align 1
@.str.4 = private unnamed_addr constant [42 x i8] c"\49\6e\69\74\69\61\6c\69\7a\69\6e\67\20\47\65\6f\4d\69\6e\64\20\4e\61\74\69\76\65\20\56\6f\69\63\65\20\42\6f\78\2e\2e\2e\0a\00", align 1
@.str.5 = private unnamed_addr constant [7 x i8] c"\0a\59\6f\75\3a\20\00", align 1
@.str.6 = private unnamed_addr constant [10 x i8] c"\47\65\6f\4d\69\6e\64\3a\20\00", align 1
@.str.7 = private unnamed_addr constant [2 x i8] c"\0a\00", align 1
@.str.8 = private unnamed_addr constant [29 x i8] c"\0a\53\68\75\74\74\69\6e\67\20\64\6f\77\6e\20\56\6f\69\63\65\20\42\6f\78\2e\2e\2e\0a\00", align 1
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

