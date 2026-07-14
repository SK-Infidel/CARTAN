; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

%ArgParser = type {  }
%ConsoleStream = type {  }

declare i32 @cartan_get_arg_int(ptr, i32)
declare ptr @cartan_get_arg_float(ptr, ptr)
declare ptr @cartan_get_arg_string(ptr, ptr)
declare i32 @cartan_has_arg(ptr)
declare i32 @printf(ptr, ...)
declare ptr @fopen(ptr, ptr)
declare i32 @fread(ptr, i32, i32, ptr)
declare i32 @fseek(ptr, i32, i32)
declare i32 @fclose(ptr)
declare i32 @clock()
declare i32 @cartan_console_read(ptr, i32)

define ptr @ArgParser_get_int(%ArgParser %arg_this, ptr %arg_key, ptr %arg_default_val) {
entry:
  %1 = alloca %ArgParser, align 8
  store %ArgParser %arg_this, ptr %1, align 8
  %2 = alloca ptr, align 4
  store ptr %arg_key, ptr %2, align 4
  %3 = alloca ptr, align 4
  store ptr %arg_default_val, ptr %3, align 4
  %4 = load ptr, ptr %2, align 8
  %5 = load ptr, ptr %3, align 8
  %6 = call i32 @cartan_get_arg_int(ptr %4, ptr %5)
  %7 = sitofp i32 %6 to float
  %8 = fptoui float %7 to i64
  %9 = inttoptr i64 %8 to ptr
  ret ptr %9
unreachable_1:
  ret ptr null
}

define ptr @ArgParser_get_float(%ArgParser %arg_this, ptr %arg_key, ptr %arg_default_val) {
entry:
  %10 = alloca %ArgParser, align 8
  store %ArgParser %arg_this, ptr %10, align 8
  %11 = alloca ptr, align 4
  store ptr %arg_key, ptr %11, align 4
  %12 = alloca ptr, align 4
  store ptr %arg_default_val, ptr %12, align 4
  %13 = load ptr, ptr %11, align 8
  %14 = load ptr, ptr %12, align 8
  %15 = call ptr @cartan_get_arg_float(ptr %13, ptr %14)
  ret ptr %15
unreachable_2:
  ret ptr null
}

define ptr @ArgParser_get_string(%ArgParser %arg_this, ptr %arg_key, ptr %arg_default_val) {
entry:
  %16 = alloca %ArgParser, align 8
  store %ArgParser %arg_this, ptr %16, align 8
  %17 = alloca ptr, align 4
  store ptr %arg_key, ptr %17, align 4
  %18 = alloca ptr, align 4
  store ptr %arg_default_val, ptr %18, align 4
  %19 = load ptr, ptr %17, align 8
  %20 = load ptr, ptr %18, align 8
  %21 = call ptr @cartan_get_arg_string(ptr %19, ptr %20)
  ret ptr %21
unreachable_3:
  ret ptr null
}

define ptr @ArgParser_has_arg(%ArgParser %arg_this, ptr %arg_key) {
entry:
  %22 = alloca %ArgParser, align 8
  store %ArgParser %arg_this, ptr %22, align 8
  %23 = alloca ptr, align 4
  store ptr %arg_key, ptr %23, align 4
  %24 = load ptr, ptr %23, align 8
  %25 = call i32 @cartan_has_arg(ptr %24)
  %26 = sitofp i32 %25 to float
  %27 = fptoui float %26 to i64
  %28 = inttoptr i64 %27 to ptr
  ret ptr %28
unreachable_4:
  ret ptr null
}

define ptr @ConsoleStream_read_line(%ConsoleStream %arg_this, ptr %arg_buffer, ptr %arg_max_len) {
entry:
  %29 = alloca %ConsoleStream, align 8
  store %ConsoleStream %arg_this, ptr %29, align 8
  %30 = alloca ptr, align 4
  store ptr %arg_buffer, ptr %30, align 4
  %31 = alloca ptr, align 4
  store ptr %arg_max_len, ptr %31, align 4
  %32 = load ptr, ptr %30, align 8
  %33 = load ptr, ptr %31, align 8
  %34 = call i32 @cartan_console_read(ptr %32, ptr %33)
  %35 = sitofp i32 %34 to float
  %36 = fptoui float %35 to i64
  %37 = inttoptr i64 %36 to ptr
  ret ptr %37
unreachable_5:
  ret ptr null
}

define void @ConsoleStream_print(%ConsoleStream %arg_this, ptr %arg_text) {
entry:
  %38 = alloca %ConsoleStream, align 8
  store %ConsoleStream %arg_this, ptr %38, align 8
  %39 = alloca ptr, align 4
  store ptr %arg_text, ptr %39, align 4
  %40 = load ptr, ptr %39, align 8
  %41 = call i32 (ptr, ...) @printf(ptr %40)
  ret void
}

define dso_local dllexport i32 @trigger_system_action(ptr %arg_action_type, float %arg_data) {
entry:
  %42 = alloca ptr, align 4
  store ptr %arg_action_type, ptr %42, align 4
  %43 = alloca float, align 4
  store float %arg_data, ptr %43, align 4
  ; --- Struct Instantiation: ConsoleStream ---
  %44 = alloca %ConsoleStream
  %46 = load %ConsoleStream, ptr %44, align 8
  call void @ConsoleStream_print(%ConsoleStream %46, ptr @.str.0)
  %48 = load ptr, ptr %42, align 8
  %49 = load %ConsoleStream, ptr %44, align 8
  call void @ConsoleStream_print(%ConsoleStream %49, ptr %48)
  %51 = load %ConsoleStream, ptr %44, align 8
  call void @ConsoleStream_print(%ConsoleStream %51, ptr @.str.1)
  %52 = fptosi float 0x3FF0000000000000 to i32
  ret i32 %52
unreachable_6:
  ret i32 0
}

define i32 @user_main() {
entry:
  ; --- Struct Instantiation: ConsoleStream ---
  %53 = alloca %ConsoleStream
  %55 = load %ConsoleStream, ptr %53, align 8
  call void @ConsoleStream_print(%ConsoleStream %55, ptr @.str.2)
  %56 = call ptr @cartan_alloc_sequence(i32 256)
  %57 = alloca ptr, align 8
  store ptr %56, ptr %57, align 8
  %58 = call ptr @cartan_alloc_block(i32 16)
  %59 = alloca ptr, align 8
  store ptr %58, ptr %59, align 8
  %60 = call ptr @cartan_alloc_parameter_adam_nd(i32 2, i32 16, i32 16, i32 1, i32 1)
  %61 = alloca ptr, align 8
  store ptr %60, ptr %61, align 8
  %62 = call ptr @cartan_alloc_parameter_adam(i32 16)
  %63 = alloca ptr, align 8
  store ptr %62, ptr %63, align 8
  %64 = load float, ptr @.str.3, align 4
  %65 = ptrtoint ptr @.str.4 to i64
  %66 = sitofp i64 %65 to float
  %67 = fcmp oeq float %64, %66
  br i1 %67, label %match_arm_8, label %match_next_9
match_arm_8:
  %69 = load %ConsoleStream, ptr %53, align 8
  call void @ConsoleStream_print(%ConsoleStream %69, ptr @.str.5)
  br label %match_end_7
match_next_9:
  %70 = ptrtoint ptr @.str.6 to i64
  %71 = sitofp i64 %70 to float
  %72 = fcmp oeq float %64, %71
  br i1 %72, label %match_arm_10, label %match_next_11
match_arm_10:
  %74 = load %ConsoleStream, ptr %53, align 8
  call void @ConsoleStream_print(%ConsoleStream %74, ptr @.str.7)
  br label %match_end_7
match_next_11:
  br label %match_arm_12
match_arm_12:
  %76 = load %ConsoleStream, ptr %53, align 8
  call void @ConsoleStream_print(%ConsoleStream %76, ptr @.str.8)
  br label %match_end_7
match_next_13:
  br label %match_end_7
match_end_7:
  %78 = load %ConsoleStream, ptr %53, align 8
  call void @ConsoleStream_print(%ConsoleStream %78, ptr @.str.9)
  %79 = call i32 @trigger_system_action(ptr @.str.10, float 0x0000000000000000)
  %80 = sitofp i32 %79 to float
  %82 = load %ConsoleStream, ptr %53, align 8
  call void @ConsoleStream_print(%ConsoleStream %82, ptr @.str.11)
  %83 = fptosi float 0x0000000000000000 to i32
  ret i32 %83
unreachable_14:
  ret i32 0
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
@.str.0 = private unnamed_addr constant [26 x i8] c"\53\79\73\74\65\6d\20\41\63\74\69\6f\6e\20\54\72\69\67\67\65\72\65\64\3a\20\00", align 1
@.str.1 = private unnamed_addr constant [2 x i8] c"\0a\00", align 1
@.str.2 = private unnamed_addr constant [27 x i8] c"\49\6e\69\74\69\61\6c\69\7a\69\6e\67\20\45\32\45\20\4d\6f\64\65\6c\2e\2e\2e\0a\00", align 1
@.str.3 = private unnamed_addr constant [6 x i8] c"\56\69\64\65\6f\00", align 1
@.str.4 = private unnamed_addr constant [6 x i8] c"\56\69\64\65\6f\00", align 1
@.str.5 = private unnamed_addr constant [28 x i8] c"\50\72\6f\63\65\73\73\69\6e\67\20\56\69\64\65\6f\20\53\74\72\65\61\6d\2e\2e\2e\0a\00", align 1
@.str.6 = private unnamed_addr constant [6 x i8] c"\41\75\64\69\6f\00", align 1
@.str.7 = private unnamed_addr constant [28 x i8] c"\50\72\6f\63\65\73\73\69\6e\67\20\41\75\64\69\6f\20\53\74\72\65\61\6d\2e\2e\2e\0a\00", align 1
@.str.8 = private unnamed_addr constant [30 x i8] c"\50\72\6f\63\65\73\73\69\6e\67\20\44\65\66\61\75\6c\74\20\53\74\72\65\61\6d\2e\2e\2e\0a\00", align 1
@.str.9 = private unnamed_addr constant [26 x i8] c"\54\72\69\67\67\65\72\69\6e\67\20\61\67\65\6e\74\20\68\6f\6f\6b\2e\2e\2e\0a\00", align 1
@.str.10 = private unnamed_addr constant [14 x i8] c"\4c\61\75\6e\63\68\42\72\6f\77\73\65\72\00", align 1
@.str.11 = private unnamed_addr constant [7 x i8] c"\44\6f\6e\65\21\0a\00", align 1
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

