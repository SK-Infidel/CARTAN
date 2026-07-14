; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

%CosformerStream = type { ptr, ptr, ptr }
%SSMStream = type { ptr, ptr, ptr, ptr, ptr }
%SpectralStream = type { ptr }
%PoincareStream = type { ptr }
%HomologyStream = type { ptr }
%EikonalStream = type { ptr }
%HeatKernelStream = type { float, ptr }
%TrialityStream = type { ptr, ptr, ptr }


define ptr @CosformerStream_forward(%CosformerStream %arg_this, ptr %arg_x) {
entry:
  %1 = alloca %CosformerStream, align 8
  store %CosformerStream %arg_this, ptr %1, align 8
  %2 = alloca ptr, align 4
  store ptr %arg_x, ptr %2, align 4
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds %CosformerStream, ptr %1, i32 0, i32 0
  %5 = load ptr, ptr %4, align 8
  %6 = call ptr @cartan_tensor_matmul(ptr %3, ptr %5)
  %7 = alloca ptr, align 8
  store ptr %6, ptr %7, align 8
  %8 = load ptr, ptr %2, align 8
  %9 = getelementptr inbounds %CosformerStream, ptr %1, i32 0, i32 1
  %10 = load ptr, ptr %9, align 8
  %11 = call ptr @cartan_tensor_matmul(ptr %8, ptr %10)
  %12 = alloca ptr, align 8
  store ptr %11, ptr %12, align 8
  %13 = load ptr, ptr %2, align 8
  %14 = getelementptr inbounds %CosformerStream, ptr %1, i32 0, i32 2
  %15 = load ptr, ptr %14, align 8
  %16 = call ptr @cartan_tensor_matmul(ptr %13, ptr %15)
  %17 = alloca ptr, align 8
  store ptr %16, ptr %17, align 8
  %18 = load ptr, ptr %7, align 8
  %19 = alloca ptr, align 8
  store ptr %18, ptr %19, align 8
  %20 = load ptr, ptr %12, align 8
  %21 = alloca ptr, align 8
  store ptr %20, ptr %21, align 8
  %22 = load ptr, ptr %21, align 8
  %23 = load ptr, ptr %17, align 8
  %24 = call ptr @cartan_tensor_matmul(ptr %22, ptr %23)
  %25 = alloca ptr, align 8
  store ptr %24, ptr %25, align 8
  %26 = load ptr, ptr %19, align 8
  %27 = load ptr, ptr %25, align 8
  %28 = call ptr @cartan_tensor_matmul(ptr %26, ptr %27)
  ret ptr %28
unreachable_1:
  ret ptr null
}

define float @CosformerStream_calculate_loss(%CosformerStream %arg_this, ptr %arg_predictions, ptr %arg_targets) {
entry:
  %29 = alloca %CosformerStream, align 8
  store %CosformerStream %arg_this, ptr %29, align 8
  %30 = alloca ptr, align 4
  store ptr %arg_predictions, ptr %30, align 4
  %31 = alloca ptr, align 4
  store ptr %arg_targets, ptr %31, align 4
  %32 = load ptr, ptr %30, align 8
  %33 = load ptr, ptr %31, align 8
  %34 = call float @cartan_tensor_cross_entropy_loss(ptr %32, ptr %33)
  ret float %34
unreachable_2:
  ret float 0.0
}

define ptr @SSMStream_forward(%SSMStream %arg_this, ptr %arg_x) {
entry:
  %35 = alloca %SSMStream, align 8
  store %SSMStream %arg_this, ptr %35, align 8
  %36 = alloca ptr, align 4
  store ptr %arg_x, ptr %36, align 4
  %37 = getelementptr inbounds %SSMStream, ptr %35, i32 0, i32 4
  %38 = load ptr, ptr %37, align 8
  %39 = getelementptr inbounds %SSMStream, ptr %35, i32 0, i32 0
  %40 = load ptr, ptr %39, align 8
  %41 = call ptr @cartan_tensor_matmul(ptr %38, ptr %40)
  %42 = alloca ptr, align 8
  store ptr %41, ptr %42, align 8
  %43 = load ptr, ptr %36, align 8
  %44 = getelementptr inbounds %SSMStream, ptr %35, i32 0, i32 1
  %45 = load ptr, ptr %44, align 8
  %46 = call ptr @cartan_tensor_matmul(ptr %43, ptr %45)
  %47 = alloca ptr, align 8
  store ptr %46, ptr %47, align 8
  ; --- Begin Fused Kernel ---
  %48 = load ptr, ptr %42, align 8
  %49 = load ptr, ptr %47, align 8
  %50 = call ptr @cartan_tensor_add(ptr %48, ptr %49)
  ; --- End Fused Kernel ---
  %51 = alloca ptr, align 8
  store ptr %50, ptr %51, align 8
  %52 = getelementptr inbounds %SSMStream, ptr %35, i32 0, i32 4
  %53 = load ptr, ptr %52, align 8
  %54 = getelementptr inbounds %SSMStream, ptr %35, i32 0, i32 2
  %55 = load ptr, ptr %54, align 8
  %56 = call ptr @cartan_tensor_matmul(ptr %53, ptr %55)
  %57 = alloca ptr, align 8
  store ptr %56, ptr %57, align 8
  %58 = load ptr, ptr %36, align 8
  %59 = getelementptr inbounds %SSMStream, ptr %35, i32 0, i32 3
  %60 = load ptr, ptr %59, align 8
  %61 = call ptr @cartan_tensor_matmul(ptr %58, ptr %60)
  %62 = alloca ptr, align 8
  store ptr %61, ptr %62, align 8
  ; --- Begin Fused Kernel ---
  %63 = load ptr, ptr %57, align 8
  %64 = load ptr, ptr %62, align 8
  %65 = call ptr @cartan_tensor_add(ptr %63, ptr %64)
  ; --- End Fused Kernel ---
  %66 = alloca ptr, align 8
  store ptr %65, ptr %66, align 8
  %67 = load ptr, ptr %66, align 8
  ret ptr %67
unreachable_3:
  ret ptr null
}

define float @SSMStream_calculate_loss(%SSMStream %arg_this, ptr %arg_predictions, ptr %arg_targets) {
entry:
  %68 = alloca %SSMStream, align 8
  store %SSMStream %arg_this, ptr %68, align 8
  %69 = alloca ptr, align 4
  store ptr %arg_predictions, ptr %69, align 4
  %70 = alloca ptr, align 4
  store ptr %arg_targets, ptr %70, align 4
  %71 = load ptr, ptr %69, align 8
  %72 = load ptr, ptr %70, align 8
  %73 = call float @cartan_tensor_spherical_cosine_loss(ptr %71, ptr %72)
  ret float %73
unreachable_4:
  ret float 0.0
}

define ptr @SpectralStream_forward(%SpectralStream %arg_this, ptr %arg_x) {
entry:
  %74 = alloca %SpectralStream, align 8
  store %SpectralStream %arg_this, ptr %74, align 8
  %75 = alloca ptr, align 4
  store ptr %arg_x, ptr %75, align 4
  ; --- Begin Fused Kernel ---
  %76 = load ptr, ptr %75, align 8
  %77 = getelementptr inbounds %SpectralStream, ptr %74, i32 0, i32 0
  %78 = load ptr, ptr %77, align 8
  %79 = call ptr @cartan_tensor_mul(ptr %76, ptr %78)
  ; --- End Fused Kernel ---
  ret ptr %79
unreachable_5:
  ret ptr null
}

define float @SpectralStream_calculate_loss(%SpectralStream %arg_this, ptr %arg_predictions, ptr %arg_targets) {
entry:
  %80 = alloca %SpectralStream, align 8
  store %SpectralStream %arg_this, ptr %80, align 8
  %81 = alloca ptr, align 4
  store ptr %arg_predictions, ptr %81, align 4
  %82 = alloca ptr, align 4
  store ptr %arg_targets, ptr %82, align 4
  %83 = load ptr, ptr %81, align 8
  %84 = load ptr, ptr %82, align 8
  %85 = call float @cartan_tensor_mse_loss(ptr %83, ptr %84)
  ret float %85
unreachable_6:
  ret float 0.0
}

define ptr @PoincareStream_forward(%PoincareStream %arg_this, ptr %arg_x) {
entry:
  %86 = alloca %PoincareStream, align 8
  store %PoincareStream %arg_this, ptr %86, align 8
  %87 = alloca ptr, align 4
  store ptr %arg_x, ptr %87, align 4
  %88 = load ptr, ptr %87, align 8
  %89 = getelementptr inbounds %PoincareStream, ptr %86, i32 0, i32 0
  %90 = load ptr, ptr %89, align 8
  %91 = call ptr @cartan_tensor_matmul(ptr %88, ptr %90)
  ret ptr %91
unreachable_7:
  ret ptr null
}

define float @PoincareStream_calculate_loss(%PoincareStream %arg_this, ptr %arg_predictions, ptr %arg_targets) {
entry:
  %92 = alloca %PoincareStream, align 8
  store %PoincareStream %arg_this, ptr %92, align 8
  %93 = alloca ptr, align 4
  store ptr %arg_predictions, ptr %93, align 4
  %94 = alloca ptr, align 4
  store ptr %arg_targets, ptr %94, align 4
  %95 = load ptr, ptr %93, align 8
  %96 = load ptr, ptr %94, align 8
  %97 = call float @cartan_tensor_cross_entropy_loss(ptr %95, ptr %96)
  ret float %97
unreachable_8:
  ret float 0.0
}

define ptr @HomologyStream_forward(%HomologyStream %arg_this, ptr %arg_x) {
entry:
  %98 = alloca %HomologyStream, align 8
  store %HomologyStream %arg_this, ptr %98, align 8
  %99 = alloca ptr, align 4
  store ptr %arg_x, ptr %99, align 4
  ; --- Begin Fused Kernel ---
  %100 = load ptr, ptr %99, align 8
  %101 = getelementptr inbounds %HomologyStream, ptr %98, i32 0, i32 0
  %102 = load ptr, ptr %101, align 8
  %103 = call ptr @cartan_tensor_mul(ptr %100, ptr %102)
  ; --- End Fused Kernel ---
  %104 = alloca ptr, align 8
  store ptr %103, ptr %104, align 8
  %105 = load ptr, ptr %104, align 8
  ret ptr %105
unreachable_9:
  ret ptr null
}

define float @HomologyStream_calculate_loss(%HomologyStream %arg_this, ptr %arg_predictions, ptr %arg_targets) {
entry:
  %106 = alloca %HomologyStream, align 8
  store %HomologyStream %arg_this, ptr %106, align 8
  %107 = alloca ptr, align 4
  store ptr %arg_predictions, ptr %107, align 4
  %108 = alloca ptr, align 4
  store ptr %arg_targets, ptr %108, align 4
  %109 = load ptr, ptr %107, align 8
  %110 = load ptr, ptr %108, align 8
  %111 = call float @cartan_tensor_betti_homology_loss(ptr %109, ptr %110)
  ret float %111
unreachable_10:
  ret float 0.0
}

define ptr @EikonalStream_forward(%EikonalStream %arg_this, ptr %arg_x) {
entry:
  %112 = alloca %EikonalStream, align 8
  store %EikonalStream %arg_this, ptr %112, align 8
  %113 = alloca ptr, align 4
  store ptr %arg_x, ptr %113, align 4
  %114 = load ptr, ptr %113, align 8
  %115 = getelementptr inbounds %EikonalStream, ptr %112, i32 0, i32 0
  %116 = load ptr, ptr %115, align 8
  %117 = call ptr @cartan_tensor_matmul(ptr %114, ptr %116)
  %118 = alloca ptr, align 8
  store ptr %117, ptr %118, align 8
  %119 = load ptr, ptr %118, align 8
  ret ptr %119
unreachable_11:
  ret ptr null
}

define float @EikonalStream_calculate_loss(%EikonalStream %arg_this, ptr %arg_predictions, ptr %arg_targets) {
entry:
  %120 = alloca %EikonalStream, align 8
  store %EikonalStream %arg_this, ptr %120, align 8
  %121 = alloca ptr, align 4
  store ptr %arg_predictions, ptr %121, align 4
  %122 = alloca ptr, align 4
  store ptr %arg_targets, ptr %122, align 4
  %123 = load ptr, ptr %121, align 8
  %124 = load ptr, ptr %122, align 8
  %125 = call float @cartan_tensor_finsler_randers_loss(ptr %123, ptr %124)
  ret float %125
unreachable_12:
  ret float 0.0
}

define ptr @HeatKernelStream_forward(%HeatKernelStream %arg_this, ptr %arg_x) {
entry:
  %126 = alloca %HeatKernelStream, align 8
  store %HeatKernelStream %arg_this, ptr %126, align 8
  %127 = alloca ptr, align 4
  store ptr %arg_x, ptr %127, align 4
  %128 = load ptr, ptr %127, align 8
  %129 = getelementptr inbounds %HeatKernelStream, ptr %126, i32 0, i32 1
  %130 = load ptr, ptr %129, align 8
  %131 = call ptr @cartan_tensor_matmul(ptr %128, ptr %130)
  %132 = alloca ptr, align 8
  store ptr %131, ptr %132, align 8
  ; --- Begin Fused Kernel ---
  %133 = load ptr, ptr %132, align 8
  %134 = getelementptr inbounds %HeatKernelStream, ptr %126, i32 0, i32 0
  %135 = load float, ptr %134, align 4
  %136 = ptrtoint ptr %133 to i64
  %137 = sitofp i64 %136 to float
  %138 = fmul float %137, %135
  ; --- End Fused Kernel ---
  %139 = fptoui float %138 to i64
  %140 = inttoptr i64 %139 to ptr
  ret ptr %140
unreachable_13:
  ret ptr null
}

define float @HeatKernelStream_calculate_loss(%HeatKernelStream %arg_this, ptr %arg_predictions, ptr %arg_targets) {
entry:
  %141 = alloca %HeatKernelStream, align 8
  store %HeatKernelStream %arg_this, ptr %141, align 8
  %142 = alloca ptr, align 4
  store ptr %arg_predictions, ptr %142, align 4
  %143 = alloca ptr, align 4
  store ptr %arg_targets, ptr %143, align 4
  %144 = load ptr, ptr %142, align 8
  %145 = load ptr, ptr %143, align 8
  %146 = call float @cartan_tensor_mse_loss(ptr %144, ptr %145)
  ret float %146
unreachable_14:
  ret float 0.0
}

define ptr @TrialityStream_forward(%TrialityStream %arg_this, ptr %arg_x) {
entry:
  %147 = alloca %TrialityStream, align 8
  store %TrialityStream %arg_this, ptr %147, align 8
  %148 = alloca ptr, align 4
  store ptr %arg_x, ptr %148, align 4
  %149 = load ptr, ptr %148, align 8
  %150 = getelementptr inbounds %TrialityStream, ptr %147, i32 0, i32 0
  %151 = load ptr, ptr %150, align 8
  %152 = call ptr @cartan_tensor_matmul(ptr %149, ptr %151)
  %153 = alloca ptr, align 8
  store ptr %152, ptr %153, align 8
  %154 = load ptr, ptr %148, align 8
  %155 = getelementptr inbounds %TrialityStream, ptr %147, i32 0, i32 1
  %156 = load ptr, ptr %155, align 8
  %157 = call ptr @cartan_tensor_matmul(ptr %154, ptr %156)
  %158 = alloca ptr, align 8
  store ptr %157, ptr %158, align 8
  %159 = load ptr, ptr %148, align 8
  %160 = getelementptr inbounds %TrialityStream, ptr %147, i32 0, i32 2
  %161 = load ptr, ptr %160, align 8
  %162 = call ptr @cartan_tensor_matmul(ptr %159, ptr %161)
  %163 = alloca ptr, align 8
  store ptr %162, ptr %163, align 8
  ; --- Begin Fused Kernel ---
  %164 = load ptr, ptr %153, align 8
  %165 = load ptr, ptr %158, align 8
  %166 = call ptr @cartan_tensor_add(ptr %164, ptr %165)
  ; --- End Fused Kernel ---
  %167 = alloca ptr, align 8
  store ptr %166, ptr %167, align 8
  ; --- Begin Fused Kernel ---
  %168 = load ptr, ptr %167, align 8
  %169 = load ptr, ptr %163, align 8
  %170 = call ptr @cartan_tensor_add(ptr %168, ptr %169)
  ; --- End Fused Kernel ---
  ret ptr %170
unreachable_15:
  ret ptr null
}

define float @TrialityStream_calculate_loss(%TrialityStream %arg_this, ptr %arg_predictions, ptr %arg_targets) {
entry:
  %171 = alloca %TrialityStream, align 8
  store %TrialityStream %arg_this, ptr %171, align 8
  %172 = alloca ptr, align 4
  store ptr %arg_predictions, ptr %172, align 4
  %173 = alloca ptr, align 4
  store ptr %arg_targets, ptr %173, align 4
  %174 = load ptr, ptr %172, align 8
  %175 = load ptr, ptr %173, align 8
  %176 = call float @cartan_tensor_cross_entropy_loss(ptr %174, ptr %175)
  ret float %176
unreachable_16:
  ret float 0.0
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

