; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

%FinslerRandersMetric = type { ptr, float }
%E8_Manifold = type { float, %FinslerRandersMetric, ptr }
%SO16_Manifold = type { float }
%E7xSU2_Manifold = type { float }
%CosformerStream = type { ptr, ptr, ptr }
%SSMStream = type { ptr, ptr, ptr, ptr, ptr }
%SpectralStream = type { ptr }
%PoincareStream = type { ptr }
%HomologyStream = type { ptr }
%EikonalStream = type { ptr }
%HeatKernelStream = type { float, ptr }
%TrialityStream = type { ptr, ptr, ptr }
%MagicSquareExpert = type { ptr }
%SasakiRouter = type { ptr }
%E8MagicSquareMoE = type { %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %MagicSquareExpert, %SasakiRouter }
%GeoMindHybridEngine = type { float, %E8MagicSquareMoE, ptr, ptr, float }

declare i32 @printf(ptr, ...)
declare ptr @fopen(ptr, ptr)
declare i32 @fread(ptr, i32, i32, ptr)
declare i32 @fseek(ptr, i32, i32)
declare i32 @fclose(ptr)
declare i32 @clock()
declare i32 @strcmp(ptr, ptr)

define void @io_stream_init(ptr %arg_uri) {
entry:
  %1 = alloca ptr, align 4
  store ptr %arg_uri, ptr %1, align 4
  %2 = call i32 (ptr, ...) @printf(ptr @.str.0)
  ret void
}

define void @io_lex_and_embed(ptr %arg_input_stream) {
entry:
  %3 = alloca ptr, align 4
  store ptr %arg_input_stream, ptr %3, align 4
  %4 = call i32 (ptr, ...) @printf(ptr @.str.1)
  ret void
}

define ptr @FinslerRandersMetric_compute_distance(%FinslerRandersMetric %arg_this, ptr %arg_x, ptr %arg_y) {
entry:
  %5 = alloca %FinslerRandersMetric, align 8
  store %FinslerRandersMetric %arg_this, ptr %5, align 8
  %6 = alloca ptr, align 4
  store ptr %arg_x, ptr %6, align 4
  %7 = alloca ptr, align 4
  store ptr %arg_y, ptr %7, align 4
  ; --- Begin Fused Kernel ---
  %8 = load ptr, ptr %6, align 8
  %9 = load ptr, ptr %7, align 8
  %10 = call ptr @cartan_tensor_sub(ptr %8, ptr %9)
  ; --- End Fused Kernel ---
  %11 = alloca ptr, align 8
  store ptr %10, ptr %11, align 8
  %12 = load ptr, ptr %11, align 8
  %13 = load ptr, ptr %11, align 8
  %14 = call ptr @cartan_tensor_matmul(ptr %12, ptr %13)
  %15 = alloca ptr, align 8
  store ptr %14, ptr %15, align 8
  %16 = getelementptr inbounds %FinslerRandersMetric, ptr %5, i32 0, i32 0
  %17 = load ptr, ptr %16, align 8
  %18 = load ptr, ptr %7, align 8
  %19 = call ptr @cartan_tensor_matmul(ptr %17, ptr %18)
  %20 = alloca ptr, align 8
  store ptr %19, ptr %20, align 8
  ; --- Begin Fused Kernel ---
  %21 = load ptr, ptr %15, align 8
  %22 = load ptr, ptr %20, align 8
  %23 = call ptr @cartan_tensor_add(ptr %21, ptr %22)
  ; --- End Fused Kernel ---
  ret ptr %23
unreachable_1:
  ret ptr null
}

define ptr @FinslerRandersMetric_compute_geodesic_gradient(%FinslerRandersMetric %arg_this, ptr %arg_grad) {
entry:
  %24 = alloca %FinslerRandersMetric, align 8
  store %FinslerRandersMetric %arg_this, ptr %24, align 8
  %25 = alloca ptr, align 4
  store ptr %arg_grad, ptr %25, align 4
  %26 = getelementptr inbounds %FinslerRandersMetric, ptr %24, i32 0, i32 0
  %27 = load ptr, ptr %26, align 8
  %28 = getelementptr inbounds %FinslerRandersMetric, ptr %24, i32 0, i32 0
  %29 = load ptr, ptr %28, align 8
  %30 = call ptr @cartan_tensor_matmul(ptr %27, ptr %29)
  %31 = alloca ptr, align 8
  store ptr %30, ptr %31, align 8
  %32 = load ptr, ptr %25, align 8
  %33 = getelementptr inbounds %FinslerRandersMetric, ptr %24, i32 0, i32 0
  %34 = load ptr, ptr %33, align 8
  %35 = call ptr @cartan_tensor_matmul(ptr %32, ptr %34)
  %36 = alloca ptr, align 8
  store ptr %35, ptr %36, align 8
  ; --- Begin Fused Kernel ---
  %37 = load ptr, ptr %31, align 8
  %38 = ptrtoint ptr %37 to i64
  %39 = sitofp i64 %38 to float
  %40 = fadd float 0x3FF0000000000000, %39
  ; --- End Fused Kernel ---
  %41 = alloca float, align 4
  store float %40, ptr %41, align 4
  ; --- Begin Fused Kernel ---
  %42 = load ptr, ptr %36, align 8
  %43 = load float, ptr %41, align 4
  %44 = ptrtoint ptr %42 to i64
  %45 = sitofp i64 %44 to float
  %46 = fdiv float %45, %43
  ; --- End Fused Kernel ---
  %47 = alloca float, align 4
  store float %46, ptr %47, align 4
  ; --- Begin Fused Kernel ---
  %48 = getelementptr inbounds %FinslerRandersMetric, ptr %24, i32 0, i32 0
  %49 = load ptr, ptr %48, align 8
  %50 = load float, ptr %47, align 4
  %51 = ptrtoint ptr %49 to i64
  %52 = sitofp i64 %51 to float
  %53 = fmul float %52, %50
  ; --- End Fused Kernel ---
  %54 = alloca float, align 4
  store float %53, ptr %54, align 4
  ; --- Begin Fused Kernel ---
  %55 = load ptr, ptr %25, align 8
  %56 = load float, ptr %54, align 4
  %57 = ptrtoint ptr %55 to i64
  %58 = sitofp i64 %57 to float
  %59 = fsub float %58, %56
  ; --- End Fused Kernel ---
  %60 = fptoui float %59 to i64
  %61 = inttoptr i64 %60 to ptr
  ret ptr %61
unreachable_2:
  ret ptr null
}

define ptr @E8_Manifold_project_to_lattice(%E8_Manifold %arg_this, ptr %arg_x) {
entry:
  %62 = alloca %E8_Manifold, align 8
  store %E8_Manifold %arg_this, ptr %62, align 8
  %63 = alloca ptr, align 4
  store ptr %arg_x, ptr %63, align 4
  %64 = load ptr, ptr %63, align 8
  ret ptr %64
unreachable_3:
  ret ptr null
}

define ptr @CosformerStream_forward(%CosformerStream %arg_this, ptr %arg_x) {
entry:
  %65 = alloca %CosformerStream, align 8
  store %CosformerStream %arg_this, ptr %65, align 8
  %66 = alloca ptr, align 4
  store ptr %arg_x, ptr %66, align 4
  %67 = load ptr, ptr %66, align 8
  %68 = getelementptr inbounds %CosformerStream, ptr %65, i32 0, i32 0
  %69 = load ptr, ptr %68, align 8
  %70 = call ptr @cartan_tensor_matmul(ptr %67, ptr %69)
  %71 = alloca ptr, align 8
  store ptr %70, ptr %71, align 8
  %72 = load ptr, ptr %66, align 8
  %73 = getelementptr inbounds %CosformerStream, ptr %65, i32 0, i32 1
  %74 = load ptr, ptr %73, align 8
  %75 = call ptr @cartan_tensor_matmul(ptr %72, ptr %74)
  %76 = alloca ptr, align 8
  store ptr %75, ptr %76, align 8
  %77 = load ptr, ptr %66, align 8
  %78 = getelementptr inbounds %CosformerStream, ptr %65, i32 0, i32 2
  %79 = load ptr, ptr %78, align 8
  %80 = call ptr @cartan_tensor_matmul(ptr %77, ptr %79)
  %81 = alloca ptr, align 8
  store ptr %80, ptr %81, align 8
  %82 = load ptr, ptr %71, align 8
  %83 = alloca ptr, align 8
  store ptr %82, ptr %83, align 8
  %84 = load ptr, ptr %76, align 8
  %85 = alloca ptr, align 8
  store ptr %84, ptr %85, align 8
  %86 = load ptr, ptr %85, align 8
  %87 = load ptr, ptr %81, align 8
  %88 = call ptr @cartan_tensor_matmul(ptr %86, ptr %87)
  %89 = alloca ptr, align 8
  store ptr %88, ptr %89, align 8
  %90 = load ptr, ptr %83, align 8
  %91 = load ptr, ptr %89, align 8
  %92 = call ptr @cartan_tensor_matmul(ptr %90, ptr %91)
  ret ptr %92
unreachable_4:
  ret ptr null
}

define ptr @SSMStream_forward(%SSMStream %arg_this, ptr %arg_x) {
entry:
  %93 = alloca %SSMStream, align 8
  store %SSMStream %arg_this, ptr %93, align 8
  %94 = alloca ptr, align 4
  store ptr %arg_x, ptr %94, align 4
  %95 = getelementptr inbounds %SSMStream, ptr %93, i32 0, i32 4
  %96 = load ptr, ptr %95, align 8
  %97 = getelementptr inbounds %SSMStream, ptr %93, i32 0, i32 0
  %98 = load ptr, ptr %97, align 8
  %99 = call ptr @cartan_tensor_matmul(ptr %96, ptr %98)
  %100 = alloca ptr, align 8
  store ptr %99, ptr %100, align 8
  %101 = load ptr, ptr %94, align 8
  %102 = getelementptr inbounds %SSMStream, ptr %93, i32 0, i32 1
  %103 = load ptr, ptr %102, align 8
  %104 = call ptr @cartan_tensor_matmul(ptr %101, ptr %103)
  %105 = alloca ptr, align 8
  store ptr %104, ptr %105, align 8
  ; --- Begin Fused Kernel ---
  %106 = load ptr, ptr %100, align 8
  %107 = load ptr, ptr %105, align 8
  %108 = call ptr @cartan_tensor_add(ptr %106, ptr %107)
  ; --- End Fused Kernel ---
  %109 = alloca ptr, align 8
  store ptr %108, ptr %109, align 8
  %110 = getelementptr inbounds %SSMStream, ptr %93, i32 0, i32 4
  %111 = load ptr, ptr %110, align 8
  %112 = getelementptr inbounds %SSMStream, ptr %93, i32 0, i32 2
  %113 = load ptr, ptr %112, align 8
  %114 = call ptr @cartan_tensor_matmul(ptr %111, ptr %113)
  %115 = alloca ptr, align 8
  store ptr %114, ptr %115, align 8
  %116 = load ptr, ptr %94, align 8
  %117 = getelementptr inbounds %SSMStream, ptr %93, i32 0, i32 3
  %118 = load ptr, ptr %117, align 8
  %119 = call ptr @cartan_tensor_matmul(ptr %116, ptr %118)
  %120 = alloca ptr, align 8
  store ptr %119, ptr %120, align 8
  ; --- Begin Fused Kernel ---
  %121 = load ptr, ptr %115, align 8
  %122 = load ptr, ptr %120, align 8
  %123 = call ptr @cartan_tensor_add(ptr %121, ptr %122)
  ; --- End Fused Kernel ---
  %124 = alloca ptr, align 8
  store ptr %123, ptr %124, align 8
  %125 = load ptr, ptr %124, align 8
  ret ptr %125
unreachable_5:
  ret ptr null
}

define ptr @SpectralStream_forward(%SpectralStream %arg_this, ptr %arg_x) {
entry:
  %126 = alloca %SpectralStream, align 8
  store %SpectralStream %arg_this, ptr %126, align 8
  %127 = alloca ptr, align 4
  store ptr %arg_x, ptr %127, align 4
  ; --- Begin Fused Kernel ---
  %128 = load ptr, ptr %127, align 8
  %129 = getelementptr inbounds %SpectralStream, ptr %126, i32 0, i32 0
  %130 = load ptr, ptr %129, align 8
  %131 = call ptr @cartan_tensor_mul(ptr %128, ptr %130)
  ; --- End Fused Kernel ---
  ret ptr %131
unreachable_6:
  ret ptr null
}

define ptr @PoincareStream_forward(%PoincareStream %arg_this, ptr %arg_x) {
entry:
  %132 = alloca %PoincareStream, align 8
  store %PoincareStream %arg_this, ptr %132, align 8
  %133 = alloca ptr, align 4
  store ptr %arg_x, ptr %133, align 4
  %134 = load ptr, ptr %133, align 8
  %135 = getelementptr inbounds %PoincareStream, ptr %132, i32 0, i32 0
  %136 = load ptr, ptr %135, align 8
  %137 = call ptr @cartan_tensor_matmul(ptr %134, ptr %136)
  ret ptr %137
unreachable_7:
  ret ptr null
}

define ptr @HomologyStream_forward(%HomologyStream %arg_this, ptr %arg_x) {
entry:
  %138 = alloca %HomologyStream, align 8
  store %HomologyStream %arg_this, ptr %138, align 8
  %139 = alloca ptr, align 4
  store ptr %arg_x, ptr %139, align 4
  ; --- Begin Fused Kernel ---
  %140 = load ptr, ptr %139, align 8
  %141 = getelementptr inbounds %HomologyStream, ptr %138, i32 0, i32 0
  %142 = load ptr, ptr %141, align 8
  %143 = call ptr @cartan_tensor_mul(ptr %140, ptr %142)
  ; --- End Fused Kernel ---
  %144 = alloca ptr, align 8
  store ptr %143, ptr %144, align 8
  %145 = load ptr, ptr %144, align 8
  ret ptr %145
unreachable_8:
  ret ptr null
}

define ptr @EikonalStream_forward(%EikonalStream %arg_this, ptr %arg_x) {
entry:
  %146 = alloca %EikonalStream, align 8
  store %EikonalStream %arg_this, ptr %146, align 8
  %147 = alloca ptr, align 4
  store ptr %arg_x, ptr %147, align 4
  %148 = load ptr, ptr %147, align 8
  %149 = getelementptr inbounds %EikonalStream, ptr %146, i32 0, i32 0
  %150 = load ptr, ptr %149, align 8
  %151 = call ptr @cartan_tensor_matmul(ptr %148, ptr %150)
  %152 = alloca ptr, align 8
  store ptr %151, ptr %152, align 8
  %153 = load ptr, ptr %152, align 8
  ret ptr %153
unreachable_9:
  ret ptr null
}

define ptr @HeatKernelStream_forward(%HeatKernelStream %arg_this, ptr %arg_x) {
entry:
  %154 = alloca %HeatKernelStream, align 8
  store %HeatKernelStream %arg_this, ptr %154, align 8
  %155 = alloca ptr, align 4
  store ptr %arg_x, ptr %155, align 4
  %156 = load ptr, ptr %155, align 8
  %157 = getelementptr inbounds %HeatKernelStream, ptr %154, i32 0, i32 1
  %158 = load ptr, ptr %157, align 8
  %159 = call ptr @cartan_tensor_matmul(ptr %156, ptr %158)
  %160 = alloca ptr, align 8
  store ptr %159, ptr %160, align 8
  ; --- Begin Fused Kernel ---
  %161 = load ptr, ptr %160, align 8
  %162 = getelementptr inbounds %HeatKernelStream, ptr %154, i32 0, i32 0
  %163 = load float, ptr %162, align 4
  %164 = ptrtoint ptr %161 to i64
  %165 = sitofp i64 %164 to float
  %166 = fmul float %165, %163
  ; --- End Fused Kernel ---
  %167 = fptoui float %166 to i64
  %168 = inttoptr i64 %167 to ptr
  ret ptr %168
unreachable_10:
  ret ptr null
}

define ptr @TrialityStream_forward(%TrialityStream %arg_this, ptr %arg_x) {
entry:
  %169 = alloca %TrialityStream, align 8
  store %TrialityStream %arg_this, ptr %169, align 8
  %170 = alloca ptr, align 4
  store ptr %arg_x, ptr %170, align 4
  %171 = load ptr, ptr %170, align 8
  %172 = getelementptr inbounds %TrialityStream, ptr %169, i32 0, i32 0
  %173 = load ptr, ptr %172, align 8
  %174 = call ptr @cartan_tensor_matmul(ptr %171, ptr %173)
  %175 = alloca ptr, align 8
  store ptr %174, ptr %175, align 8
  %176 = load ptr, ptr %170, align 8
  %177 = getelementptr inbounds %TrialityStream, ptr %169, i32 0, i32 1
  %178 = load ptr, ptr %177, align 8
  %179 = call ptr @cartan_tensor_matmul(ptr %176, ptr %178)
  %180 = alloca ptr, align 8
  store ptr %179, ptr %180, align 8
  %181 = load ptr, ptr %170, align 8
  %182 = getelementptr inbounds %TrialityStream, ptr %169, i32 0, i32 2
  %183 = load ptr, ptr %182, align 8
  %184 = call ptr @cartan_tensor_matmul(ptr %181, ptr %183)
  %185 = alloca ptr, align 8
  store ptr %184, ptr %185, align 8
  ; --- Begin Fused Kernel ---
  %186 = load ptr, ptr %175, align 8
  %187 = load ptr, ptr %180, align 8
  %188 = call ptr @cartan_tensor_add(ptr %186, ptr %187)
  ; --- End Fused Kernel ---
  %189 = alloca ptr, align 8
  store ptr %188, ptr %189, align 8
  ; --- Begin Fused Kernel ---
  %190 = load ptr, ptr %189, align 8
  %191 = load ptr, ptr %185, align 8
  %192 = call ptr @cartan_tensor_add(ptr %190, ptr %191)
  ; --- End Fused Kernel ---
  ret ptr %192
unreachable_11:
  ret ptr null
}

define ptr @MagicSquareExpert_process(%MagicSquareExpert %arg_this, ptr %arg_x) {
entry:
  %193 = alloca %MagicSquareExpert, align 8
  store %MagicSquareExpert %arg_this, ptr %193, align 8
  %194 = alloca ptr, align 4
  store ptr %arg_x, ptr %194, align 4
  %195 = load ptr, ptr %194, align 8
  %196 = getelementptr inbounds %MagicSquareExpert, ptr %193, i32 0, i32 0
  %197 = load ptr, ptr %196, align 8
  %198 = call ptr @cartan_tensor_matmul(ptr %195, ptr %197)
  ret ptr %198
unreachable_12:
  ret ptr null
}

define ptr @SasakiRouter_route(%SasakiRouter %arg_this, ptr %arg_position, ptr %arg_momentum) {
entry:
  %199 = alloca %SasakiRouter, align 8
  store %SasakiRouter %arg_this, ptr %199, align 8
  %200 = alloca ptr, align 4
  store ptr %arg_position, ptr %200, align 4
  %201 = alloca ptr, align 4
  store ptr %arg_momentum, ptr %201, align 4
  ; --- Begin Fused Kernel ---
  %202 = load ptr, ptr %200, align 8
  %203 = load ptr, ptr %201, align 8
  %204 = call ptr @cartan_tensor_add(ptr %202, ptr %203)
  ; --- End Fused Kernel ---
  %205 = alloca ptr, align 8
  store ptr %204, ptr %205, align 8
  %206 = load ptr, ptr %205, align 8
  %207 = getelementptr inbounds %SasakiRouter, ptr %199, i32 0, i32 0
  %208 = load ptr, ptr %207, align 8
  %209 = call ptr @cartan_tensor_matmul(ptr %206, ptr %208)
  %210 = alloca ptr, align 8
  store ptr %209, ptr %210, align 8
  %211 = load ptr, ptr %210, align 8
  ret ptr %211
unreachable_13:
  ret ptr null
}

define ptr @E8MagicSquareMoE_execute_routing(%E8MagicSquareMoE %arg_this, ptr %arg_position, ptr %arg_momentum) {
entry:
  %212 = alloca %E8MagicSquareMoE, align 8
  store %E8MagicSquareMoE %arg_this, ptr %212, align 8
  %213 = alloca ptr, align 4
  store ptr %arg_position, ptr %213, align 4
  %214 = alloca ptr, align 4
  store ptr %arg_momentum, ptr %214, align 4
  %215 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 16
  %217 = load ptr, ptr %213, align 8
  %218 = load ptr, ptr %214, align 8
  %219 = load %SasakiRouter, ptr %215, align 8
  %220 = call ptr @SasakiRouter_route(%SasakiRouter %219, ptr %217, ptr %218)
  %221 = alloca ptr, align 8
  store ptr %220, ptr %221, align 8
  %222 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 0
  %224 = load ptr, ptr %213, align 8
  %225 = load %MagicSquareExpert, ptr %222, align 8
  %226 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %225, ptr %224)
  %227 = alloca ptr, align 8
  store ptr %226, ptr %227, align 8
  %228 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 1
  %230 = load ptr, ptr %213, align 8
  %231 = load %MagicSquareExpert, ptr %228, align 8
  %232 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %231, ptr %230)
  %233 = alloca ptr, align 8
  store ptr %232, ptr %233, align 8
  %234 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 2
  %236 = load ptr, ptr %213, align 8
  %237 = load %MagicSquareExpert, ptr %234, align 8
  %238 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %237, ptr %236)
  %239 = alloca ptr, align 8
  store ptr %238, ptr %239, align 8
  %240 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 3
  %242 = load ptr, ptr %213, align 8
  %243 = load %MagicSquareExpert, ptr %240, align 8
  %244 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %243, ptr %242)
  %245 = alloca ptr, align 8
  store ptr %244, ptr %245, align 8
  %246 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 4
  %248 = load ptr, ptr %213, align 8
  %249 = load %MagicSquareExpert, ptr %246, align 8
  %250 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %249, ptr %248)
  %251 = alloca ptr, align 8
  store ptr %250, ptr %251, align 8
  %252 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 5
  %254 = load ptr, ptr %213, align 8
  %255 = load %MagicSquareExpert, ptr %252, align 8
  %256 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %255, ptr %254)
  %257 = alloca ptr, align 8
  store ptr %256, ptr %257, align 8
  %258 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 6
  %260 = load ptr, ptr %213, align 8
  %261 = load %MagicSquareExpert, ptr %258, align 8
  %262 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %261, ptr %260)
  %263 = alloca ptr, align 8
  store ptr %262, ptr %263, align 8
  %264 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 7
  %266 = load ptr, ptr %213, align 8
  %267 = load %MagicSquareExpert, ptr %264, align 8
  %268 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %267, ptr %266)
  %269 = alloca ptr, align 8
  store ptr %268, ptr %269, align 8
  %270 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 8
  %272 = load ptr, ptr %213, align 8
  %273 = load %MagicSquareExpert, ptr %270, align 8
  %274 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %273, ptr %272)
  %275 = alloca ptr, align 8
  store ptr %274, ptr %275, align 8
  %276 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 9
  %278 = load ptr, ptr %213, align 8
  %279 = load %MagicSquareExpert, ptr %276, align 8
  %280 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %279, ptr %278)
  %281 = alloca ptr, align 8
  store ptr %280, ptr %281, align 8
  %282 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 10
  %284 = load ptr, ptr %213, align 8
  %285 = load %MagicSquareExpert, ptr %282, align 8
  %286 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %285, ptr %284)
  %287 = alloca ptr, align 8
  store ptr %286, ptr %287, align 8
  %288 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 11
  %290 = load ptr, ptr %213, align 8
  %291 = load %MagicSquareExpert, ptr %288, align 8
  %292 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %291, ptr %290)
  %293 = alloca ptr, align 8
  store ptr %292, ptr %293, align 8
  %294 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 12
  %296 = load ptr, ptr %213, align 8
  %297 = load %MagicSquareExpert, ptr %294, align 8
  %298 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %297, ptr %296)
  %299 = alloca ptr, align 8
  store ptr %298, ptr %299, align 8
  %300 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 13
  %302 = load ptr, ptr %213, align 8
  %303 = load %MagicSquareExpert, ptr %300, align 8
  %304 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %303, ptr %302)
  %305 = alloca ptr, align 8
  store ptr %304, ptr %305, align 8
  %306 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 14
  %308 = load ptr, ptr %213, align 8
  %309 = load %MagicSquareExpert, ptr %306, align 8
  %310 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %309, ptr %308)
  %311 = alloca ptr, align 8
  store ptr %310, ptr %311, align 8
  %312 = getelementptr inbounds %E8MagicSquareMoE, ptr %212, i32 0, i32 15
  %314 = load ptr, ptr %213, align 8
  %315 = load %MagicSquareExpert, ptr %312, align 8
  %316 = call ptr @MagicSquareExpert_process(%MagicSquareExpert %315, ptr %314)
  %317 = alloca ptr, align 8
  store ptr %316, ptr %317, align 8
  ; --- Begin Fused Kernel ---
  %318 = load ptr, ptr %227, align 8
  %319 = load ptr, ptr %233, align 8
  %320 = call ptr @cartan_tensor_add(ptr %318, ptr %319)
  %321 = load ptr, ptr %239, align 8
  %322 = call ptr @cartan_tensor_add(ptr %320, ptr %321)
  %323 = load ptr, ptr %245, align 8
  %324 = call ptr @cartan_tensor_add(ptr %322, ptr %323)
  ; --- End Fused Kernel ---
  %325 = alloca ptr, align 8
  store ptr %324, ptr %325, align 8
  ; --- Begin Fused Kernel ---
  %326 = load ptr, ptr %251, align 8
  %327 = load ptr, ptr %257, align 8
  %328 = call ptr @cartan_tensor_add(ptr %326, ptr %327)
  %329 = load ptr, ptr %263, align 8
  %330 = call ptr @cartan_tensor_add(ptr %328, ptr %329)
  %331 = load ptr, ptr %269, align 8
  %332 = call ptr @cartan_tensor_add(ptr %330, ptr %331)
  ; --- End Fused Kernel ---
  %333 = alloca ptr, align 8
  store ptr %332, ptr %333, align 8
  ; --- Begin Fused Kernel ---
  %334 = load ptr, ptr %275, align 8
  %335 = load ptr, ptr %281, align 8
  %336 = call ptr @cartan_tensor_add(ptr %334, ptr %335)
  %337 = load ptr, ptr %287, align 8
  %338 = call ptr @cartan_tensor_add(ptr %336, ptr %337)
  %339 = load ptr, ptr %293, align 8
  %340 = call ptr @cartan_tensor_add(ptr %338, ptr %339)
  ; --- End Fused Kernel ---
  %341 = alloca ptr, align 8
  store ptr %340, ptr %341, align 8
  ; --- Begin Fused Kernel ---
  %342 = load ptr, ptr %299, align 8
  %343 = load ptr, ptr %305, align 8
  %344 = call ptr @cartan_tensor_add(ptr %342, ptr %343)
  %345 = load ptr, ptr %311, align 8
  %346 = call ptr @cartan_tensor_add(ptr %344, ptr %345)
  %347 = load ptr, ptr %317, align 8
  %348 = call ptr @cartan_tensor_add(ptr %346, ptr %347)
  ; --- End Fused Kernel ---
  %349 = alloca ptr, align 8
  store ptr %348, ptr %349, align 8
  ; --- Begin Fused Kernel ---
  %350 = load ptr, ptr %325, align 8
  %351 = load ptr, ptr %333, align 8
  %352 = call ptr @cartan_tensor_add(ptr %350, ptr %351)
  %353 = load ptr, ptr %341, align 8
  %354 = call ptr @cartan_tensor_add(ptr %352, ptr %353)
  %355 = load ptr, ptr %349, align 8
  %356 = call ptr @cartan_tensor_add(ptr %354, ptr %355)
  ; --- End Fused Kernel ---
  %357 = alloca ptr, align 8
  store ptr %356, ptr %357, align 8
  %358 = load ptr, ptr %357, align 8
  ret ptr %358
unreachable_14:
  ret ptr null
}

define ptr @GeoMindHybridEngine_process_trajectory(%GeoMindHybridEngine %arg_this, ptr %arg_m_context, ptr %arg_m_gauge, ptr %arg_m_coupling) {
entry:
  %359 = alloca %GeoMindHybridEngine, align 8
  store %GeoMindHybridEngine %arg_this, ptr %359, align 8
  %360 = alloca ptr, align 4
  store ptr %arg_m_context, ptr %360, align 4
  %361 = alloca ptr, align 4
  store ptr %arg_m_gauge, ptr %361, align 4
  %362 = alloca ptr, align 4
  store ptr %arg_m_coupling, ptr %362, align 4
  %363 = load ptr, ptr %360, align 8
  %364 = getelementptr inbounds %GeoMindHybridEngine, ptr %359, i32 0, i32 2
  %365 = load ptr, ptr %364, align 8
  %366 = call ptr @cartan_tensor_embed(ptr %363, ptr %365)
  %367 = alloca ptr, align 8
  store ptr %366, ptr %367, align 8
  %368 = load ptr, ptr %367, align 8
  %369 = load ptr, ptr %361, align 8
  %370 = call ptr @cartan_tensor_matmul(ptr %368, ptr %369)
  %371 = alloca ptr, align 8
  store ptr %370, ptr %371, align 8
  %372 = getelementptr inbounds %GeoMindHybridEngine, ptr %359, i32 0, i32 1
  %374 = load ptr, ptr %371, align 8
  %375 = load ptr, ptr %362, align 8
  %376 = load %E8MagicSquareMoE, ptr %372, align 8
  %377 = call ptr @E8MagicSquareMoE_execute_routing(%E8MagicSquareMoE %376, ptr %374, ptr %375)
  %378 = alloca ptr, align 8
  store ptr %377, ptr %378, align 8
  %379 = load ptr, ptr %378, align 8
  %380 = getelementptr inbounds %GeoMindHybridEngine, ptr %359, i32 0, i32 3
  %381 = load ptr, ptr %380, align 8
  %382 = call ptr @cartan_tensor_matmul(ptr %379, ptr %381)
  %383 = alloca ptr, align 8
  store ptr %382, ptr %383, align 8
  %384 = load ptr, ptr %383, align 8
  ret ptr %384
unreachable_15:
  ret ptr null
}

define i32 @main(i32 %argc, ptr %argv) {
entry:
  store i32 %argc, ptr @global_argc, align 4
  store ptr %argv, ptr @global_argv, align 8
  ; --- Struct Instantiation: GeoMindHybridEngine ---
  %385 = alloca %GeoMindHybridEngine
  ; --- Init Elastic Vocabulary ---
  %386 = call ptr @cartan_init_elastic_vocabulary()
  %387 = getelementptr inbounds %GeoMindHybridEngine, ptr %385, i32 0, i32 0
  store ptr %386, ptr %387
  ; --- Struct Instantiation: E8MagicSquareMoE ---
  %388 = alloca %E8MagicSquareMoE
  ; --- Struct Instantiation: MagicSquareExpert ---
  %389 = alloca %MagicSquareExpert
  %390 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %391 = getelementptr inbounds %MagicSquareExpert, ptr %389, i32 0, i32 0
  store ptr %390, ptr %391
  %392 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 0
  %393 = load %MagicSquareExpert, ptr %389, align 8
  store %MagicSquareExpert %393, ptr %392, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %394 = alloca %MagicSquareExpert
  %395 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %396 = getelementptr inbounds %MagicSquareExpert, ptr %394, i32 0, i32 0
  store ptr %395, ptr %396
  %397 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 1
  %398 = load %MagicSquareExpert, ptr %394, align 8
  store %MagicSquareExpert %398, ptr %397, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %399 = alloca %MagicSquareExpert
  %400 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %401 = getelementptr inbounds %MagicSquareExpert, ptr %399, i32 0, i32 0
  store ptr %400, ptr %401
  %402 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 2
  %403 = load %MagicSquareExpert, ptr %399, align 8
  store %MagicSquareExpert %403, ptr %402, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %404 = alloca %MagicSquareExpert
  %405 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %406 = getelementptr inbounds %MagicSquareExpert, ptr %404, i32 0, i32 0
  store ptr %405, ptr %406
  %407 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 3
  %408 = load %MagicSquareExpert, ptr %404, align 8
  store %MagicSquareExpert %408, ptr %407, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %409 = alloca %MagicSquareExpert
  %410 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %411 = getelementptr inbounds %MagicSquareExpert, ptr %409, i32 0, i32 0
  store ptr %410, ptr %411
  %412 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 4
  %413 = load %MagicSquareExpert, ptr %409, align 8
  store %MagicSquareExpert %413, ptr %412, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %414 = alloca %MagicSquareExpert
  %415 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %416 = getelementptr inbounds %MagicSquareExpert, ptr %414, i32 0, i32 0
  store ptr %415, ptr %416
  %417 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 5
  %418 = load %MagicSquareExpert, ptr %414, align 8
  store %MagicSquareExpert %418, ptr %417, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %419 = alloca %MagicSquareExpert
  %420 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %421 = getelementptr inbounds %MagicSquareExpert, ptr %419, i32 0, i32 0
  store ptr %420, ptr %421
  %422 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 6
  %423 = load %MagicSquareExpert, ptr %419, align 8
  store %MagicSquareExpert %423, ptr %422, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %424 = alloca %MagicSquareExpert
  %425 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %426 = getelementptr inbounds %MagicSquareExpert, ptr %424, i32 0, i32 0
  store ptr %425, ptr %426
  %427 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 7
  %428 = load %MagicSquareExpert, ptr %424, align 8
  store %MagicSquareExpert %428, ptr %427, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %429 = alloca %MagicSquareExpert
  %430 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %431 = getelementptr inbounds %MagicSquareExpert, ptr %429, i32 0, i32 0
  store ptr %430, ptr %431
  %432 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 8
  %433 = load %MagicSquareExpert, ptr %429, align 8
  store %MagicSquareExpert %433, ptr %432, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %434 = alloca %MagicSquareExpert
  %435 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %436 = getelementptr inbounds %MagicSquareExpert, ptr %434, i32 0, i32 0
  store ptr %435, ptr %436
  %437 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 9
  %438 = load %MagicSquareExpert, ptr %434, align 8
  store %MagicSquareExpert %438, ptr %437, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %439 = alloca %MagicSquareExpert
  %440 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %441 = getelementptr inbounds %MagicSquareExpert, ptr %439, i32 0, i32 0
  store ptr %440, ptr %441
  %442 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 10
  %443 = load %MagicSquareExpert, ptr %439, align 8
  store %MagicSquareExpert %443, ptr %442, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %444 = alloca %MagicSquareExpert
  %445 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %446 = getelementptr inbounds %MagicSquareExpert, ptr %444, i32 0, i32 0
  store ptr %445, ptr %446
  %447 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 11
  %448 = load %MagicSquareExpert, ptr %444, align 8
  store %MagicSquareExpert %448, ptr %447, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %449 = alloca %MagicSquareExpert
  %450 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %451 = getelementptr inbounds %MagicSquareExpert, ptr %449, i32 0, i32 0
  store ptr %450, ptr %451
  %452 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 12
  %453 = load %MagicSquareExpert, ptr %449, align 8
  store %MagicSquareExpert %453, ptr %452, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %454 = alloca %MagicSquareExpert
  %455 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %456 = getelementptr inbounds %MagicSquareExpert, ptr %454, i32 0, i32 0
  store ptr %455, ptr %456
  %457 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 13
  %458 = load %MagicSquareExpert, ptr %454, align 8
  store %MagicSquareExpert %458, ptr %457, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %459 = alloca %MagicSquareExpert
  %460 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %461 = getelementptr inbounds %MagicSquareExpert, ptr %459, i32 0, i32 0
  store ptr %460, ptr %461
  %462 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 14
  %463 = load %MagicSquareExpert, ptr %459, align 8
  store %MagicSquareExpert %463, ptr %462, align 8
  ; --- Struct Instantiation: MagicSquareExpert ---
  %464 = alloca %MagicSquareExpert
  %465 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %466 = getelementptr inbounds %MagicSquareExpert, ptr %464, i32 0, i32 0
  store ptr %465, ptr %466
  %467 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 15
  %468 = load %MagicSquareExpert, ptr %464, align 8
  store %MagicSquareExpert %468, ptr %467, align 8
  ; --- Struct Instantiation: SasakiRouter ---
  %469 = alloca %SasakiRouter
  %470 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 16, i32 1, i32 1)
  %471 = getelementptr inbounds %SasakiRouter, ptr %469, i32 0, i32 0
  store ptr %470, ptr %471
  %472 = getelementptr inbounds %E8MagicSquareMoE, ptr %388, i32 0, i32 16
  %473 = load %SasakiRouter, ptr %469, align 8
  store %SasakiRouter %473, ptr %472, align 8
  %474 = getelementptr inbounds %GeoMindHybridEngine, ptr %385, i32 0, i32 1
  %475 = load %E8MagicSquareMoE, ptr %388, align 8
  store %E8MagicSquareMoE %475, ptr %474, align 8
  %476 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 32000, i32 248, i32 1, i32 1)
  %477 = getelementptr inbounds %GeoMindHybridEngine, ptr %385, i32 0, i32 2
  store ptr %476, ptr %477
  %478 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 32000, i32 1, i32 1)
  %479 = getelementptr inbounds %GeoMindHybridEngine, ptr %385, i32 0, i32 3
  store ptr %478, ptr %479
  %480 = getelementptr inbounds %GeoMindHybridEngine, ptr %385, i32 0, i32 4
  store float 0x3FE0000000000000, ptr %480
  %481 = call i32 (ptr, ...) @printf(ptr @.str.2)
  %482 = call ptr @sys_get_arg(float 0x3FF0000000000000)
  %483 = alloca ptr, align 8
  store ptr %482, ptr %483, align 8
  %484 = load ptr, ptr %483, align 8
  %485 = call i32 @strcmp(ptr %484, ptr @.str.3)
  %486 = sitofp i32 %485 to float
  %487 = fcmp one float %486, 0x0000000000000000
  %488 = uitofp i1 %487 to float
  %489 = fcmp one float %488, 0.0
  br i1 %489, label %then_16, label %end_18
then_16:
  %490 = call i32 (ptr, ...) @printf(ptr @.str.4)
  ret i32 0
unreachable_19:
  br label %end_18
end_18:
  %491 = call ptr @sys_get_arg(float 0x4000000000000000)
  %492 = alloca ptr, align 8
  store ptr %491, ptr %492, align 8
  %493 = load ptr, ptr %492, align 8
  %494 = call ptr @fopen(ptr %493, ptr @.str.5)
  %495 = alloca ptr, align 8
  store ptr %494, ptr %495, align 8
  %496 = load ptr, ptr %495, align 8
  %497 = ptrtoint ptr %496 to i64
  %498 = sitofp i64 %497 to float
  %499 = fcmp oeq float %498, 0x0000000000000000
  %500 = uitofp i1 %499 to float
  %501 = fcmp one float %500, 0.0
  br i1 %501, label %then_20, label %end_22
then_20:
  %502 = call i32 (ptr, ...) @printf(ptr @.str.6)
  ret i32 0
unreachable_23:
  br label %end_22
end_22:
  %503 = call i32 (ptr, ...) @printf(ptr @.str.7)
  %504 = call i32 @clock()
  %505 = sitofp i32 %504 to float
  %506 = alloca float, align 4
  store float %505, ptr %506, align 4
  %507 = alloca float, align 4
  store float 0x0000000000000000, ptr %507, align 4
  %508 = alloca float, align 4
  store float 0x0000000000000000, ptr %508, align 4
  %509 = alloca float, align 4
  store float 0x4070000000000000, ptr %509, align 4
  br label %while_cond_24
while_cond_24:
  %510 = load float, ptr %507, align 4
  %511 = fcmp olt float %510, 0x408F400000000000
  %512 = uitofp i1 %511 to float
  %513 = fcmp one float %512, 0.0
  br i1 %513, label %while_body_25, label %while_end_26
while_body_25:
  %514 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 8, i32 248, i32 1, i32 1)
  %515 = alloca ptr, align 8
  store ptr %514, ptr %515, align 8
  %516 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 8, i32 248, i32 1, i32 1)
  %517 = alloca ptr, align 8
  store ptr %516, ptr %517, align 8
  %518 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %519 = alloca ptr, align 8
  store ptr %518, ptr %519, align 8
  %520 = call ptr @cartan_tensor_alloc_nd(i32 2, i32 248, i32 248, i32 1, i32 1)
  %521 = alloca ptr, align 8
  store ptr %520, ptr %521, align 8
  %522 = load ptr, ptr %515, align 8
  %523 = load ptr, ptr %517, align 8
  %524 = load ptr, ptr %495, align 8
  %525 = call float @cartan_file_read_batch(ptr %522, ptr %523, float 0x409F000000000000, ptr %524)
  %526 = alloca float, align 4
  store float %525, ptr %526, align 4
  %527 = load float, ptr %526, align 4
  %528 = fcmp olt float %527, 0x409F000000000000
  %529 = uitofp i1 %528 to float
  %530 = fcmp one float %529, 0.0
  br i1 %530, label %then_27, label %end_29
then_27:
  %531 = call i32 (ptr, ...) @printf(ptr @.str.8)
  ret i32 0
unreachable_30:
  br label %end_29
end_29:
  %533 = load ptr, ptr %515, align 8
  %534 = load ptr, ptr %519, align 8
  %535 = load ptr, ptr %521, align 8
  %536 = load %GeoMindHybridEngine, ptr %385, align 8
  %537 = call ptr @GeoMindHybridEngine_process_trajectory(%GeoMindHybridEngine %536, ptr %533, ptr %534, ptr %535)
  %538 = alloca ptr, align 8
  store ptr %537, ptr %538, align 8
  %539 = load ptr, ptr %538, align 8
  %540 = load ptr, ptr %517, align 8
  %541 = call float @cartan_tensor_cross_entropy_loss(ptr %539, ptr %540)
  %542 = alloca float, align 4
  store float %541, ptr %542, align 4
  %543 = alloca float, align 4
  store float 0x3FF0000000000000, ptr %543, align 4
  ; --- Begin Backward Pass ---
  %544 = load float, ptr %542, align 4
  ; --- End Backward Pass ---
  ; --- Begin Fused Kernel ---
  %545 = load float, ptr %507, align 4
  %546 = fadd float %545, 0x3FF0000000000000
  ; --- End Fused Kernel ---
  store float %546, ptr %507, align 4
  ; --- Begin Fused Kernel ---
  %547 = load float, ptr %508, align 4
  %548 = load float, ptr %509, align 4
  %549 = fadd float %547, %548
  ; --- End Fused Kernel ---
  store float %549, ptr %508, align 4
  %550 = call i32 @clock()
  %551 = sitofp i32 %550 to float
  %552 = alloca float, align 4
  store float %551, ptr %552, align 4
  ; --- Begin Fused Kernel ---
  %553 = load float, ptr %552, align 4
  %554 = load float, ptr %506, align 4
  %555 = fsub float %553, %554
  ; --- End Fused Kernel ---
  %556 = alloca float, align 4
  store float %555, ptr %556, align 4
  %557 = load float, ptr %556, align 4
  %558 = fcmp oeq float %557, 0x0000000000000000
  %559 = uitofp i1 %558 to float
  %560 = fcmp one float %559, 0.0
  br i1 %560, label %then_31, label %end_33
then_31:
  store float 0x3FF0000000000000, ptr %556, align 4
  br label %end_33
end_33:
  ; --- Begin Fused Kernel ---
  %561 = load float, ptr %508, align 4
  %562 = fmul float %561, 0x408F400000000000
  %563 = load float, ptr %556, align 4
  %564 = fdiv float %562, %563
  ; --- End Fused Kernel ---
  %565 = alloca float, align 4
  store float %564, ptr %565, align 4
  %566 = load float, ptr %507, align 4
  %567 = load float, ptr %542, align 4
  %568 = load float, ptr %509, align 4
  %569 = load float, ptr %565, align 4
  %570 = fpext float %566 to double
  %571 = fpext float %567 to double
  %572 = fpext float %568 to double
  %573 = fpext float %569 to double
  %574 = call i32 (ptr, ...) @printf(ptr @.str.11, double %570, double %571, double 0x3F847AE140000000, double %572, double %573)
  br label %while_cond_24
while_end_26:
  %575 = load ptr, ptr %495, align 8
  %576 = call i32 @fclose(ptr %575)
  %577 = sitofp i32 %576 to float
  %578 = call i32 (ptr, ...) @printf(ptr @.str.12)
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
declare void @cartan_tensor_backward(ptr)
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
@.str.0 = private unnamed_addr constant [55 x i8] c"\5b\73\74\64\3a\3a\69\6f\3a\3a\53\74\72\65\61\6d\49\6e\69\74\5d\20\42\6f\6f\74\73\74\72\61\70\70\65\64\20\6e\61\74\69\76\65\20\6e\65\74\77\6f\72\6b\69\6e\67\21\0a\00", align 1
@.str.1 = private unnamed_addr constant [48 x i8] c"\5b\73\74\64\3a\3a\69\6f\3a\3a\4c\65\78\41\6e\64\45\6d\62\65\64\5d\20\45\78\65\63\75\74\69\6e\67\20\6e\61\74\69\76\65\20\6c\65\78\65\72\21\0a\00", align 1
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

@.str.2 = private unnamed_addr constant [43 x i8] c"\53\74\61\72\74\69\6e\67\20\47\65\6f\4d\69\6e\64\20\4e\61\74\69\76\65\20\44\61\74\61\20\49\6e\67\65\73\74\69\6f\6e\2e\2e\2e\0a\00", align 1
@.str.3 = private unnamed_addr constant [8 x i8] c"\2d\2d\74\72\61\69\6e\00", align 1
@.str.4 = private unnamed_addr constant [42 x i8] c"\55\73\61\67\65\3a\20\67\65\6f\6d\69\6e\64\2e\65\78\65\20\2d\2d\74\72\61\69\6e\20\3c\64\61\74\61\73\65\74\2e\62\69\6e\3e\0a\00", align 1
@.str.5 = private unnamed_addr constant [3 x i8] c"\72\62\00", align 1
@.str.6 = private unnamed_addr constant [32 x i8] c"\45\72\72\6f\72\3a\20\43\6f\75\6c\64\20\6e\6f\74\20\6f\70\65\6e\20\64\61\74\61\73\65\74\21\0a\00", align 1
@.str.7 = private unnamed_addr constant [67 x i8] c"\44\61\74\61\73\65\74\20\6f\70\65\6e\65\64\20\73\75\63\63\65\73\73\66\75\6c\6c\79\2e\20\52\65\61\64\79\20\74\6f\20\73\74\72\65\61\6d\20\72\61\77\20\62\69\6e\61\72\79\20\74\6f\6b\65\6e\73\2e\2e\2e\0a\00", align 1
@.str.8 = private unnamed_addr constant [25 x i8] c"\45\6e\64\20\6f\66\20\64\61\74\61\73\65\74\20\72\65\61\63\68\65\64\21\0a\00", align 1
@.str.9 = private unnamed_addr constant [37 x i8] c"\2d\2d\2d\20\41\75\74\6f\2d\47\65\6e\65\72\61\74\65\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.10 = private unnamed_addr constant [26 x i8] c"\2d\2d\2d\20\45\6e\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.11 = private unnamed_addr constant [61 x i8] c"\53\74\65\70\3a\20\25\66\20\7c\20\4c\6f\73\73\3a\20\25\66\20\7c\20\6c\72\3a\20\25\66\20\7c\20\73\65\71\5f\6c\65\6e\3a\20\25\66\20\7c\20\74\6f\6b\65\6e\73\2f\73\65\63\3a\20\25\66\0a\00", align 1
@.str.12 = private unnamed_addr constant [20 x i8] c"\54\72\61\69\6e\69\6e\67\20\63\6f\6d\70\6c\65\74\65\2e\0a\00", align 1
