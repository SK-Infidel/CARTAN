; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

%ArgParser = type {  }
%ConsoleStream = type {  }

declare float @cartan_get_arg_int(ptr, float)
declare float @cartan_get_arg_float(ptr, float)
declare ptr @cartan_get_arg_string(ptr, ptr)
declare float @cartan_has_arg(ptr)
declare float @printf(ptr, ...)
declare ptr @fopen(ptr, ptr)
declare float @fread(ptr, float, float, ptr)
declare float @fseek(ptr, float, float)
declare float @fclose(ptr)
declare float @clock()
declare float @cartan_console_read(ptr, float)

define float @ArgParser_get_int(%ArgParser %arg_this, ptr %arg_key, float %arg_default_val) {
entry:
  %1 = alloca %ArgParser, align 8
  store %ArgParser %arg_this, ptr %1, align 8
  %2 = alloca ptr, align 4
  store ptr %arg_key, ptr %2, align 4
  %3 = alloca float, align 4
  store float %arg_default_val, ptr %3, align 4
  %4 = load ptr, ptr %2, align 8
  %5 = load float, ptr %3, align 4
  %6 = call float @cartan_get_arg_int(ptr %4, float %5)
  ret float %6
unreachable_1:
  ret float 0.0
}

define float @ArgParser_get_float(%ArgParser %arg_this, ptr %arg_key, float %arg_default_val) {
entry:
  %7 = alloca %ArgParser, align 8
  store %ArgParser %arg_this, ptr %7, align 8
  %8 = alloca ptr, align 4
  store ptr %arg_key, ptr %8, align 4
  %9 = alloca float, align 4
  store float %arg_default_val, ptr %9, align 4
  %10 = load ptr, ptr %8, align 8
  %11 = load float, ptr %9, align 4
  %12 = call float @cartan_get_arg_float(ptr %10, float %11)
  ret float %12
unreachable_2:
  ret float 0.0
}

define ptr @ArgParser_get_string(%ArgParser %arg_this, ptr %arg_key, ptr %arg_default_val) {
entry:
  %13 = alloca %ArgParser, align 8
  store %ArgParser %arg_this, ptr %13, align 8
  %14 = alloca ptr, align 4
  store ptr %arg_key, ptr %14, align 4
  %15 = alloca ptr, align 4
  store ptr %arg_default_val, ptr %15, align 4
  %16 = load ptr, ptr %14, align 8
  %17 = load ptr, ptr %15, align 8
  %18 = call ptr @cartan_get_arg_string(ptr %16, ptr %17)
  ret ptr %18
unreachable_3:
  ret ptr null
}

define float @ArgParser_has_arg(%ArgParser %arg_this, ptr %arg_key) {
entry:
  %19 = alloca %ArgParser, align 8
  store %ArgParser %arg_this, ptr %19, align 8
  %20 = alloca ptr, align 4
  store ptr %arg_key, ptr %20, align 4
  %21 = load ptr, ptr %20, align 8
  %22 = call float @cartan_has_arg(ptr %21)
  ret float %22
unreachable_4:
  ret float 0.0
}

define float @ConsoleStream_read_line(%ConsoleStream %arg_this, ptr %arg_buffer, float %arg_max_len) {
entry:
  %23 = alloca %ConsoleStream, align 8
  store %ConsoleStream %arg_this, ptr %23, align 8
  %24 = alloca ptr, align 4
  store ptr %arg_buffer, ptr %24, align 4
  %25 = alloca float, align 4
  store float %arg_max_len, ptr %25, align 4
  %26 = load ptr, ptr %24, align 8
  %27 = load float, ptr %25, align 4
  %28 = call float @cartan_console_read(ptr %26, float %27)
  ret float %28
unreachable_5:
  ret float 0.0
}

define void @ConsoleStream_print(%ConsoleStream %arg_this, ptr %arg_text) {
entry:
  %29 = alloca %ConsoleStream, align 8
  store %ConsoleStream %arg_this, ptr %29, align 8
  %30 = alloca ptr, align 4
  store ptr %arg_text, ptr %30, align 4
  %31 = load ptr, ptr %30, align 8
  %32 = call i32 (ptr, ...) @printf(ptr %31)
  ret void
}

define float @run_causal_pretrain(ptr %arg_dataset, float %arg_epochs, float %arg_seq_len, float %arg_batch_size, float %arg_debug) {
entry:
  %33 = alloca ptr, align 4
  store ptr %arg_dataset, ptr %33, align 4
  %34 = alloca float, align 4
  store float %arg_epochs, ptr %34, align 4
  %35 = alloca float, align 4
  store float %arg_seq_len, ptr %35, align 4
  %36 = alloca float, align 4
  store float %arg_batch_size, ptr %36, align 4
  %37 = alloca float, align 4
  store float %arg_debug, ptr %37, align 4
  ; --- Struct Instantiation: ConsoleStream ---
  %38 = alloca %ConsoleStream
  %39 = load float, ptr %37, align 4
  %40 = fcmp oeq float %39, 0x3FF0000000000000
  %41 = uitofp i1 %40 to float
  %42 = fcmp one float %41, 0.0
  br i1 %42, label %then_6, label %else_7
then_6:
  %44 = load %ConsoleStream, ptr %38, align 8
  call void @ConsoleStream_print(%ConsoleStream %44, ptr @.str.0)
  %46 = load %ConsoleStream, ptr %38, align 8
  call void @ConsoleStream_print(%ConsoleStream %46, ptr @.str.1)
  %48 = load %ConsoleStream, ptr %38, align 8
  call void @ConsoleStream_print(%ConsoleStream %48, ptr @.str.2)
  br label %end_8
else_7:
  %50 = load %ConsoleStream, ptr %38, align 8
  call void @ConsoleStream_print(%ConsoleStream %50, ptr @.str.3)
  br label %end_8
end_8:
  %51 = call ptr @cartan_alloc_sequence(i32 256)
  %52 = alloca ptr, align 8
  store ptr %51, ptr %52, align 8
  %53 = call ptr @cartan_alloc_block(i32 16)
  %54 = alloca ptr, align 8
  store ptr %53, ptr %54, align 8
  %55 = call ptr @cartan_alloc_parameter_adam_nd(i32 2, i32 16, i32 16, i32 1, i32 1)
  %56 = alloca ptr, align 8
  store ptr %55, ptr %56, align 8
  %57 = call ptr @cartan_alloc_parameter_adam(i32 16)
  %58 = alloca ptr, align 8
  store ptr %57, ptr %58, align 8
  %59 = load float, ptr %37, align 4
  %60 = fcmp oeq float %59, 0x3FF0000000000000
  %61 = uitofp i1 %60 to float
  %62 = fcmp one float %61, 0.0
  br i1 %62, label %then_9, label %end_11
then_9:
  %64 = load %ConsoleStream, ptr %38, align 8
  call void @ConsoleStream_print(%ConsoleStream %64, ptr @.str.4)
  br label %end_11
end_11:
  %66 = load %ConsoleStream, ptr %38, align 8
  call void @ConsoleStream_print(%ConsoleStream %66, ptr @.str.5)
  ret float 0x0000000000000000
unreachable_12:
  ret float 0.0
}

define float @run_sft_train(ptr %arg_dataset, float %arg_epochs, float %arg_debug) {
entry:
  %67 = alloca ptr, align 4
  store ptr %arg_dataset, ptr %67, align 4
  %68 = alloca float, align 4
  store float %arg_epochs, ptr %68, align 4
  %69 = alloca float, align 4
  store float %arg_debug, ptr %69, align 4
  ; --- Struct Instantiation: ConsoleStream ---
  %70 = alloca %ConsoleStream
  %71 = load float, ptr %69, align 4
  %72 = fcmp oeq float %71, 0x3FF0000000000000
  %73 = uitofp i1 %72 to float
  %74 = fcmp one float %73, 0.0
  br i1 %74, label %then_13, label %else_14
then_13:
  %76 = load %ConsoleStream, ptr %70, align 8
  call void @ConsoleStream_print(%ConsoleStream %76, ptr @.str.6)
  %78 = load %ConsoleStream, ptr %70, align 8
  call void @ConsoleStream_print(%ConsoleStream %78, ptr @.str.7)
  %80 = load %ConsoleStream, ptr %70, align 8
  call void @ConsoleStream_print(%ConsoleStream %80, ptr @.str.8)
  br label %end_15
else_14:
  %82 = load %ConsoleStream, ptr %70, align 8
  call void @ConsoleStream_print(%ConsoleStream %82, ptr @.str.9)
  br label %end_15
end_15:
  %83 = call ptr @cartan_alloc_sequence(i32 256)
  %84 = alloca ptr, align 8
  store ptr %83, ptr %84, align 8
  %85 = call ptr @cartan_alloc_block(i32 16)
  %86 = alloca ptr, align 8
  store ptr %85, ptr %86, align 8
  %87 = call ptr @cartan_alloc_parameter_adam_nd(i32 2, i32 16, i32 16, i32 1, i32 1)
  %88 = alloca ptr, align 8
  store ptr %87, ptr %88, align 8
  %89 = load float, ptr %69, align 4
  %90 = fcmp oeq float %89, 0x3FF0000000000000
  %91 = uitofp i1 %90 to float
  %92 = fcmp one float %91, 0.0
  br i1 %92, label %then_16, label %end_18
then_16:
  %94 = load %ConsoleStream, ptr %70, align 8
  call void @ConsoleStream_print(%ConsoleStream %94, ptr @.str.10)
  br label %end_18
end_18:
  %96 = load %ConsoleStream, ptr %70, align 8
  call void @ConsoleStream_print(%ConsoleStream %96, ptr @.str.11)
  ret float 0x0000000000000000
unreachable_19:
  ret float 0.0
}

define float @run_chat(float %arg_temperature, float %arg_debug) {
entry:
  %97 = alloca float, align 4
  store float %arg_temperature, ptr %97, align 4
  %98 = alloca float, align 4
  store float %arg_debug, ptr %98, align 4
  ; --- Struct Instantiation: ConsoleStream ---
  %99 = alloca %ConsoleStream
  %100 = load float, ptr %98, align 4
  %101 = fcmp oeq float %100, 0x3FF0000000000000
  %102 = uitofp i1 %101 to float
  %103 = fcmp one float %102, 0.0
  br i1 %103, label %then_20, label %end_22
then_20:
  %105 = load %ConsoleStream, ptr %99, align 8
  call void @ConsoleStream_print(%ConsoleStream %105, ptr @.str.12)
  br label %end_22
end_22:
  %107 = load %ConsoleStream, ptr %99, align 8
  call void @ConsoleStream_print(%ConsoleStream %107, ptr @.str.13)
  ret float 0x0000000000000000
unreachable_23:
  ret float 0.0
}

define float @run_generate(ptr %arg_prompt, float %arg_max_tokens, float %arg_temperature, float %arg_debug) {
entry:
  %108 = alloca ptr, align 4
  store ptr %arg_prompt, ptr %108, align 4
  %109 = alloca float, align 4
  store float %arg_max_tokens, ptr %109, align 4
  %110 = alloca float, align 4
  store float %arg_temperature, ptr %110, align 4
  %111 = alloca float, align 4
  store float %arg_debug, ptr %111, align 4
  ; --- Struct Instantiation: ConsoleStream ---
  %112 = alloca %ConsoleStream
  %113 = load float, ptr %111, align 4
  %114 = fcmp oeq float %113, 0x3FF0000000000000
  %115 = uitofp i1 %114 to float
  %116 = fcmp one float %115, 0.0
  br i1 %116, label %then_24, label %end_26
then_24:
  %118 = load %ConsoleStream, ptr %112, align 8
  call void @ConsoleStream_print(%ConsoleStream %118, ptr @.str.14)
  br label %end_26
end_26:
  %120 = load %ConsoleStream, ptr %112, align 8
  call void @ConsoleStream_print(%ConsoleStream %120, ptr @.str.15)
  ret float 0x0000000000000000
unreachable_27:
  ret float 0.0
}

define float @user_main() {
entry:
  ; --- Struct Instantiation: ConsoleStream ---
  %121 = alloca %ConsoleStream
  %122 = call float @cartan_has_arg(ptr @.str.16)
  %123 = alloca float, align 4
  store float %122, ptr %123, align 4
  %124 = load float, ptr %123, align 4
  %125 = fcmp oeq float %124, 0x3FF0000000000000
  %126 = uitofp i1 %125 to float
  %127 = fcmp one float %126, 0.0
  br i1 %127, label %then_28, label %end_30
then_28:
  %129 = load %ConsoleStream, ptr %121, align 8
  call void @ConsoleStream_print(%ConsoleStream %129, ptr @.str.17)
  %131 = load %ConsoleStream, ptr %121, align 8
  call void @ConsoleStream_print(%ConsoleStream %131, ptr @.str.18)
  %133 = load %ConsoleStream, ptr %121, align 8
  call void @ConsoleStream_print(%ConsoleStream %133, ptr @.str.19)
  %135 = load %ConsoleStream, ptr %121, align 8
  call void @ConsoleStream_print(%ConsoleStream %135, ptr @.str.20)
  %137 = load %ConsoleStream, ptr %121, align 8
  call void @ConsoleStream_print(%ConsoleStream %137, ptr @.str.21)
  %139 = load %ConsoleStream, ptr %121, align 8
  call void @ConsoleStream_print(%ConsoleStream %139, ptr @.str.22)
  %141 = load %ConsoleStream, ptr %121, align 8
  call void @ConsoleStream_print(%ConsoleStream %141, ptr @.str.23)
  %143 = load %ConsoleStream, ptr %121, align 8
  call void @ConsoleStream_print(%ConsoleStream %143, ptr @.str.24)
  ret float 0x0000000000000000
unreachable_31:
  br label %end_30
end_30:
  %144 = call float @cartan_has_arg(ptr @.str.25)
  %145 = alloca float, align 4
  store float %144, ptr %145, align 4
  %146 = load float, ptr %145, align 4
  %147 = fcmp oeq float %146, 0x3FF0000000000000
  %148 = uitofp i1 %147 to float
  %149 = fcmp one float %148, 0.0
  br i1 %149, label %then_32, label %end_34
then_32:
  %151 = load %ConsoleStream, ptr %121, align 8
  call void @ConsoleStream_print(%ConsoleStream %151, ptr @.str.26)
  br label %end_34
end_34:
  %152 = call float @cartan_has_arg(ptr @.str.27)
  %153 = alloca float, align 4
  store float %152, ptr %153, align 4
  %154 = load float, ptr %153, align 4
  %155 = fcmp oeq float %154, 0x3FF0000000000000
  %156 = uitofp i1 %155 to float
  %157 = fcmp one float %156, 0.0
  br i1 %157, label %then_35, label %end_37
then_35:
  store float 0x3FF0000000000000, ptr %145, align 4
  br label %end_37
end_37:
  %158 = call float @cartan_has_arg(ptr @.str.28)
  %159 = alloca float, align 4
  store float %158, ptr %159, align 4
  %160 = call float @cartan_has_arg(ptr @.str.29)
  %161 = alloca float, align 4
  store float %160, ptr %161, align 4
  %162 = call float @cartan_has_arg(ptr @.str.30)
  %163 = alloca float, align 4
  store float %162, ptr %163, align 4
  %164 = call float @cartan_has_arg(ptr @.str.31)
  %165 = alloca float, align 4
  store float %164, ptr %165, align 4
  %166 = load float, ptr %159, align 4
  %167 = fcmp oeq float %166, 0x3FF0000000000000
  %168 = uitofp i1 %167 to float
  %169 = fcmp one float %168, 0.0
  br i1 %169, label %then_38, label %end_40
then_38:
  %170 = call ptr @cartan_get_arg_string(ptr @.str.32, ptr @.str.33)
  %171 = alloca ptr, align 8
  store ptr %170, ptr %171, align 8
  %172 = call float @cartan_get_arg_int(ptr @.str.34, float 0x3FF0000000000000)
  %173 = alloca float, align 4
  store float %172, ptr %173, align 4
  %174 = call float @cartan_get_arg_int(ptr @.str.35, float 0x4070000000000000)
  %175 = alloca float, align 4
  store float %174, ptr %175, align 4
  %176 = call float @cartan_get_arg_int(ptr @.str.36, float 0x4020000000000000)
  %177 = alloca float, align 4
  store float %176, ptr %177, align 4
  %178 = load ptr, ptr %171, align 8
  %179 = load float, ptr %173, align 4
  %180 = load float, ptr %175, align 4
  %181 = load float, ptr %177, align 4
  %182 = load float, ptr %145, align 4
  %183 = call float @run_causal_pretrain(ptr %178, float %179, float %180, float %181, float %182)
  ret float %183
unreachable_41:
  br label %end_40
end_40:
  %184 = load float, ptr %161, align 4
  %185 = fcmp oeq float %184, 0x3FF0000000000000
  %186 = uitofp i1 %185 to float
  %187 = fcmp one float %186, 0.0
  br i1 %187, label %then_42, label %end_44
then_42:
  %188 = call ptr @cartan_get_arg_string(ptr @.str.37, ptr @.str.38)
  %189 = alloca ptr, align 8
  store ptr %188, ptr %189, align 8
  %190 = call float @cartan_get_arg_int(ptr @.str.39, float 0x3FF0000000000000)
  %191 = alloca float, align 4
  store float %190, ptr %191, align 4
  %192 = load ptr, ptr %189, align 8
  %193 = load float, ptr %191, align 4
  %194 = load float, ptr %145, align 4
  %195 = call float @run_sft_train(ptr %192, float %193, float %194)
  ret float %195
unreachable_45:
  br label %end_44
end_44:
  %196 = load float, ptr %163, align 4
  %197 = fcmp oeq float %196, 0x3FF0000000000000
  %198 = uitofp i1 %197 to float
  %199 = fcmp one float %198, 0.0
  br i1 %199, label %then_46, label %end_48
then_46:
  %200 = call float @cartan_get_arg_float(ptr @.str.40, float 0x3FE6666660000000)
  %201 = alloca float, align 4
  store float %200, ptr %201, align 4
  %202 = load float, ptr %201, align 4
  %203 = load float, ptr %145, align 4
  %204 = call float @run_chat(float %202, float %203)
  ret float %204
unreachable_49:
  br label %end_48
end_48:
  %205 = load float, ptr %165, align 4
  %206 = fcmp oeq float %205, 0x3FF0000000000000
  %207 = uitofp i1 %206 to float
  %208 = fcmp one float %207, 0.0
  br i1 %208, label %then_50, label %end_52
then_50:
  %209 = call ptr @cartan_get_arg_string(ptr @.str.41, ptr @.str.42)
  %210 = alloca ptr, align 8
  store ptr %209, ptr %210, align 8
  %211 = call float @cartan_get_arg_int(ptr @.str.43, float 0x4059000000000000)
  %212 = alloca float, align 4
  store float %211, ptr %212, align 4
  %213 = call float @cartan_get_arg_float(ptr @.str.44, float 0x3FE6666660000000)
  %214 = alloca float, align 4
  store float %213, ptr %214, align 4
  %215 = load ptr, ptr %210, align 8
  %216 = load float, ptr %212, align 4
  %217 = load float, ptr %214, align 4
  %218 = load float, ptr %145, align 4
  %219 = call float @run_generate(ptr %215, float %216, float %217, float %218)
  ret float %219
unreachable_53:
  br label %end_52
end_52:
  %221 = load %ConsoleStream, ptr %121, align 8
  call void @ConsoleStream_print(%ConsoleStream %221, ptr @.str.45)
  ret float 0x3FF0000000000000
unreachable_54:
  ret float 0.0
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
@.str.0 = private unnamed_addr constant [39 x i8] c"\5b\44\45\42\55\47\5d\20\52\75\6e\6e\69\6e\67\20\43\61\75\73\61\6c\20\50\72\65\74\72\61\69\6e\69\6e\67\2e\2e\2e\0a\00", align 1
@.str.1 = private unnamed_addr constant [21 x i8] c"\5b\44\45\42\55\47\5d\20\50\61\72\61\6d\65\74\65\72\73\3a\0a\00", align 1
@.str.2 = private unnamed_addr constant [25 x i8] c"\20\20\44\61\74\61\73\65\74\20\70\61\74\68\20\70\72\6f\76\69\64\65\64\0a\00", align 1
@.str.3 = private unnamed_addr constant [29 x i8] c"\53\74\61\72\74\69\6e\67\20\43\61\75\73\61\6c\20\50\72\65\74\72\61\69\6e\2e\2e\2e\0a\00", align 1
@.str.4 = private unnamed_addr constant [39 x i8] c"\5b\44\45\42\55\47\5d\20\4d\6f\64\65\6c\20\50\61\72\61\6d\65\74\65\72\73\20\49\6e\69\74\69\61\6c\69\7a\65\64\2e\0a\00", align 1
@.str.5 = private unnamed_addr constant [20 x i8] c"\54\72\61\69\6e\69\6e\67\20\63\6f\6d\70\6c\65\74\65\2e\0a\00", align 1
@.str.6 = private unnamed_addr constant [33 x i8] c"\5b\44\45\42\55\47\5d\20\52\75\6e\6e\69\6e\67\20\53\46\54\20\54\72\61\69\6e\69\6e\67\2e\2e\2e\0a\00", align 1
@.str.7 = private unnamed_addr constant [21 x i8] c"\5b\44\45\42\55\47\5d\20\50\61\72\61\6d\65\74\65\72\73\3a\0a\00", align 1
@.str.8 = private unnamed_addr constant [25 x i8] c"\20\20\44\61\74\61\73\65\74\20\70\61\74\68\20\70\72\6f\76\69\64\65\64\0a\00", align 1
@.str.9 = private unnamed_addr constant [26 x i8] c"\53\74\61\72\74\69\6e\67\20\53\46\54\20\54\72\61\69\6e\69\6e\67\2e\2e\2e\0a\00", align 1
@.str.10 = private unnamed_addr constant [37 x i8] c"\5b\44\45\42\55\47\5d\20\53\46\54\20\50\61\72\61\6d\65\74\65\72\73\20\49\6e\69\74\69\61\6c\69\7a\65\64\2e\0a\00", align 1
@.str.11 = private unnamed_addr constant [15 x i8] c"\53\46\54\20\63\6f\6d\70\6c\65\74\65\2e\0a\00", align 1
@.str.12 = private unnamed_addr constant [40 x i8] c"\5b\44\45\42\55\47\5d\20\49\6e\69\74\69\61\6c\69\7a\69\6e\67\20\43\68\61\74\20\49\6e\74\65\72\66\61\63\65\2e\2e\2e\0a\00", align 1
@.str.13 = private unnamed_addr constant [41 x i8] c"\43\68\61\74\20\69\6e\74\65\72\66\61\63\65\20\72\65\61\64\79\2e\20\28\4e\6f\74\20\69\6d\70\6c\65\6d\65\6e\74\65\64\29\0a\00", align 1
@.str.14 = private unnamed_addr constant [30 x i8] c"\5b\44\45\42\55\47\5d\20\47\65\6e\65\72\61\74\69\6e\67\20\74\6f\6b\65\6e\73\2e\2e\2e\0a\00", align 1
@.str.15 = private unnamed_addr constant [22 x i8] c"\47\65\6e\65\72\61\74\69\6f\6e\20\63\6f\6d\70\6c\65\74\65\2e\0a\00", align 1
@.str.16 = private unnamed_addr constant [5 x i8] c"\68\65\6c\70\00", align 1
@.str.17 = private unnamed_addr constant [28 x i8] c"\47\65\6f\4d\69\6e\64\20\43\6f\6d\70\69\6c\65\72\20\26\20\52\75\6e\74\69\6d\65\0a\00", align 1
@.str.18 = private unnamed_addr constant [10 x i8] c"\4f\70\74\69\6f\6e\73\3a\0a\00", align 1
@.str.19 = private unnamed_addr constant [58 x i8] c"\20\20\2d\2d\74\72\61\69\6e\2d\63\61\75\73\61\6c\20\20\20\52\75\6e\20\63\61\75\73\61\6c\20\6c\61\6e\67\75\61\67\65\20\6d\6f\64\65\6c\20\70\72\65\74\72\61\69\6e\69\6e\67\0a\00", align 1
@.str.20 = private unnamed_addr constant [47 x i8] c"\20\20\2d\2d\74\72\61\69\6e\2d\73\66\74\20\20\20\20\20\20\52\75\6e\20\73\75\70\65\72\76\69\73\65\64\20\66\69\6e\65\20\74\75\6e\69\6e\67\0a\00", align 1
@.str.21 = private unnamed_addr constant [51 x i8] c"\20\20\2d\2d\63\68\61\74\20\20\20\20\20\20\20\20\20\20\20\53\74\61\72\74\20\69\6e\74\65\72\61\63\74\69\76\65\20\63\68\61\74\20\73\65\73\73\69\6f\6e\0a\00", align 1
@.str.22 = private unnamed_addr constant [48 x i8] c"\20\20\2d\2d\67\65\6e\65\72\61\74\65\20\20\20\20\20\20\20\47\65\6e\65\72\61\74\65\20\74\65\78\74\20\66\72\6f\6d\20\61\20\70\72\6f\6d\70\74\0a\00", align 1
@.str.23 = private unnamed_addr constant [52 x i8] c"\20\20\2d\2d\64\65\62\75\67\20\20\20\20\20\20\20\20\20\20\53\68\6f\77\20\69\6e\74\65\72\6e\61\6c\20\73\74\61\74\65\73\20\61\6e\64\20\74\6f\6b\65\6e\73\0a\00", align 1
@.str.24 = private unnamed_addr constant [36 x i8] c"\20\20\2d\2d\73\68\6f\77\2d\74\6f\6b\65\6e\73\20\20\20\20\53\61\6d\65\20\61\73\20\2d\2d\64\65\62\75\67\0a\00", align 1
@.str.25 = private unnamed_addr constant [6 x i8] c"\64\65\62\75\67\00", align 1
@.str.26 = private unnamed_addr constant [27 x i8] c"\49\53\5f\44\45\42\55\47\20\69\73\20\31\20\69\6e\20\67\65\6f\6d\69\6e\64\21\0a\00", align 1
@.str.27 = private unnamed_addr constant [12 x i8] c"\73\68\6f\77\2d\74\6f\6b\65\6e\73\00", align 1
@.str.28 = private unnamed_addr constant [13 x i8] c"\74\72\61\69\6e\2d\63\61\75\73\61\6c\00", align 1
@.str.29 = private unnamed_addr constant [10 x i8] c"\74\72\61\69\6e\2d\73\66\74\00", align 1
@.str.30 = private unnamed_addr constant [5 x i8] c"\63\68\61\74\00", align 1
@.str.31 = private unnamed_addr constant [9 x i8] c"\67\65\6e\65\72\61\74\65\00", align 1
@.str.32 = private unnamed_addr constant [8 x i8] c"\64\61\74\61\73\65\74\00", align 1
@.str.33 = private unnamed_addr constant [20 x i8] c"\64\65\66\61\75\6c\74\5f\64\61\74\61\73\65\74\2e\62\69\6e\00", align 1
@.str.34 = private unnamed_addr constant [7 x i8] c"\65\70\6f\63\68\73\00", align 1
@.str.35 = private unnamed_addr constant [8 x i8] c"\73\65\71\5f\6c\65\6e\00", align 1
@.str.36 = private unnamed_addr constant [11 x i8] c"\62\61\74\63\68\5f\73\69\7a\65\00", align 1
@.str.37 = private unnamed_addr constant [8 x i8] c"\64\61\74\61\73\65\74\00", align 1
@.str.38 = private unnamed_addr constant [16 x i8] c"\73\66\74\5f\64\61\74\61\73\65\74\2e\62\69\6e\00", align 1
@.str.39 = private unnamed_addr constant [7 x i8] c"\65\70\6f\63\68\73\00", align 1
@.str.40 = private unnamed_addr constant [12 x i8] c"\74\65\6d\70\65\72\61\74\75\72\65\00", align 1
@.str.41 = private unnamed_addr constant [7 x i8] c"\70\72\6f\6d\70\74\00", align 1
@.str.42 = private unnamed_addr constant [1 x i8] c"\00", align 1
@.str.43 = private unnamed_addr constant [11 x i8] c"\6d\61\78\5f\74\6f\6b\65\6e\73\00", align 1
@.str.44 = private unnamed_addr constant [12 x i8] c"\74\65\6d\70\65\72\61\74\75\72\65\00", align 1
@.str.45 = private unnamed_addr constant [70 x i8] c"\45\72\72\6f\72\3a\20\4e\6f\20\6f\70\65\72\61\74\69\6f\6e\20\73\70\65\63\69\66\69\65\64\2e\20\55\73\65\20\2d\2d\68\65\6c\70\20\74\6f\20\73\65\65\20\61\76\61\69\6c\61\62\6c\65\20\63\6f\6d\6d\61\6e\64\73\2e\0a\00", align 1
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

