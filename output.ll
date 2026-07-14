; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

%FinslerRandersMetric = type { float }
%E8_Manifold = type { float, float }
%SO16_Manifold = type { float }
%E7xSU2_Manifold = type { float }
%CosformerStream = type {  }
%SSMStream = type {  }
%SpectralStream = type {  }
%PoincareStream = type {  }
%HomologyStream = type {  }
%EikonalStream = type {  }
%HeatKernelStream = type { float }
%TrialityStream = type {  }
%MagicSquareExpert = type {  }
%SasakiRouter = type {  }
%E8MagicSquareMoE = type { float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float }
%GeoMindHybridEngine = type { float, float, float }

declare i32 @printf(ptr, ...)

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

define i32 @main() {
entry:
  ; --- Struct Instantiation: GeoMindHybridEngine ---
  %5 = alloca %GeoMindHybridEngine
  %6 = call i32 (ptr, ...) @printf(ptr @.str.2)
  %7 = call i32 (ptr, ...) @printf(ptr @.str.3)
  %8 = call i32 (ptr, ...) @printf(ptr @.str.4)
  %9 = call i32 (ptr, ...) @printf(ptr @.str.5)
  %10 = call i32 (ptr, ...) @printf(ptr @.str.6)
  %11 = call i32 (ptr, ...) @printf(ptr @.str.7)
  ; --- Struct Instantiation: CosformerStream ---
  %12 = alloca %CosformerStream
  %13 = load %CosformerStream, ptr %12, align 4
  %14 = alloca float, align 4
  store float 0.0, ptr %14, align 4
  %15 = alloca float, align 4
  store float 1.000000e0, ptr %15, align 4
  ; --- Begin Backward Pass ---
  %16 = load float, ptr %14, align 4
  ; --- End Backward Pass ---
  %17 = call i32 (ptr, ...) @printf(ptr @.str.10)
  ; --- Struct Instantiation: SSMStream ---
  %18 = alloca %SSMStream
  %19 = load %SSMStream, ptr %18, align 4
  %20 = alloca float, align 4
  store float 0.0, ptr %20, align 4
  %21 = alloca float, align 4
  store float 1.000000e0, ptr %21, align 4
  ; --- Begin Backward Pass ---
  %22 = load float, ptr %20, align 4
  ; --- End Backward Pass ---
  %23 = call i32 (ptr, ...) @printf(ptr @.str.13)
  ; --- Struct Instantiation: SpectralStream ---
  %24 = alloca %SpectralStream
  %25 = load %SpectralStream, ptr %24, align 4
  %26 = alloca float, align 4
  store float 0.0, ptr %26, align 4
  %27 = alloca float, align 4
  store float 1.000000e0, ptr %27, align 4
  ; --- Begin Backward Pass ---
  %28 = load float, ptr %26, align 4
  ; --- End Backward Pass ---
  %29 = call i32 (ptr, ...) @printf(ptr @.str.16)
  ; --- Struct Instantiation: PoincareStream ---
  %30 = alloca %PoincareStream
  %31 = load %PoincareStream, ptr %30, align 4
  %32 = alloca float, align 4
  store float 0.0, ptr %32, align 4
  %33 = alloca float, align 4
  store float 1.000000e0, ptr %33, align 4
  ; --- Begin Backward Pass ---
  %34 = load float, ptr %32, align 4
  ; --- End Backward Pass ---
  %35 = call i32 (ptr, ...) @printf(ptr @.str.19)
  ; --- Struct Instantiation: HomologyStream ---
  %36 = alloca %HomologyStream
  %37 = load %HomologyStream, ptr %36, align 4
  %38 = alloca float, align 4
  store float 0.0, ptr %38, align 4
  %39 = alloca float, align 4
  store float 1.000000e0, ptr %39, align 4
  ; --- Begin Backward Pass ---
  %40 = load float, ptr %38, align 4
  ; --- End Backward Pass ---
  %41 = call i32 (ptr, ...) @printf(ptr @.str.22)
  ; --- Struct Instantiation: EikonalStream ---
  %42 = alloca %EikonalStream
  %43 = load %EikonalStream, ptr %42, align 4
  %44 = alloca float, align 4
  store float 0.0, ptr %44, align 4
  %45 = alloca float, align 4
  store float 1.000000e0, ptr %45, align 4
  ; --- Begin Backward Pass ---
  %46 = load float, ptr %44, align 4
  ; --- End Backward Pass ---
  %47 = call i32 (ptr, ...) @printf(ptr @.str.25)
  ; --- Struct Instantiation: HeatKernelStream ---
  %48 = alloca %HeatKernelStream
  %49 = load %HeatKernelStream, ptr %48, align 4
  %50 = alloca float, align 4
  store float 0.0, ptr %50, align 4
  %51 = alloca float, align 4
  store float 1.000000e0, ptr %51, align 4
  ; --- Begin Backward Pass ---
  %52 = load float, ptr %50, align 4
  ; --- End Backward Pass ---
  %53 = call i32 (ptr, ...) @printf(ptr @.str.28)
  ; --- Struct Instantiation: TrialityStream ---
  %54 = alloca %TrialityStream
  %55 = load %TrialityStream, ptr %54, align 4
  %56 = alloca float, align 4
  store float 0.0, ptr %56, align 4
  %57 = alloca float, align 4
  store float 1.000000e0, ptr %57, align 4
  ; --- Begin Backward Pass ---
  %58 = load float, ptr %56, align 4
  ; --- End Backward Pass ---
  %59 = call i32 (ptr, ...) @printf(ptr @.str.31)
  %60 = call i32 (ptr, ...) @printf(ptr @.str.32)
  %61 = call i32 (ptr, ...) @printf(ptr @.str.33)
  ret i32 0
}

@.str.0 = private unnamed_addr constant [55 x i8] c"\5b\73\74\64\3a\3a\69\6f\3a\3a\53\74\72\65\61\6d\49\6e\69\74\5d\20\42\6f\6f\74\73\74\72\61\70\70\65\64\20\6e\61\74\69\76\65\20\6e\65\74\77\6f\72\6b\69\6e\67\21\0a\00", align 1
@.str.1 = private unnamed_addr constant [48 x i8] c"\5b\73\74\64\3a\3a\69\6f\3a\3a\4c\65\78\41\6e\64\45\6d\62\65\64\5d\20\45\78\65\63\75\74\69\6e\67\20\6e\61\74\69\76\65\20\6c\65\78\65\72\21\0a\00", align 1
@.str.2 = private unnamed_addr constant [49 x i8] c"\5b\41\65\74\68\65\72\20\4e\61\74\69\76\65\5d\20\42\6f\6f\74\73\74\72\61\70\70\65\64\20\6e\61\74\69\76\65\20\6e\65\74\77\6f\72\6b\69\6e\67\21\0a\00", align 1
@.str.3 = private unnamed_addr constant [51 x i8] c"\5b\41\65\74\68\65\72\20\4e\61\74\69\76\65\5d\20\45\78\65\63\75\74\69\6e\67\20\48\61\72\64\2d\4c\65\78\69\6e\67\20\46\53\41\20\4b\65\72\6e\65\6c\21\0a\00", align 1
@.str.4 = private unnamed_addr constant [43 x i8] c"\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\0a\00", align 1
@.str.5 = private unnamed_addr constant [56 x i8] c"\5b\47\65\6f\4d\69\6e\64\5d\20\54\65\73\74\69\6e\67\20\38\2d\53\74\72\65\61\6d\20\46\6f\72\77\61\72\64\20\61\6e\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\65\73\0a\00", align 1
@.str.6 = private unnamed_addr constant [43 x i8] c"\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\0a\00", align 1
@.str.7 = private unnamed_addr constant [59 x i8] c"\5b\47\65\6f\4d\69\6e\64\5d\20\54\65\73\74\69\6e\67\20\53\74\72\65\61\6d\20\30\3a\20\53\4f\28\31\36\29\20\2d\3e\20\43\6f\73\66\6f\72\6d\65\72\20\41\74\74\65\6e\74\69\6f\6e\0a\00", align 1
@.str.8 = private unnamed_addr constant [37 x i8] c"\2d\2d\2d\20\41\75\74\6f\2d\47\65\6e\65\72\61\74\65\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.9 = private unnamed_addr constant [26 x i8] c"\2d\2d\2d\20\45\6e\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.10 = private unnamed_addr constant [60 x i8] c"\5b\47\65\6f\4d\69\6e\64\5d\20\54\65\73\74\69\6e\67\20\53\74\72\65\61\6d\20\31\3a\20\45\37\20\78\20\53\55\28\32\29\20\2d\3e\20\4c\61\74\74\69\63\65\20\57\61\76\65\20\53\53\4d\0a\00", align 1
@.str.11 = private unnamed_addr constant [37 x i8] c"\2d\2d\2d\20\41\75\74\6f\2d\47\65\6e\65\72\61\74\65\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.12 = private unnamed_addr constant [26 x i8] c"\2d\2d\2d\20\45\6e\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.13 = private unnamed_addr constant [59 x i8] c"\5b\47\65\6f\4d\69\6e\64\5d\20\54\65\73\74\69\6e\67\20\53\74\72\65\61\6d\20\32\3a\20\45\36\20\78\20\53\55\28\33\29\20\2d\3e\20\53\70\65\63\74\72\61\6c\20\4d\65\6d\6f\72\79\0a\00", align 1
@.str.14 = private unnamed_addr constant [37 x i8] c"\2d\2d\2d\20\41\75\74\6f\2d\47\65\6e\65\72\61\74\65\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.15 = private unnamed_addr constant [26 x i8] c"\2d\2d\2d\20\45\6e\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.16 = private unnamed_addr constant [59 x i8] c"\5b\47\65\6f\4d\69\6e\64\5d\20\54\65\73\74\69\6e\67\20\53\74\72\65\61\6d\20\33\3a\20\53\55\28\39\29\20\2d\3e\20\48\79\70\65\72\62\6f\6c\69\63\20\41\74\74\65\6e\74\69\6f\6e\0a\00", align 1
@.str.17 = private unnamed_addr constant [37 x i8] c"\2d\2d\2d\20\41\75\74\6f\2d\47\65\6e\65\72\61\74\65\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.18 = private unnamed_addr constant [26 x i8] c"\2d\2d\2d\20\45\6e\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.19 = private unnamed_addr constant [59 x i8] c"\5b\47\65\6f\4d\69\6e\64\5d\20\54\65\73\74\69\6e\67\20\53\74\72\65\61\6d\20\34\3a\20\46\34\20\78\20\47\32\20\2d\3e\20\48\6f\6d\6f\6c\6f\67\79\20\41\74\74\65\6e\74\69\6f\6e\0a\00", align 1
@.str.20 = private unnamed_addr constant [37 x i8] c"\2d\2d\2d\20\41\75\74\6f\2d\47\65\6e\65\72\61\74\65\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.21 = private unnamed_addr constant [26 x i8] c"\2d\2d\2d\20\45\6e\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.22 = private unnamed_addr constant [67 x i8] c"\5b\47\65\6f\4d\69\6e\64\5d\20\54\65\73\74\69\6e\67\20\53\74\72\65\61\6d\20\35\3a\20\53\55\28\35\29\20\78\20\53\55\28\35\29\20\2d\3e\20\47\65\6f\64\65\73\69\63\20\52\61\79\2d\54\72\61\63\69\6e\67\0a\00", align 1
@.str.23 = private unnamed_addr constant [37 x i8] c"\2d\2d\2d\20\41\75\74\6f\2d\47\65\6e\65\72\61\74\65\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.24 = private unnamed_addr constant [26 x i8] c"\2d\2d\2d\20\45\6e\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.25 = private unnamed_addr constant [62 x i8] c"\5b\47\65\6f\4d\69\6e\64\5d\20\54\65\73\74\69\6e\67\20\53\74\72\65\61\6d\20\36\3a\20\53\4f\28\31\30\29\20\78\20\53\55\28\34\29\20\2d\3e\20\48\65\61\74\20\44\69\66\66\75\73\69\6f\6e\0a\00", align 1
@.str.26 = private unnamed_addr constant [37 x i8] c"\2d\2d\2d\20\41\75\74\6f\2d\47\65\6e\65\72\61\74\65\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.27 = private unnamed_addr constant [26 x i8] c"\2d\2d\2d\20\45\6e\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.28 = private unnamed_addr constant [60 x i8] c"\5b\47\65\6f\4d\69\6e\64\5d\20\54\65\73\74\69\6e\67\20\53\74\72\65\61\6d\20\37\3a\20\53\55\28\33\29\5e\33\20\2d\3e\20\53\79\6d\70\6c\65\63\74\69\63\20\54\72\69\61\6c\69\74\79\0a\00", align 1
@.str.29 = private unnamed_addr constant [37 x i8] c"\2d\2d\2d\20\41\75\74\6f\2d\47\65\6e\65\72\61\74\65\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.30 = private unnamed_addr constant [26 x i8] c"\2d\2d\2d\20\45\6e\64\20\42\61\63\6b\77\61\72\64\20\50\61\73\73\20\2d\2d\2d\00", align 1
@.str.31 = private unnamed_addr constant [43 x i8] c"\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\0a\00", align 1
@.str.32 = private unnamed_addr constant [63 x i8] c"\5b\47\65\6f\4d\69\6e\64\5d\20\41\6c\6c\20\38\20\53\74\72\65\61\6d\73\20\67\65\6e\65\72\61\74\65\64\20\62\61\63\6b\77\61\72\64\20\70\61\73\73\20\73\75\63\63\65\73\73\66\75\6c\6c\79\21\0a\00", align 1
@.str.33 = private unnamed_addr constant [43 x i8] c"\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\3d\0a\00", align 1
