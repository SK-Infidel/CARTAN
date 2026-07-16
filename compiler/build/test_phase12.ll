; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

%WordLevel = type { ptr }
%StructuralNoise = type { i32 }
%HighEntropy = type {  }


define ptr @WordLevel_encode(%WordLevel %arg_self, ptr %arg_text) {
entry:
  %1 = alloca %WordLevel, align 8
  store %WordLevel %arg_self, ptr %1, align 8
  %2 = alloca ptr, align 4
  store ptr %arg_text, ptr %2, align 4
  ; --- Cartan.tree_create ---
  %3 = call ptr @cartan_tree_create()
  %4 = alloca ptr, align 8
  store ptr %3, ptr %4, align 8
  %5 = alloca float, align 4
  store float 0, ptr %5, align 4
  %6 = load ptr, ptr %2, align 8
  %7 = load %ptr, ptr %6, align 8
  %8 = call float @ptr_string_length(%ptr %7)
  %9 = alloca float, align 4
  store float %8, ptr %9, align 4
  br label %while_cond_1
while_cond_1:
  %10 = load float, ptr %5, align 4
  %11 = load float, ptr %9, align 4
  %12 = fcmp olt float %10, %11
  %13 = uitofp i1 %12 to float
  %14 = fcmp one float %13, 0.0
  br i1 %14, label %while_body_2, label %while_end_3
while_body_2:
  %15 = load ptr, ptr %2, align 8
  %16 = load float, ptr %5, align 4
  %17 = load %ptr, ptr %15, align 8
  %18 = call float @ptr_char_at(%ptr %17, float %16)
  %19 = alloca float, align 4
  store float %18, ptr %19, align 4
  %20 = load float, ptr %19, align 4
  %21 = fcmp oeq float %20, string:@.str.1
  %22 = uitofp i1 %21 to float
  %23 = load float, ptr %19, align 4
  %24 = fcmp oeq float %23, string:@.str.2
  %25 = uitofp i1 %24 to float
  %26 = fcmp one float 0.0, 0.0
  br i1 %26, label %then_4, label %else_5
then_4:
  %27 = load %string, ptr @.str.0, align 8
  %28 = call float @string_string_length(%string %27)
  %29 = fcmp ogt float %28, 0
  %30 = uitofp i1 %29 to float
  %31 = fcmp one float %30, 0.0
  br i1 %31, label %then_7, label %end_9
then_7:
  %33 = load %WordLevel, ptr %1, align 8
  %34 = call float @WordLevel_find_vocab_id(%WordLevel %33, ptr @.str.0)
  %35 = alloca float, align 4
  store float %34, ptr %35, align 4
  %36 = load float, ptr %35, align 4
  %37 = fpext float %36 to double
  %38 = call i32 (ptr, ...) @printf(ptr @.str.3, ptr @.str.0, double %37)
  ; --- Cartan.tree_push ---
  %39 = load ptr, ptr %4, align 8
  %40 = load float, ptr %35, align 4
  %42 = fptoui float %40 to i64
  %41 = inttoptr i64 %42 to ptr
  call void @cartan_tree_push(ptr %39, ptr %41)
  store float string:@.str.4, ptr @.str.0, align 4
  br label %end_9
end_9:
  br label %end_6
else_5:
  ; --- Begin Fused Kernel ---
  %43 = load float, ptr %19, align 4
  %44 = fadd float string:@.str.0, %43
  ; --- End Fused Kernel (Unrolled) ---
  store float %44, ptr @.str.0, align 4
  br label %end_6
end_6:
  ; --- Begin Fused Kernel ---
  %45 = load float, ptr %5, align 4
  %46 = fadd float %45, 1
  ; --- End Fused Kernel (Unrolled) ---
  store float %46, ptr %5, align 4
  br label %while_cond_1
while_end_3:
  %47 = load %string, ptr @.str.0, align 8
  %48 = call float @string_string_length(%string %47)
  %49 = fcmp ogt float %48, 0
  %50 = uitofp i1 %49 to float
  %51 = fcmp one float %50, 0.0
  br i1 %51, label %then_10, label %end_12
then_10:
  %53 = load %WordLevel, ptr %1, align 8
  %54 = call float @WordLevel_find_vocab_id(%WordLevel %53, ptr @.str.0)
  %55 = alloca float, align 4
  store float %54, ptr %55, align 4
  %56 = load float, ptr %55, align 4
  %57 = fpext float %56 to double
  %58 = call i32 (ptr, ...) @printf(ptr @.str.5, ptr @.str.0, double %57)
  ; --- Cartan.tree_push ---
  %59 = load ptr, ptr %4, align 8
  %60 = load float, ptr %55, align 4
  %62 = fptoui float %60 to i64
  %61 = inttoptr i64 %62 to ptr
  call void @cartan_tree_push(ptr %59, ptr %61)
  br label %end_12
end_12:
  %63 = load ptr, ptr %4, align 8
  ret ptr %63
unreachable_13:
  ret ptr null
}

define ptr @WordLevel_decode(%WordLevel %arg_self, ptr %arg_tokens) {
entry:
  %64 = alloca %WordLevel, align 8
  store %WordLevel %arg_self, ptr %64, align 8
  %65 = alloca ptr, align 4
  store ptr %arg_tokens, ptr %65, align 4
  %66 = alloca float, align 4
  store float 0, ptr %66, align 4
  %67 = load ptr, ptr %65, align 8
  %68 = load %ptr, ptr %67, align 8
  %69 = call float @ptr_len(%ptr %68)
  %70 = alloca float, align 4
  store float %69, ptr %70, align 4
  br label %while_cond_14
while_cond_14:
  %71 = load float, ptr %66, align 4
  %72 = load float, ptr %70, align 4
  %73 = fcmp olt float %71, %72
  %74 = uitofp i1 %73 to float
  %75 = fcmp one float %74, 0.0
  br i1 %75, label %while_body_15, label %while_end_16
while_body_15:
  ; --- Cartan.tree_get ---
  %76 = load ptr, ptr %65, align 8
  %77 = load float, ptr %66, align 4
  %78 = fptosi float %77 to i32
  %79 = call ptr @cartan_tree_get(ptr %76, i32 %78)
  %80 = alloca ptr, align 8
  store ptr %79, ptr %80, align 8
  ; --- Cartan.tree_get ---
  %81 = getelementptr inbounds %WordLevel, ptr %64, i32 0, i32 0
  %82 = load ptr, ptr %81, align 8
  %83 = load ptr, ptr %80, align 8
  %84 = fptosi float %83 to i32
  %85 = call ptr @cartan_tree_get(ptr %82, i32 %84)
  %86 = alloca ptr, align 8
  store ptr %85, ptr %86, align 8
  %87 = load float, ptr %66, align 4
  %88 = fcmp ogt float %87, 0
  %89 = uitofp i1 %88 to float
  %90 = fcmp one float %89, 0.0
  br i1 %90, label %then_17, label %end_19
then_17:
  %91 = fadd float string:@.str.6, string:@.str.7
  store float %91, ptr @.str.6, align 4
  br label %end_19
end_19:
  ; --- Begin Fused Kernel ---
  %92 = load ptr, ptr %86, align 8
  %93 = ptrtoint ptr %92 to i64
  %94 = sitofp i64 %93 to float
  %95 = fadd float string:@.str.6, %94
  ; --- End Fused Kernel (Unrolled) ---
  store float %95, ptr @.str.6, align 4
  ; --- Begin Fused Kernel ---
  %96 = load float, ptr %66, align 4
  %97 = fadd float %96, 1
  ; --- End Fused Kernel (Unrolled) ---
  store float %97, ptr %66, align 4
  br label %while_cond_14
while_end_16:
  %98 = fptoui float string:@.str.6 to i64
  %99 = inttoptr i64 %98 to ptr
  ret ptr %99
unreachable_20:
  ret ptr null
}

define i32 @WordLevel_find_vocab_id(%WordLevel %arg_self, ptr %arg_word) {
entry:
  %100 = alloca %WordLevel, align 8
  store %WordLevel %arg_self, ptr %100, align 8
  %101 = alloca ptr, align 4
  store ptr %arg_word, ptr %101, align 4
  %102 = alloca float, align 4
  store float 0, ptr %102, align 4
  %103 = getelementptr inbounds %WordLevel, ptr %100, i32 0, i32 0
  %104 = load ptr, ptr %103, align 8
  %105 = load %StructName, ptr %104, align 8
  %106 = call float @StructName_len(%StructName %105)
  %107 = alloca float, align 4
  store float %106, ptr %107, align 4
  br label %while_cond_21
while_cond_21:
  %108 = load float, ptr %102, align 4
  %109 = load float, ptr %107, align 4
  %110 = fcmp olt float %108, %109
  %111 = uitofp i1 %110 to float
  %112 = fcmp one float %111, 0.0
  br i1 %112, label %while_body_22, label %while_end_23
while_body_22:
  ; --- Cartan.tree_get ---
  %113 = getelementptr inbounds %WordLevel, ptr %100, i32 0, i32 0
  %114 = load ptr, ptr %113, align 8
  %115 = load float, ptr %102, align 4
  %116 = fptosi float %115 to i32
  %117 = call ptr @cartan_tree_get(ptr %114, i32 %116)
  %118 = alloca ptr, align 8
  store ptr %117, ptr %118, align 8
  %119 = load ptr, ptr %118, align 8
  %120 = load ptr, ptr %101, align 8
  %121 = call ptr @cartan_tensor_add(ptr %119, ptr %120)
  %122 = fcmp one float ptr:%121, 0.0
  br i1 %122, label %then_24, label %end_26
then_24:
  %123 = load float, ptr %102, align 4
  %124 = fptosi float %123 to i32
  ret i32 %124
unreachable_27:
  br label %end_26
end_26:
  ; --- Begin Fused Kernel ---
  %125 = load float, ptr %102, align 4
  %126 = fadd float %125, 1
  ; --- End Fused Kernel (Unrolled) ---
  store float %126, ptr %102, align 4
  br label %while_cond_21
while_end_23:
  ret i32 0
unreachable_28:
  ret i32 0
}

define ptr @StructuralNoise_apply(%StructuralNoise %arg_self, ptr %arg_tokens) {
entry:
  %127 = alloca %StructuralNoise, align 8
  store %StructuralNoise %arg_self, ptr %127, align 8
  %128 = alloca ptr, align 4
  store ptr %arg_tokens, ptr %128, align 4
  ; --- Cartan.tree_create ---
  %129 = call ptr @cartan_tree_create()
  %130 = alloca ptr, align 8
  store ptr %129, ptr %130, align 8
  %131 = load ptr, ptr %128, align 8
  %132 = load %ptr, ptr %131, align 8
  %133 = call float @ptr_len(%ptr %132)
  %134 = alloca float, align 4
  store float %133, ptr %134, align 4
  %135 = alloca float, align 4
  store float 0, ptr %135, align 4
  br label %while_cond_29
while_cond_29:
  %136 = load float, ptr %135, align 4
  %137 = load float, ptr %134, align 4
  %138 = fcmp olt float %136, %137
  %139 = uitofp i1 %138 to float
  %140 = fcmp one float %139, 0.0
  br i1 %140, label %while_body_30, label %while_end_31
while_body_30:
  ; --- Cartan.tree_get ---
  %141 = load ptr, ptr %128, align 8
  %142 = load float, ptr %135, align 4
  %143 = fptosi float %142 to i32
  %144 = call ptr @cartan_tree_get(ptr %141, i32 %143)
  %145 = alloca ptr, align 8
  store ptr %144, ptr %145, align 8
  %146 = alloca float, align 4
  store float 0.0, ptr %146, align 4
  %147 = load float, ptr %135, align 4
  %148 = getelementptr inbounds %StructuralNoise, ptr %127, i32 0, i32 0
  %149 = load float, ptr %148, align 4
  %150 = fcmp oge float %147, %149
  %151 = uitofp i1 %150 to float
  %152 = fcmp one float %151, 0.0
  br i1 %152, label %then_32, label %end_34
then_32:
  ; --- Cartan.tree_get ---
  %153 = load ptr, ptr %128, align 8
  %154 = load float, ptr %135, align 4
  %155 = getelementptr inbounds %StructuralNoise, ptr %127, i32 0, i32 0
  %156 = load float, ptr %155, align 4
  %157 = fsub float %154, %156
  %158 = fptosi float %157 to i32
  %159 = call ptr @cartan_tree_get(ptr %153, i32 %158)
  %160 = alloca ptr, align 8
  store ptr %159, ptr %160, align 8
  %161 = load ptr, ptr %145, align 8
  %162 = load ptr, ptr %160, align 8
  %163 = call ptr @cartan_tensor_add(ptr %161, ptr %162)
  %164 = fcmp one float ptr:%163, 0.0
  br i1 %164, label %then_35, label %end_37
then_35:
  store float 0.0, ptr %146, align 4
  br label %end_37
end_37:
  br label %end_34
end_34:
  %165 = load float, ptr %146, align 4
  %166 = fcmp one float 0.0, 0.0
  br i1 %166, label %then_38, label %end_40
then_38:
  ; --- Cartan.tree_push ---
  %167 = load ptr, ptr %130, align 8
  %168 = load ptr, ptr %145, align 8
  call void @cartan_tree_push(ptr %167, ptr %168)
  br label %end_40
end_40:
  ; --- Begin Fused Kernel ---
  %169 = load float, ptr %135, align 4
  %170 = fadd float %169, 1
  ; --- End Fused Kernel (Unrolled) ---
  store float %170, ptr %135, align 4
  br label %while_cond_29
while_end_31:
  %171 = load ptr, ptr %130, align 8
  ret ptr %171
unreachable_41:
  ret ptr null
}

define ptr @HighEntropy_apply(%HighEntropy %arg_self, ptr %arg_tokens) {
entry:
  %172 = alloca %HighEntropy, align 8
  store %HighEntropy %arg_self, ptr %172, align 8
  %173 = alloca ptr, align 4
  store ptr %arg_tokens, ptr %173, align 4
  ; --- Cartan.tree_create ---
  %174 = call ptr @cartan_tree_create()
  %175 = alloca ptr, align 8
  store ptr %174, ptr %175, align 8
  %176 = load ptr, ptr %173, align 8
  %177 = load %ptr, ptr %176, align 8
  %178 = call float @ptr_len(%ptr %177)
  %179 = alloca float, align 4
  store float %178, ptr %179, align 4
  %180 = alloca float, align 4
  store float 0, ptr %180, align 4
  br label %while_cond_42
while_cond_42:
  %181 = load float, ptr %180, align 4
  %182 = load float, ptr %179, align 4
  %183 = fcmp olt float %181, %182
  %184 = uitofp i1 %183 to float
  %185 = fcmp one float %184, 0.0
  br i1 %185, label %while_body_43, label %while_end_44
while_body_43:
  ; --- Cartan.tree_get ---
  %186 = load ptr, ptr %173, align 8
  %187 = load float, ptr %180, align 4
  %188 = fptosi float %187 to i32
  %189 = call ptr @cartan_tree_get(ptr %186, i32 %188)
  %190 = alloca ptr, align 8
  store ptr %189, ptr %190, align 8
  %191 = load ptr, ptr %190, align 8
  %192 = ptrtoint ptr %191 to i64
  %193 = sitofp i64 %192 to float
  %194 = fcmp one float %193, 0
  %195 = uitofp i1 %194 to float
  %196 = fcmp one float %195, 0.0
  br i1 %196, label %then_45, label %end_47
then_45:
  ; --- Cartan.tree_push ---
  %197 = load ptr, ptr %175, align 8
  %198 = load ptr, ptr %190, align 8
  call void @cartan_tree_push(ptr %197, ptr %198)
  br label %end_47
end_47:
  ; --- Begin Fused Kernel ---
  %199 = load float, ptr %180, align 4
  %200 = fadd float %199, 1
  ; --- End Fused Kernel (Unrolled) ---
  store float %200, ptr %180, align 4
  br label %while_cond_42
while_end_44:
  %201 = load ptr, ptr %175, align 8
  ret ptr %201
unreachable_48:
  ret ptr null
}

define void @user_main() {
entry:
  ; --- Cartan.tree_create ---
  %202 = call ptr @cartan_tree_create()
  %203 = alloca ptr, align 8
  store ptr %202, ptr %203, align 8
  ; --- Cartan.tree_push ---
  %204 = load ptr, ptr %203, align 8
  %206 = fptoui float string:@.str.8 to i64
  %205 = inttoptr i64 %206 to ptr
  call void @cartan_tree_push(ptr %204, ptr %205)
  ; --- Cartan.tree_push ---
  %207 = load ptr, ptr %203, align 8
  %209 = fptoui float string:@.str.9 to i64
  %208 = inttoptr i64 %209 to ptr
  call void @cartan_tree_push(ptr %207, ptr %208)
  ; --- Cartan.tree_push ---
  %210 = load ptr, ptr %203, align 8
  %212 = fptoui float string:@.str.10 to i64
  %211 = inttoptr i64 %212 to ptr
  call void @cartan_tree_push(ptr %210, ptr %211)
  ; --- Cartan.tree_push ---
  %213 = load ptr, ptr %203, align 8
  %215 = fptoui float string:@.str.11 to i64
  %214 = inttoptr i64 %215 to ptr
  call void @cartan_tree_push(ptr %213, ptr %214)
  ; --- Cartan.tree_push ---
  %216 = load ptr, ptr %203, align 8
  %218 = fptoui float string:@.str.12 to i64
  %217 = inttoptr i64 %218 to ptr
  call void @cartan_tree_push(ptr %216, ptr %217)
  %219 = alloca %WordLevel, align 8
  %220 = load ptr, ptr %203, align 8
  %221 = getelementptr inbounds %WordLevel, ptr %219, i32 0, i32 0
  store ptr %220, ptr %221, align 8
  %222 = call i32 (ptr, ...) @printf(ptr @.str.14, ptr @.str.13)
  %224 = load %WordLevel, ptr %219, align 8
  %225 = call ptr @WordLevel_encode(%WordLevel %224, ptr @.str.13)
  %226 = alloca ptr, align 8
  store ptr %225, ptr %226, align 8
  %227 = load ptr, ptr %226, align 8
  %228 = load %ptr, ptr %227, align 8
  %229 = call float @ptr_len(%ptr %228)
  %230 = fpext float %229 to double
  %231 = call i32 (ptr, ...) @printf(ptr @.str.15, double %230)
  %232 = alloca %StructuralNoise, align 8
  %233 = getelementptr inbounds %StructuralNoise, ptr %232, i32 0, i32 0
  store i32 1, ptr %233, align 4
  %235 = load ptr, ptr %226, align 8
  %236 = load %StructuralNoise, ptr %232, align 8
  %237 = call ptr @StructuralNoise_apply(%StructuralNoise %236, ptr %235)
  %238 = alloca ptr, align 8
  store ptr %237, ptr %238, align 8
  %239 = alloca %HighEntropy, align 8
  %241 = load ptr, ptr %238, align 8
  %242 = load %HighEntropy, ptr %239, align 8
  %243 = call ptr @HighEntropy_apply(%HighEntropy %242, ptr %241)
  store ptr %243, ptr %238, align 8
  %244 = load ptr, ptr %238, align 8
  %245 = load %ptr, ptr %244, align 8
  %246 = call float @ptr_len(%ptr %245)
  %247 = fpext float %246 to double
  %248 = call i32 (ptr, ...) @printf(ptr @.str.16, double %247)
  %250 = load ptr, ptr %238, align 8
  %251 = load %WordLevel, ptr %219, align 8
  %252 = call ptr @WordLevel_decode(%WordLevel %251, ptr %250)
  %253 = alloca ptr, align 8
  store ptr %252, ptr %253, align 8
  %254 = load ptr, ptr %253, align 8
  %255 = call i32 (ptr, ...) @printf(ptr @.str.17, ptr %254)
  ret void
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
@.str.1 = private unnamed_addr constant [2 x i8] c"\20\00", align 1
@.str.2 = private unnamed_addr constant [2 x i8] c"\0a\00", align 1
@.str.3 = private unnamed_addr constant [30 x i8] c"\50\75\73\68\69\6e\67\20\77\6f\72\64\20\27\25\73\27\20\77\69\74\68\20\69\64\20\25\64\0a\00", align 1
@.str.4 = private unnamed_addr constant [1 x i8] c"\00", align 1
@.str.5 = private unnamed_addr constant [30 x i8] c"\50\75\73\68\69\6e\67\20\77\6f\72\64\20\27\25\73\27\20\77\69\74\68\20\69\64\20\25\64\0a\00", align 1
@.str.6 = private unnamed_addr constant [1 x i8] c"\00", align 1
@.str.7 = private unnamed_addr constant [2 x i8] c"\20\00", align 1
@.str.8 = private unnamed_addr constant [6 x i8] c"\5b\55\4e\4b\5d\00", align 1
@.str.9 = private unnamed_addr constant [6 x i8] c"\68\65\6c\6c\6f\00", align 1
@.str.10 = private unnamed_addr constant [6 x i8] c"\77\6f\72\6c\64\00", align 1
@.str.11 = private unnamed_addr constant [7 x i8] c"\63\61\72\74\61\6e\00", align 1
@.str.12 = private unnamed_addr constant [6 x i8] c"\6e\6f\69\73\65\00", align 1
@.str.13 = private unnamed_addr constant [36 x i8] c"\68\65\6c\6c\6f\20\6e\6f\69\73\65\20\6e\6f\69\73\65\20\78\7a\71\79\20\63\61\72\74\61\6e\20\77\6f\72\6c\64\00", align 1
@.str.14 = private unnamed_addr constant [14 x i8] c"\52\61\77\20\54\65\78\74\3a\20\25\73\0a\00", align 1
@.str.15 = private unnamed_addr constant [26 x i8] c"\45\6e\63\6f\64\65\64\20\54\6f\6b\65\6e\73\20\43\6f\75\6e\74\3a\20\25\64\0a\00", align 1
@.str.16 = private unnamed_addr constant [24 x i8] c"\43\6c\65\61\6e\20\54\6f\6b\65\6e\73\20\43\6f\75\6e\74\3a\20\25\64\0a\00", align 1
@.str.17 = private unnamed_addr constant [18 x i8] c"\43\6c\65\61\6e\65\64\20\54\65\78\74\3a\20\25\73\0a\00", align 1
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

