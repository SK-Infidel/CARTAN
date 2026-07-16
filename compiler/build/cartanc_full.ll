; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

%GenericBound = type { ptr, ptr }
%Parameter = type { ptr, ptr, ptr, ptr, i32, i32 }
%BlockStmt = type { ptr }
%FunctionDecl = type { ptr, ptr, ptr, ptr, i32, %BlockStmt }
%ExprInteger = type { i32 }
%ExprFloat = type { float }
%ExprStringLiteral = type { ptr }
%ExprIdentifier = type { ptr }
%ExprBinaryOp = type { ptr, ptr, ptr }
%ExprFunctionCall = type { ptr, ptr }
%ExprMethodCall = type { ptr, ptr, ptr }
%ExprPropertyAccess = type { ptr, ptr }
%ExprStructInit = type { ptr, ptr }
%Expr = type { i32, ptr }
%StmtExpr = type { ptr }
%StmtVarDecl = type { ptr, i32, ptr, ptr }
%StmtStructDecl = type { ptr, ptr }
%StmtFieldDecl = type { ptr, ptr }
%StmtImplDecl = type { ptr, ptr, ptr }
%StmtTraitDecl = type { ptr, ptr }
%StmtIf = type { ptr, %BlockStmt, %BlockStmt }
%StmtWhile = type { ptr, %BlockStmt }
%StmtReturn = type { ptr }
%Stmt = type { i32, ptr }
%Token = type { i32, ptr, i32, i32, i32 }
%Lexer = type { ptr, i32, i32, i32 }
%Parser = type { ptr, i32 }
%KernelFusionPass = type {  }
%AlgebraicSimplificationPass = type {  }
%TopologicRewritingPass = type {  }
%MacroPass = type {  }
%AutoDiffPass = type {  }
%LLVMGenerator = type { ptr, ptr }
%Compiler = type { ptr }


define ptr @Lexer_tokenize(%Lexer %arg_self) {
entry:
  %1 = alloca %Lexer, align 8
  store %Lexer %arg_self, ptr %1, align 8
  ; --- Cartan.tree_create ---
  %2 = call ptr @cartan_tree_create()
  %3 = alloca ptr, align 8
  store ptr %2, ptr %3, align 8
  %4 = load ptr, ptr %3, align 8
  ret ptr %4
unreachable_1:
  ret ptr null
}

define ptr @Parser_parse(%Parser %arg_self) {
entry:
  %5 = alloca %Parser, align 8
  store %Parser %arg_self, ptr %5, align 8
  ; --- Cartan.tree_create ---
  %6 = call ptr @cartan_tree_create()
  %7 = alloca ptr, align 8
  store ptr %6, ptr %7, align 8
  %8 = load ptr, ptr %7, align 8
  ret ptr %8
unreachable_2:
  ret ptr null
}

define ptr @KernelFusionPass_optimize(%KernelFusionPass %arg_self, ptr %arg_ast) {
entry:
  %9 = alloca %KernelFusionPass, align 8
  store %KernelFusionPass %arg_self, ptr %9, align 8
  %10 = alloca ptr, align 4
  store ptr %arg_ast, ptr %10, align 4
  %11 = load ptr, ptr %10, align 8
  ret ptr %11
unreachable_3:
  ret ptr null
}

define ptr @AlgebraicSimplificationPass_optimize(%AlgebraicSimplificationPass %arg_self, ptr %arg_ast) {
entry:
  %12 = alloca %AlgebraicSimplificationPass, align 8
  store %AlgebraicSimplificationPass %arg_self, ptr %12, align 8
  %13 = alloca ptr, align 4
  store ptr %arg_ast, ptr %13, align 4
  %14 = load ptr, ptr %13, align 8
  ret ptr %14
unreachable_4:
  ret ptr null
}

define ptr @TopologicRewritingPass_optimize(%TopologicRewritingPass %arg_self, ptr %arg_ast) {
entry:
  %15 = alloca %TopologicRewritingPass, align 8
  store %TopologicRewritingPass %arg_self, ptr %15, align 8
  %16 = alloca ptr, align 4
  store ptr %arg_ast, ptr %16, align 4
  %17 = load ptr, ptr %16, align 8
  ret ptr %17
unreachable_5:
  ret ptr null
}

define ptr @MacroPass_optimize(%MacroPass %arg_self, ptr %arg_ast) {
entry:
  %18 = alloca %MacroPass, align 8
  store %MacroPass %arg_self, ptr %18, align 8
  %19 = alloca ptr, align 4
  store ptr %arg_ast, ptr %19, align 4
  %20 = load ptr, ptr %19, align 8
  ret ptr %20
unreachable_6:
  ret ptr null
}

define ptr @AutoDiffPass_optimize(%AutoDiffPass %arg_self, ptr %arg_ast) {
entry:
  %21 = alloca %AutoDiffPass, align 8
  store %AutoDiffPass %arg_self, ptr %21, align 8
  %22 = alloca ptr, align 4
  store ptr %arg_ast, ptr %22, align 4
  %23 = load ptr, ptr %22, align 8
  ret ptr %23
unreachable_7:
  ret ptr null
}

define ptr @LLVMGenerator_generate(%LLVMGenerator %arg_self, ptr %arg_ast) {
entry:
  %24 = alloca %LLVMGenerator, align 8
  store %LLVMGenerator %arg_self, ptr %24, align 8
  %25 = alloca ptr, align 4
  store ptr %arg_ast, ptr %25, align 4
  %26 = alloca %LLVMGenerator, align 8
  %27 = getelementptr inbounds %LLVMGenerator, ptr %26, i32 0, i32 0
  store ptr @.str.0, ptr %27, align 8
  ; --- Cartan.tree_create ---
  %28 = call ptr @cartan_tree_create()
  %29 = getelementptr inbounds %LLVMGenerator, ptr %26, i32 0, i32 1
  store ptr %28, ptr %29, align 8
  %30 = getelementptr inbounds %LLVMGenerator, ptr %26, i32 0, i32 0
  %31 = load ptr, ptr %30, align 8
  ret ptr %31
unreachable_8:
  ret ptr null
}

define i32 @user_main() {
entry:
  %32 = call i32 (ptr, ...) @printf(ptr @.str.1)
  %33 = call i32 (ptr, ...) @printf(ptr @.str.3, ptr @.str.2)
  %34 = alloca %Lexer, align 8
  %35 = getelementptr inbounds %Lexer, ptr %34, i32 0, i32 0
  store ptr @.str.2, ptr %35, align 8
  %36 = getelementptr inbounds %Lexer, ptr %34, i32 0, i32 1
  store i32 0, ptr %36, align 4
  %37 = getelementptr inbounds %Lexer, ptr %34, i32 0, i32 2
  store i32 1, ptr %37, align 4
  %38 = getelementptr inbounds %Lexer, ptr %34, i32 0, i32 3
  store i32 1, ptr %38, align 4
  %40 = load %Lexer, ptr %34, align 8
  %41 = call ptr @Lexer_tokenize(%Lexer %40)
  %42 = alloca ptr, align 8
  store ptr %41, ptr %42, align 8
  %43 = alloca %Parser, align 8
  %44 = load ptr, ptr %42, align 8
  %45 = getelementptr inbounds %Parser, ptr %43, i32 0, i32 0
  store ptr %44, ptr %45, align 8
  %46 = getelementptr inbounds %Parser, ptr %43, i32 0, i32 1
  store i32 0, ptr %46, align 4
  %48 = load %Parser, ptr %43, align 8
  %49 = call ptr @Parser_parse(%Parser %48)
  %50 = alloca ptr, align 8
  store ptr %49, ptr %50, align 8
  %51 = alloca %KernelFusionPass, align 8
  %53 = load ptr, ptr %50, align 8
  %54 = load %KernelFusionPass, ptr %51, align 8
  %55 = call ptr @KernelFusionPass_optimize(%KernelFusionPass %54, ptr %53)
  store ptr %55, ptr %50, align 8
  %56 = alloca %LLVMGenerator, align 8
  %57 = getelementptr inbounds %LLVMGenerator, ptr %56, i32 0, i32 0
  store ptr @.str.4, ptr %57, align 8
  ; --- Cartan.tree_create ---
  %58 = call ptr @cartan_tree_create()
  %59 = getelementptr inbounds %LLVMGenerator, ptr %56, i32 0, i32 1
  store ptr %58, ptr %59, align 8
  %61 = load ptr, ptr %50, align 8
  %62 = load %LLVMGenerator, ptr %56, align 8
  %63 = call ptr @LLVMGenerator_generate(%LLVMGenerator %62, ptr %61)
  %64 = alloca ptr, align 8
  store ptr %63, ptr %64, align 8
  %65 = call i32 (ptr, ...) @printf(ptr @.str.5)
  ret i32 0
unreachable_9:
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
declare ptr @cartan_tensor_alloc(i32, i32)
declare ptr @cartan_tree_create()
declare void @cartan_tree_push(ptr, ptr)
declare ptr @cartan_tree_get(ptr, i32)
declare i32 @cartan_tree_len(ptr)
declare i32 @printf(ptr, ...)
declare ptr @cartan_tensor_alloc_nd(i32, i32, i32, i32, i32, i32)
declare ptr @cartan_tensor_linear_relu(ptr, ptr, ptr)
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
declare ptr @cartan_rt_parallel_transport(ptr, ptr, ptr)
declare void @cartan_emit_spike(float)
declare ptr @cartan_init_elastic_vocabulary()
declare ptr @cartan_init_sieving_cache()
declare ptr @cartan_init_fractal_attention()
declare ptr @cartan_stream_init(ptr, ptr)
declare ptr @cartan_init_spike()
declare ptr @cartan_init_neuron()
declare void @cartan_rt_register_capability(ptr, ptr)
declare ptr @cartan_rt_load_aer(ptr)
declare void @cartan_sandbox_hot_swap(ptr, ptr)
declare ptr @cartan_tensor_graft(ptr)
declare ptr @cartan_tensor_translation_barrier(ptr, ptr)
declare ptr @cartan_alloc_parameter_adam(i32)
declare ptr @cartan_alloc_parameter_adam_nd(i32, i32, i32, i32, i32)
declare ptr @cartan_alloc_sequence(i32)
declare ptr @cartan_alloc_block(i32)
declare ptr @cartan_rt_alloc_lattice(i32, i32)
declare ptr @cartan_rt_alloc_tree(i32)
declare ptr @cartan_rt_tree_search_mcts(ptr, ptr)
declare void @cartan_rt_multimodal_sync_start()
declare void @cartan_rt_multimodal_sync_end()
declare void @cartan_rt_vmap_begin()
declare void @cartan_rt_vmap_end()
declare void @cartan_rt_doubt_begin()
declare void @cartan_rt_doubt_end()
declare void @cartan_rt_chain_begin()
declare void @cartan_rt_chain_end()
declare void @cartan_rt_route_begin()
declare void @cartan_rt_route_end()
declare void @cartan_rt_grok_begin()
declare void @cartan_rt_grok_end()
declare void @cartan_rt_override_begin()
declare void @cartan_rt_override_end()
declare ptr @cartan_rt_paged_attention(ptr, ptr, ptr)
declare ptr @cartan_tensor_transpose(ptr)
declare ptr @cartan_tensor_ones_like(ptr)
declare void @cartan_absorb_weights(ptr, ptr)
declare void @cartan_project_vocab(ptr, ptr)
declare i32 @cartan_pattern_match(ptr, ptr)
declare ptr @cartan_rt_transform(ptr, ptr)
declare ptr @cartan_tokenize_bpe(ptr, ptr)
declare void @cartan_align_spans(ptr, ptr, ptr)
declare void @cartan_free_compute_graph()
declare void @cartan_fluid_precision_start(ptr, ptr)
declare void @cartan_fluid_precision_end()
declare void @cartan_sparsity_start(i32, float)
declare void @cartan_sparsity_end()
declare void @cartan_prune_graph(float)
declare ptr @cartan_tensor_quantize_int8(ptr)
declare ptr @cartan_internal_import_onnx(ptr)
@.str.0 = private unnamed_addr constant [1 x i8] c"\00", align 1
@.str.1 = private unnamed_addr constant [45 x i8] c"\43\41\52\54\41\4e\20\4e\61\74\69\76\65\20\43\6f\6d\70\69\6c\65\72\20\76\30\2e\32\2e\30\20\28\53\65\6c\66\2d\48\6f\73\74\65\64\29\0a\00", align 1
@.str.2 = private unnamed_addr constant [31 x i8] c"\2e\2e\2f\63\61\72\74\61\6e\5f\73\72\63\2f\74\65\73\74\5f\70\68\61\73\65\31\32\2e\63\61\72\00", align 1
@.str.3 = private unnamed_addr constant [17 x i8] c"\43\6f\6d\70\69\6c\69\6e\67\20\25\73\2e\2e\2e\0a\00", align 1
@.str.4 = private unnamed_addr constant [1 x i8] c"\00", align 1
@.str.5 = private unnamed_addr constant [37 x i8] c"\43\6f\6d\70\69\6c\61\74\69\6f\6e\20\63\6f\6d\70\6c\65\74\65\64\20\73\75\63\63\65\73\73\66\75\6c\6c\79\2e\0a\00", align 1
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

