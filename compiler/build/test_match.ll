; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"



define i32 @main(i32 %argc, ptr %argv) {
entry:
  store i32 %argc, ptr @global_argc, align 4
  store ptr %argv, ptr @global_argv, align 8
  %1 = load float, ptr @.str.0, align 4
  %2 = ptrtoint ptr @.str.1 to i64
  %3 = sitofp i64 %2 to float
  %4 = fcmp oeq float %1, %3
  br i1 %4, label %match_arm_2, label %match_next_3
match_arm_2:
  %5 = alloca float, align 4
  store float 1.000000, ptr %5, align 4
  br label %match_end_1
match_next_3:
  %6 = ptrtoint ptr @.str.2 to i64
  %7 = sitofp i64 %6 to float
  %8 = fcmp oeq float %1, %7
  br i1 %8, label %match_arm_4, label %match_next_5
match_arm_4:
  %9 = alloca float, align 4
  store float 2.000000, ptr %9, align 4
  br label %match_end_1
match_next_5:
  br label %match_arm_6
match_arm_6:
  %10 = alloca float, align 4
  store float 3.000000, ptr %10, align 4
  br label %match_end_1
match_next_7:
  br label %match_end_1
match_end_1:
  ret i32 0
}

declare ptr @malloc(i64)
declare void @free(ptr)
declare i32 @strcmp(ptr, ptr)
declare ptr @cartan_tensor_alloc(i32, i32)
declare ptr @cartan_tensor_alloc_nd(i32, i32, i32, i32, i32, i32)
declare ptr @cartan_tensor_add(ptr, ptr)
declare ptr @cartan_tensor_sub(ptr, ptr)
declare ptr @cartan_tensor_mul(ptr, ptr)
declare ptr @cartan_tensor_matmul(ptr, ptr)
declare ptr @cartan_tensor_matmul_dynamic(ptr, ptr)
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
declare ptr @cartan_tensor_transpose(ptr)
declare ptr @cartan_tensor_ones_like(ptr)
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

@.str.0 = private unnamed_addr constant [7 x i8] c"\76\69\73\75\61\6c\00", align 1
@.str.1 = private unnamed_addr constant [7 x i8] c"\76\69\73\75\61\6c\00", align 1
@.str.2 = private unnamed_addr constant [6 x i8] c"\61\75\64\69\6f\00", align 1
