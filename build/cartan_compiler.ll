; ModuleID = 'CartanModule'
source_filename = "cartan_source"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc"

%Parameter = type {  }
%GenericBound = type {  }
%Expr = type {  }
%Stmt = type {  }
%FunctionDecl = type {  }
%Program = type {  }
%Token = type {  }
%Lexer = type {  }
%Parser = type {  }
%LLVMGenerator = type {  }


define ptr @lexer_init(ptr %arg_source_text) {
entry:
  %1 = alloca ptr, align 4
  store ptr %arg_source_text, ptr %1, align 4
  %2 = fptoui float 0.0 to i64
  %3 = inttoptr i64 %2 to ptr
  ret ptr %3
unreachable_1:
  ret ptr null
}

define ptr @lexer_is_at_end(ptr %arg_lexer) {
entry:
  %4 = alloca ptr, align 4
  store ptr %arg_lexer, ptr %4, align 4
  %5 = getelementptr inbounds ptr, ptr %4, i32 0, i32 0
  %6 = load float, ptr %5, align 4
  %7 = getelementptr inbounds ptr, ptr %4, i32 0, i32 0
  %8 = load float, ptr %7, align 4
  %9 = call float @StructName_string_length(%StructName undef, float %8)
  %10 = fcmp oge float %6, %9
  %11 = uitofp i1 %10 to float
  %12 = fptoui float %11 to i64
  %13 = inttoptr i64 %12 to ptr
  ret ptr %13
unreachable_2:
  ret ptr null
}

define ptr @lexer_advance(ptr %arg_lexer) {
entry:
  %14 = alloca ptr, align 4
  store ptr %arg_lexer, ptr %14, align 4
  %15 = getelementptr inbounds ptr, ptr %14, i32 0, i32 0
  %16 = load float, ptr %15, align 4
  %17 = getelementptr inbounds ptr, ptr %14, i32 0, i32 0
  %18 = load float, ptr %17, align 4
  %19 = call float @StructName_string_char_at(%StructName undef, float %16, float %18)
  %20 = alloca float, align 4
  store float %19, ptr %20, align 4
  %21 = getelementptr inbounds ptr, ptr %14, i32 0, i32 0
  %22 = load float, ptr %21, align 4
  %23 = fadd float %22, 1
  %24 = getelementptr inbounds ptr, ptr %14, i32 0, i32 0
  store float %23, ptr %24, align 4
  %25 = getelementptr inbounds ptr, ptr %14, i32 0, i32 0
  %26 = load float, ptr %25, align 4
  %27 = fadd float %26, 1
  %28 = getelementptr inbounds ptr, ptr %14, i32 0, i32 0
  store float %27, ptr %28, align 4
  %29 = load float, ptr %20, align 4
  %30 = fcmp oeq float %29, string:@.str.0
  %31 = uitofp i1 %30 to float
  %32 = fcmp one float %31, 0.0
  br i1 %32, label %then_3, label %end_5
then_3:
  %33 = getelementptr inbounds ptr, ptr %14, i32 0, i32 0
  %34 = load float, ptr %33, align 4
  %35 = fadd float %34, 1
  %36 = getelementptr inbounds ptr, ptr %14, i32 0, i32 0
  store float %35, ptr %36, align 4
  %37 = getelementptr inbounds ptr, ptr %14, i32 0, i32 0
  store float 1, ptr %37, align 4
  br label %end_5
end_5:
  %38 = load float, ptr %20, align 4
  %39 = fptoui float %38 to i64
  %40 = inttoptr i64 %39 to ptr
  ret ptr %40
unreachable_6:
  ret ptr null
}

define ptr @lexer_peek(ptr %arg_lexer) {
entry:
  %41 = alloca ptr, align 4
  store ptr %arg_lexer, ptr %41, align 4
  %42 = getelementptr inbounds ptr, ptr %41, i32 0, i32 0
  %43 = load float, ptr %42, align 4
  %44 = getelementptr inbounds ptr, ptr %41, i32 0, i32 0
  %45 = load float, ptr %44, align 4
  %46 = call float @StructName_string_length(%StructName undef, float %45)
  %47 = fcmp oge float %43, %46
  %48 = uitofp i1 %47 to float
  %49 = fcmp one float %48, 0.0
  br i1 %49, label %then_7, label %end_9
then_7:
  %50 = fptoui float string:@.str.1 to i64
  %51 = inttoptr i64 %50 to ptr
  ret ptr %51
unreachable_10:
  br label %end_9
end_9:
  %52 = getelementptr inbounds ptr, ptr %41, i32 0, i32 0
  %53 = load float, ptr %52, align 4
  %54 = getelementptr inbounds ptr, ptr %41, i32 0, i32 0
  %55 = load float, ptr %54, align 4
  %56 = call float @StructName_string_char_at(%StructName undef, float %53, float %55)
  %57 = fptoui float %56 to i64
  %58 = inttoptr i64 %57 to ptr
  ret ptr %58
unreachable_11:
  ret ptr null
}

define ptr @lexer_next_token(ptr %arg_lexer) {
entry:
  %59 = alloca ptr, align 4
  store ptr %arg_lexer, ptr %59, align 4
  br label %while_cond_12
while_cond_12:
  %60 = fcmp one float 0.0, 0.0
  br i1 %60, label %while_body_13, label %while_end_14
while_body_13:
  %61 = load ptr, ptr %59, align 8
  %62 = call float @lexer_peek_euclidean(ptr %61)
  %63 = alloca float, align 4
  store float %62, ptr %63, align 4
  %64 = load float, ptr %63, align 4
  %65 = fcmp oeq float %64, string:@.str.2
  %66 = uitofp i1 %65 to float
  %67 = load float, ptr %63, align 4
  %68 = fcmp oeq float %67, string:@.str.3
  %69 = uitofp i1 %68 to float
  %70 = fcmp one float 0.0, 0.0
  br i1 %70, label %then_15, label %else_16
then_15:
  %71 = load ptr, ptr %59, align 8
  %72 = call float @lexer_advance_euclidean(ptr %71)
  br label %end_17
else_16:
  br label %while_end_14
unreachable_18:
  br label %end_17
end_17:
  br label %while_cond_12
while_end_14:
  %73 = load ptr, ptr %59, align 8
  %74 = call float @lexer_is_at_end_euclidean(ptr %73)
  %75 = fcmp one float %74, 0.0
  br i1 %75, label %then_19, label %end_21
then_19:
  %76 = fptoui float 0.0 to i64
  %77 = inttoptr i64 %76 to ptr
  ret ptr %77
unreachable_22:
  br label %end_21
end_21:
  %78 = getelementptr inbounds ptr, ptr %59, i32 0, i32 0
  %79 = load float, ptr %78, align 4
  %80 = alloca float, align 4
  store float %79, ptr %80, align 4
  %81 = getelementptr inbounds ptr, ptr %59, i32 0, i32 0
  %82 = load float, ptr %81, align 4
  %83 = alloca float, align 4
  store float %82, ptr %83, align 4
  %84 = load ptr, ptr %59, align 8
  %85 = call float @lexer_advance_euclidean(ptr %84)
  %86 = alloca float, align 4
  store float %85, ptr %86, align 4
  %87 = load float, ptr %86, align 4
  %88 = fcmp oeq float %87, string:@.str.4
  %89 = uitofp i1 %88 to float
  %90 = fcmp one float %89, 0.0
  br i1 %90, label %then_23, label %end_25
then_23:
  %91 = fptoui float 0.0 to i64
  %92 = inttoptr i64 %91 to ptr
  ret ptr %92
unreachable_26:
  br label %end_25
end_25:
  %93 = load float, ptr %86, align 4
  %94 = fcmp oeq float %93, string:@.str.5
  %95 = uitofp i1 %94 to float
  %96 = fcmp one float %95, 0.0
  br i1 %96, label %then_27, label %end_29
then_27:
  %97 = fptoui float 0.0 to i64
  %98 = inttoptr i64 %97 to ptr
  ret ptr %98
unreachable_30:
  br label %end_29
end_29:
  %99 = load float, ptr %86, align 4
  %100 = fcmp oeq float %99, string:@.str.6
  %101 = uitofp i1 %100 to float
  %102 = fcmp one float %101, 0.0
  br i1 %102, label %then_31, label %end_33
then_31:
  %103 = fptoui float 0.0 to i64
  %104 = inttoptr i64 %103 to ptr
  ret ptr %104
unreachable_34:
  br label %end_33
end_33:
  %105 = load float, ptr %86, align 4
  %106 = fcmp oeq float %105, string:@.str.7
  %107 = uitofp i1 %106 to float
  %108 = fcmp one float %107, 0.0
  br i1 %108, label %then_35, label %end_37
then_35:
  %109 = fptoui float 0.0 to i64
  %110 = inttoptr i64 %109 to ptr
  ret ptr %110
unreachable_38:
  br label %end_37
end_37:
  %111 = load float, ptr %86, align 4
  %112 = fcmp oeq float %111, string:@.str.8
  %113 = uitofp i1 %112 to float
  %114 = fcmp one float %113, 0.0
  br i1 %114, label %then_39, label %end_41
then_39:
  %115 = fptoui float 0.0 to i64
  %116 = inttoptr i64 %115 to ptr
  ret ptr %116
unreachable_42:
  br label %end_41
end_41:
  %117 = load float, ptr %86, align 4
  %118 = fcmp oeq float %117, string:@.str.9
  %119 = uitofp i1 %118 to float
  %120 = fcmp one float %119, 0.0
  br i1 %120, label %then_43, label %end_45
then_43:
  %121 = fptoui float 0.0 to i64
  %122 = inttoptr i64 %121 to ptr
  ret ptr %122
unreachable_46:
  br label %end_45
end_45:
  %123 = load float, ptr %86, align 4
  %124 = fcmp oeq float %123, string:@.str.10
  %125 = uitofp i1 %124 to float
  %126 = fcmp one float %125, 0.0
  br i1 %126, label %then_47, label %end_49
then_47:
  %127 = fptoui float 0.0 to i64
  %128 = inttoptr i64 %127 to ptr
  ret ptr %128
unreachable_50:
  br label %end_49
end_49:
  %129 = load float, ptr %86, align 4
  %130 = fcmp oeq float %129, string:@.str.11
  %131 = uitofp i1 %130 to float
  %132 = fcmp one float %131, 0.0
  br i1 %132, label %then_51, label %end_53
then_51:
  %133 = fptoui float 0.0 to i64
  %134 = inttoptr i64 %133 to ptr
  ret ptr %134
unreachable_54:
  br label %end_53
end_53:
  %135 = load float, ptr %86, align 4
  %136 = call float @StructName_is_alpha(%StructName undef, float %135)
  %137 = fcmp one float %136, 0.0
  br i1 %137, label %then_55, label %end_57
then_55:
  %138 = load float, ptr %86, align 4
  %139 = alloca float, align 4
  store float %138, ptr %139, align 4
  br label %while_cond_58
while_cond_58:
  %140 = load ptr, ptr %59, align 8
  %141 = call float @lexer_peek_euclidean(ptr %140)
  %142 = call float @StructName_is_alphanumeric(%StructName undef, float %141)
  %143 = fcmp one float %142, 0.0
  br i1 %143, label %while_body_59, label %while_end_60
while_body_59:
  %144 = load float, ptr %139, align 4
  %145 = load ptr, ptr %59, align 8
  %146 = call float @lexer_advance_euclidean(ptr %145)
  %147 = fadd float %144, %146
  store float %147, ptr %139, align 4
  br label %while_cond_58
while_end_60:
  %148 = load float, ptr %139, align 4
  %149 = fcmp oeq float %148, string:@.str.13
  %150 = uitofp i1 %149 to float
  %151 = fcmp one float %150, 0.0
  br i1 %151, label %then_61, label %end_63
then_61:
  store float string:@.str.14, ptr @.str.12, align 4
  br label %end_63
end_63:
  %152 = load float, ptr %139, align 4
  %153 = fcmp oeq float %152, string:@.str.15
  %154 = uitofp i1 %153 to float
  %155 = fcmp one float %154, 0.0
  br i1 %155, label %then_64, label %end_66
then_64:
  store float string:@.str.16, ptr @.str.12, align 4
  br label %end_66
end_66:
  %156 = load float, ptr %139, align 4
  %157 = fcmp oeq float %156, string:@.str.17
  %158 = uitofp i1 %157 to float
  %159 = fcmp one float %158, 0.0
  br i1 %159, label %then_67, label %end_69
then_67:
  store float string:@.str.18, ptr @.str.12, align 4
  br label %end_69
end_69:
  %160 = load float, ptr %139, align 4
  %161 = fcmp oeq float %160, string:@.str.19
  %162 = uitofp i1 %161 to float
  %163 = fcmp one float %162, 0.0
  br i1 %163, label %then_70, label %end_72
then_70:
  store float string:@.str.20, ptr @.str.12, align 4
  br label %end_72
end_72:
  %164 = load float, ptr %139, align 4
  %165 = fcmp oeq float %164, string:@.str.21
  %166 = uitofp i1 %165 to float
  %167 = fcmp one float %166, 0.0
  br i1 %167, label %then_73, label %end_75
then_73:
  store float string:@.str.22, ptr @.str.12, align 4
  br label %end_75
end_75:
  %168 = load float, ptr %139, align 4
  %169 = fcmp oeq float %168, string:@.str.23
  %170 = uitofp i1 %169 to float
  %171 = fcmp one float %170, 0.0
  br i1 %171, label %then_76, label %end_78
then_76:
  store float string:@.str.24, ptr @.str.12, align 4
  br label %end_78
end_78:
  %172 = load float, ptr %139, align 4
  %173 = fcmp oeq float %172, string:@.str.25
  %174 = uitofp i1 %173 to float
  %175 = fcmp one float %174, 0.0
  br i1 %175, label %then_79, label %end_81
then_79:
  store float string:@.str.26, ptr @.str.12, align 4
  br label %end_81
end_81:
  %176 = load float, ptr %139, align 4
  %177 = fcmp oeq float %176, string:@.str.27
  %178 = uitofp i1 %177 to float
  %179 = fcmp one float %178, 0.0
  br i1 %179, label %then_82, label %end_84
then_82:
  store float string:@.str.28, ptr @.str.12, align 4
  br label %end_84
end_84:
  %180 = load float, ptr %139, align 4
  %181 = fcmp oeq float %180, string:@.str.29
  %182 = uitofp i1 %181 to float
  %183 = fcmp one float %182, 0.0
  br i1 %183, label %then_85, label %end_87
then_85:
  store float string:@.str.30, ptr @.str.12, align 4
  br label %end_87
end_87:
  %184 = load float, ptr %139, align 4
  %185 = fcmp oeq float %184, string:@.str.31
  %186 = uitofp i1 %185 to float
  %187 = fcmp one float %186, 0.0
  br i1 %187, label %then_88, label %end_90
then_88:
  store float string:@.str.32, ptr @.str.12, align 4
  br label %end_90
end_90:
  %188 = load float, ptr %139, align 4
  %189 = fcmp oeq float %188, string:@.str.33
  %190 = uitofp i1 %189 to float
  %191 = fcmp one float %190, 0.0
  br i1 %191, label %then_91, label %end_93
then_91:
  store float string:@.str.34, ptr @.str.12, align 4
  br label %end_93
end_93:
  %192 = load float, ptr %139, align 4
  %193 = fcmp oeq float %192, string:@.str.35
  %194 = uitofp i1 %193 to float
  %195 = fcmp one float %194, 0.0
  br i1 %195, label %then_94, label %end_96
then_94:
  store float string:@.str.36, ptr @.str.12, align 4
  br label %end_96
end_96:
  %196 = load float, ptr %139, align 4
  %197 = fcmp oeq float %196, string:@.str.37
  %198 = uitofp i1 %197 to float
  %199 = fcmp one float %198, 0.0
  br i1 %199, label %then_97, label %end_99
then_97:
  store float string:@.str.38, ptr @.str.12, align 4
  br label %end_99
end_99:
  %200 = load float, ptr %139, align 4
  %201 = fcmp oeq float %200, string:@.str.39
  %202 = uitofp i1 %201 to float
  %203 = fcmp one float %202, 0.0
  br i1 %203, label %then_100, label %end_102
then_100:
  store float string:@.str.40, ptr @.str.12, align 4
  br label %end_102
end_102:
  %204 = load float, ptr %139, align 4
  %205 = fcmp oeq float %204, string:@.str.41
  %206 = uitofp i1 %205 to float
  %207 = fcmp one float %206, 0.0
  br i1 %207, label %then_103, label %end_105
then_103:
  store float string:@.str.42, ptr @.str.12, align 4
  br label %end_105
end_105:
  %208 = load float, ptr %139, align 4
  %209 = fcmp oeq float %208, string:@.str.43
  %210 = uitofp i1 %209 to float
  %211 = fcmp one float %210, 0.0
  br i1 %211, label %then_106, label %end_108
then_106:
  store float string:@.str.44, ptr @.str.12, align 4
  br label %end_108
end_108:
  %212 = load float, ptr %139, align 4
  %213 = fcmp oeq float %212, string:@.str.45
  %214 = uitofp i1 %213 to float
  %215 = fcmp one float %214, 0.0
  br i1 %215, label %then_109, label %end_111
then_109:
  store float string:@.str.46, ptr @.str.12, align 4
  br label %end_111
end_111:
  %216 = fptoui float 0.0 to i64
  %217 = inttoptr i64 %216 to ptr
  ret ptr %217
unreachable_112:
  br label %end_57
end_57:
  %218 = fptoui float 0.0 to i64
  %219 = inttoptr i64 %218 to ptr
  ret ptr %219
unreachable_113:
  ret ptr null
}

define ptr @parser_init(ptr %arg_tokens_tree) {
entry:
  %220 = alloca ptr, align 4
  store ptr %arg_tokens_tree, ptr %220, align 4
  %221 = fptoui float 0.0 to i64
  %222 = inttoptr i64 %221 to ptr
  ret ptr %222
unreachable_114:
  ret ptr null
}

define ptr @parser_peek(ptr %arg_parser) {
entry:
  %223 = alloca ptr, align 4
  store ptr %arg_parser, ptr %223, align 4
  %224 = getelementptr inbounds ptr, ptr %223, i32 0, i32 0
  %225 = load float, ptr %224, align 4
  %226 = getelementptr inbounds ptr, ptr %223, i32 0, i32 0
  %227 = load float, ptr %226, align 4
  %228 = call float @StructName_tree_get(%StructName undef, float %225, float %227)
  %229 = fptoui float %228 to i64
  %230 = inttoptr i64 %229 to ptr
  ret ptr %230
unreachable_115:
  ret ptr null
}

define ptr @parser_advance(ptr %arg_parser) {
entry:
  %231 = alloca ptr, align 4
  store ptr %arg_parser, ptr %231, align 4
  %232 = load ptr, ptr %231, align 8
  %233 = call float @parser_peek_euclidean(ptr %232)
  %234 = alloca float, align 4
  store float %233, ptr %234, align 4
  %235 = getelementptr inbounds %StructName, ptr %234, i32 0, i32 0
  %236 = load float, ptr %235, align 4
  %237 = fcmp one float %236, string:@.str.47
  %238 = uitofp i1 %237 to float
  %239 = fcmp one float %238, 0.0
  br i1 %239, label %then_116, label %end_118
then_116:
  %240 = getelementptr inbounds ptr, ptr %231, i32 0, i32 0
  %241 = load float, ptr %240, align 4
  %242 = fadd float %241, 1
  %243 = getelementptr inbounds ptr, ptr %231, i32 0, i32 0
  store float %242, ptr %243, align 4
  br label %end_118
end_118:
  %244 = load float, ptr %234, align 4
  %245 = fptoui float %244 to i64
  %246 = inttoptr i64 %245 to ptr
  ret ptr %246
unreachable_119:
  ret ptr null
}

define ptr @parser_match(ptr %arg_parser, ptr %arg_expected_tag) {
entry:
  %247 = alloca ptr, align 4
  store ptr %arg_parser, ptr %247, align 4
  %248 = alloca ptr, align 4
  store ptr %arg_expected_tag, ptr %248, align 4
  %249 = load ptr, ptr %247, align 8
  %250 = call float @parser_peek_euclidean(ptr %249)
  %251 = alloca float, align 4
  store float %250, ptr %251, align 4
  %252 = getelementptr inbounds %StructName, ptr %251, i32 0, i32 0
  %253 = load float, ptr %252, align 4
  %254 = load ptr, ptr %248, align 8
  %255 = ptrtoint ptr %254 to i64
  %256 = sitofp i64 %255 to float
  %257 = fcmp oeq float %253, %256
  %258 = uitofp i1 %257 to float
  %259 = fcmp one float %258, 0.0
  br i1 %259, label %then_120, label %end_122
then_120:
  %260 = load ptr, ptr %247, align 8
  %261 = call float @parser_advance_euclidean(ptr %260)
  %262 = fptoui float 0.0 to i64
  %263 = inttoptr i64 %262 to ptr
  ret ptr %263
unreachable_123:
  br label %end_122
end_122:
  %264 = fptoui float 0.0 to i64
  %265 = inttoptr i64 %264 to ptr
  ret ptr %265
unreachable_124:
  ret ptr null
}

define ptr @parser_consume(ptr %arg_parser, ptr %arg_expected_tag, ptr %arg_error_msg) {
entry:
  %266 = alloca ptr, align 4
  store ptr %arg_parser, ptr %266, align 4
  %267 = alloca ptr, align 4
  store ptr %arg_expected_tag, ptr %267, align 4
  %268 = alloca ptr, align 4
  store ptr %arg_error_msg, ptr %268, align 4
  %269 = load ptr, ptr %266, align 8
  %270 = call ptr @parser_peek(ptr %269)
  %271 = getelementptr inbounds %StructName, ptr ptr:%270, i32 0, i32 0
  %272 = load float, ptr %271, align 4
  %273 = load ptr, ptr %267, align 8
  %274 = ptrtoint ptr %273 to i64
  %275 = sitofp i64 %274 to float
  %276 = fcmp oeq float %272, %275
  %277 = uitofp i1 %276 to float
  %278 = fcmp one float %277, 0.0
  br i1 %278, label %then_125, label %end_127
then_125:
  %279 = load ptr, ptr %266, align 8
  %280 = call float @parser_advance_euclidean(ptr %279)
  %281 = fptoui float %280 to i64
  %282 = inttoptr i64 %281 to ptr
  ret ptr %282
unreachable_128:
  br label %end_127
end_127:
  %283 = load ptr, ptr %268, align 8
  %284 = call float @StructName_panic(%StructName undef, ptr %283)
  %285 = load ptr, ptr %266, align 8
  %286 = call float @parser_peek_euclidean(ptr %285)
  %287 = fptoui float %286 to i64
  %288 = inttoptr i64 %287 to ptr
  ret ptr %288
unreachable_129:
  ret ptr null
}

define ptr @parse_block(ptr %arg_parser) {
entry:
  %289 = alloca ptr, align 4
  store ptr %arg_parser, ptr %289, align 4
  %290 = call float @StructName_tree_create(%StructName undef)
  %291 = alloca float, align 4
  store float %290, ptr %291, align 4
  %292 = load ptr, ptr %289, align 8
  %293 = call float @parser_consume_euclidean(ptr %292, ptr @.str.48, ptr @.str.49)
  br label %while_cond_130
while_cond_130:
  %294 = load ptr, ptr %289, align 8
  %295 = call ptr @parser_peek(ptr %294)
  %296 = getelementptr inbounds %StructName, ptr ptr:%295, i32 0, i32 0
  %297 = load float, ptr %296, align 4
  %298 = fcmp one float %297, string:@.str.50
  %299 = uitofp i1 %298 to float
  %300 = load ptr, ptr %289, align 8
  %301 = call ptr @parser_peek(ptr %300)
  %302 = getelementptr inbounds %StructName, ptr ptr:%301, i32 0, i32 0
  %303 = load float, ptr %302, align 4
  %304 = fcmp one float %303, string:@.str.51
  %305 = uitofp i1 %304 to float
  %306 = fcmp one float 0.0, 0.0
  br i1 %306, label %while_body_131, label %while_end_132
while_body_131:
  %307 = load ptr, ptr %289, align 8
  %308 = call float @parse_declaration_euclidean(ptr %307)
  %309 = alloca float, align 4
  store float %308, ptr %309, align 4
  %310 = load float, ptr %291, align 4
  %311 = load float, ptr %309, align 4
  %312 = call float @StructName_tree_push(%StructName undef, float %310, float %311)
  br label %while_cond_130
while_end_132:
  %313 = load ptr, ptr %289, align 8
  %314 = call float @parser_consume_euclidean(ptr %313, ptr @.str.52, ptr @.str.53)
  %315 = load float, ptr %291, align 4
  %316 = fptoui float %315 to i64
  %317 = inttoptr i64 %316 to ptr
  ret ptr %317
unreachable_133:
  ret ptr null
}

define ptr @parse_declaration(ptr %arg_parser) {
entry:
  %318 = alloca ptr, align 4
  store ptr %arg_parser, ptr %318, align 4
  %319 = alloca float, align 4
  store float 0.0, ptr %319, align 4
  %320 = alloca float, align 4
  store float 0.0, ptr %320, align 4
  %321 = alloca float, align 4
  store float 0.0, ptr %321, align 4
  %322 = load ptr, ptr %318, align 8
  %323 = call float @parser_match_euclidean(ptr %322, ptr @.str.54)
  %324 = fcmp one float %323, 0.0
  br i1 %324, label %then_134, label %end_136
then_134:
  store float 0.0, ptr %319, align 4
  br label %end_136
end_136:
  %325 = load ptr, ptr %318, align 8
  %326 = call float @parser_match_euclidean(ptr %325, ptr @.str.55)
  %327 = fcmp one float %326, 0.0
  br i1 %327, label %then_137, label %end_139
then_137:
  store float 0.0, ptr %320, align 4
  br label %end_139
end_139:
  %328 = load ptr, ptr %318, align 8
  %329 = call float @parser_match_euclidean(ptr %328, ptr @.str.56)
  %330 = fcmp one float %329, 0.0
  br i1 %330, label %then_140, label %end_142
then_140:
  store float 0.0, ptr %321, align 4
  br label %end_142
end_142:
  %331 = alloca float, align 4
  store float 0.0, ptr %331, align 4
  %332 = load ptr, ptr %318, align 8
  %333 = call float @parser_match_euclidean(ptr %332, ptr @.str.57)
  %334 = fcmp one float %333, 0.0
  br i1 %334, label %then_143, label %end_145
then_143:
  store float 0.0, ptr %331, align 4
  br label %end_145
end_145:
  %335 = load ptr, ptr %318, align 8
  %336 = call float @parser_match_euclidean(ptr %335, ptr @.str.58)
  %337 = fcmp one float %336, 0.0
  br i1 %337, label %then_146, label %end_148
then_146:
  %338 = load ptr, ptr %318, align 8
  %339 = call float @parse_function_decl_euclidean(ptr %338)
  %340 = alloca float, align 4
  store float %339, ptr %340, align 4
  %341 = load float, ptr %331, align 4
  %342 = getelementptr inbounds %StructName, ptr %340, i32 0, i32 0
  store float %341, ptr %342, align 4
  %343 = load float, ptr %340, align 4
  %344 = fptoui float %343 to i64
  %345 = inttoptr i64 %344 to ptr
  ret ptr %345
unreachable_149:
  br label %end_148
end_148:
  %346 = load ptr, ptr %318, align 8
  %347 = call float @parser_match_euclidean(ptr %346, ptr @.str.59)
  %348 = fcmp one float %347, 0.0
  br i1 %348, label %then_150, label %end_152
then_150:
  %349 = load ptr, ptr %318, align 8
  %350 = load float, ptr %319, align 4
  %351 = load float, ptr %320, align 4
  %352 = load float, ptr %321, align 4
  %353 = call float @parse_tensor_decl_euclidean(ptr %349, float %350, float %351, float %352)
  %354 = fptoui float %353 to i64
  %355 = inttoptr i64 %354 to ptr
  ret ptr %355
unreachable_153:
  br label %end_152
end_152:
  %356 = load ptr, ptr %318, align 8
  %357 = call float @parser_match_euclidean(ptr %356, ptr @.str.60)
  %358 = fcmp one float %357, 0.0
  br i1 %358, label %then_154, label %end_156
then_154:
  %359 = load ptr, ptr %318, align 8
  %360 = call float @parse_vmap_block_euclidean(ptr %359)
  %361 = fptoui float %360 to i64
  %362 = inttoptr i64 %361 to ptr
  ret ptr %362
unreachable_157:
  br label %end_156
end_156:
  %363 = load ptr, ptr %318, align 8
  %364 = call float @parser_match_euclidean(ptr %363, ptr @.str.61)
  %365 = fcmp one float %364, 0.0
  br i1 %365, label %then_158, label %end_160
then_158:
  %366 = load ptr, ptr %318, align 8
  %367 = call float @parse_multimodal_block_euclidean(ptr %366)
  %368 = fptoui float %367 to i64
  %369 = inttoptr i64 %368 to ptr
  ret ptr %369
unreachable_161:
  br label %end_160
end_160:
  %370 = load ptr, ptr %318, align 8
  %371 = call float @parser_match_euclidean(ptr %370, ptr @.str.62)
  %372 = fcmp one float %371, 0.0
  br i1 %372, label %then_162, label %end_164
then_162:
  %373 = load ptr, ptr %318, align 8
  %374 = call float @parse_vector_decl_euclidean(ptr %373)
  %375 = fptoui float %374 to i64
  %376 = inttoptr i64 %375 to ptr
  ret ptr %376
unreachable_165:
  br label %end_164
end_164:
  %377 = load ptr, ptr %318, align 8
  %378 = call float @parse_statement_euclidean(ptr %377)
  %379 = fptoui float %378 to i64
  %380 = inttoptr i64 %379 to ptr
  ret ptr %380
unreachable_166:
  ret ptr null
}

define ptr @parse_function_decl(ptr %arg_parser) {
entry:
  %381 = alloca ptr, align 4
  store ptr %arg_parser, ptr %381, align 4
  %382 = load ptr, ptr %381, align 8
  %383 = call float @parser_consume_euclidean(ptr %382, ptr @.str.63, ptr @.str.64)
  %384 = alloca float, align 4
  store float %383, ptr %384, align 4
  %385 = load ptr, ptr %381, align 8
  %386 = call float @parser_consume_euclidean(ptr %385, ptr @.str.65, ptr @.str.66)
  %387 = load ptr, ptr %381, align 8
  %388 = call float @parser_consume_euclidean(ptr %387, ptr @.str.67, ptr @.str.68)
  %389 = load ptr, ptr %381, align 8
  %390 = call float @parse_block_euclidean(ptr %389)
  %391 = alloca float, align 4
  store float %390, ptr %391, align 4
  %392 = fptoui float 0.0 to i64
  %393 = inttoptr i64 %392 to ptr
  ret ptr %393
unreachable_167:
  ret ptr null
}

define ptr @parse_tensor_decl(ptr %arg_parser, ptr %arg_is_lazy, ptr %arg_is_unified, ptr %arg_is_latent) {
entry:
  %394 = alloca ptr, align 4
  store ptr %arg_parser, ptr %394, align 4
  %395 = alloca ptr, align 4
  store ptr %arg_is_lazy, ptr %395, align 4
  %396 = alloca ptr, align 4
  store ptr %arg_is_unified, ptr %396, align 4
  %397 = alloca ptr, align 4
  store ptr %arg_is_latent, ptr %397, align 4
  %398 = load ptr, ptr %394, align 8
  %399 = call float @parser_consume_euclidean(ptr %398, ptr @.str.69, ptr @.str.70)
  %400 = alloca float, align 4
  store float %399, ptr %400, align 4
  %401 = load ptr, ptr %394, align 8
  %402 = call float @parser_consume_euclidean(ptr %401, ptr @.str.71, ptr @.str.72)
  %403 = fptoui float 0.0 to i64
  %404 = inttoptr i64 %403 to ptr
  ret ptr %404
unreachable_168:
  ret ptr null
}

define ptr @parse_vector_decl(ptr %arg_parser) {
entry:
  %405 = alloca ptr, align 4
  store ptr %arg_parser, ptr %405, align 4
  %406 = load ptr, ptr %405, align 8
  %407 = call float @parser_consume_euclidean(ptr %406, ptr @.str.73, ptr @.str.74)
  %408 = alloca float, align 4
  store float %407, ptr %408, align 4
  %409 = load ptr, ptr %405, align 8
  %410 = call float @parser_consume_euclidean(ptr %409, ptr @.str.75, ptr @.str.76)
  %411 = load ptr, ptr %405, align 8
  %412 = call float @parse_expr_euclidean(ptr %411)
  %413 = alloca float, align 4
  store float %412, ptr %413, align 4
  %414 = load ptr, ptr %405, align 8
  %415 = call float @parser_consume_euclidean(ptr %414, ptr @.str.77, ptr @.str.78)
  %416 = load ptr, ptr %405, align 8
  %417 = call ptr @parser_peek(ptr %416)
  %418 = getelementptr inbounds %StructName, ptr ptr:%417, i32 0, i32 0
  %419 = load float, ptr %418, align 4
  %420 = fcmp oeq float %419, string:@.str.79
  %421 = uitofp i1 %420 to float
  %422 = fcmp one float %421, 0.0
  br i1 %422, label %then_169, label %end_171
then_169:
  %423 = load ptr, ptr %405, align 8
  %424 = call float @parser_advance_euclidean(ptr %423)
  %425 = load ptr, ptr %405, align 8
  %426 = call float @parser_consume_euclidean(ptr %425, ptr @.str.80, ptr @.str.81)
  br label %end_171
end_171:
  %427 = load ptr, ptr %405, align 8
  %428 = call float @parser_consume_euclidean(ptr %427, ptr @.str.82, ptr @.str.83)
  %429 = fptoui float 0.0 to i64
  %430 = inttoptr i64 %429 to ptr
  ret ptr %430
unreachable_172:
  ret ptr null
}

define ptr @parse_multimodal_block(ptr %arg_parser) {
entry:
  %431 = alloca ptr, align 4
  store ptr %arg_parser, ptr %431, align 4
  %432 = load ptr, ptr %431, align 8
  %433 = call float @parser_consume_euclidean(ptr %432, ptr @.str.84, ptr @.str.85)
  %434 = alloca float, align 4
  store float %433, ptr %434, align 4
  %435 = load ptr, ptr %431, align 8
  %436 = call float @parse_block_euclidean(ptr %435)
  %437 = alloca float, align 4
  store float %436, ptr %437, align 4
  %438 = fptoui float 0.0 to i64
  %439 = inttoptr i64 %438 to ptr
  ret ptr %439
unreachable_173:
  ret ptr null
}

define ptr @parse_vmap_block(ptr %arg_parser) {
entry:
  %440 = alloca ptr, align 4
  store ptr %arg_parser, ptr %440, align 4
  %441 = load ptr, ptr %440, align 8
  %442 = call float @parse_block_euclidean(ptr %441)
  %443 = alloca float, align 4
  store float %442, ptr %443, align 4
  %444 = fptoui float 0.0 to i64
  %445 = inttoptr i64 %444 to ptr
  ret ptr %445
unreachable_174:
  ret ptr null
}

define ptr @parse_statement(ptr %arg_parser) {
entry:
  %446 = alloca ptr, align 4
  store ptr %arg_parser, ptr %446, align 4
  %447 = call float @StructName_tree_create(%StructName undef)
  %448 = alloca float, align 4
  store float %447, ptr %448, align 4
  %449 = alloca float, align 4
  store float 0.0, ptr %449, align 4
  %450 = fptoui float 0.0 to i64
  %451 = inttoptr i64 %450 to ptr
  ret ptr %451
unreachable_175:
  ret ptr null
}

define ptr @optimize_expr(ptr %arg_expr) {
entry:
  %452 = alloca ptr, align 4
  store ptr %arg_expr, ptr %452, align 4
  %453 = alloca float, align 4
  store float 0, ptr %453, align 4
  br label %while_cond_176
while_cond_176:
  %454 = load float, ptr %453, align 4
  %455 = getelementptr inbounds ptr, ptr %452, i32 0, i32 0
  %456 = load float, ptr %455, align 4
  %457 = call float @StructName_tree_size(%StructName undef, float %456)
  %458 = fcmp olt float %454, %457
  %459 = uitofp i1 %458 to float
  %460 = fcmp one float %459, 0.0
  br i1 %460, label %while_body_177, label %while_end_178
while_body_177:
  %461 = getelementptr inbounds ptr, ptr %452, i32 0, i32 0
  %462 = load float, ptr %461, align 4
  %463 = load float, ptr %453, align 4
  %464 = call float @StructName_tree_get(%StructName undef, float %462, float %463)
  %465 = alloca float, align 4
  store float %464, ptr %465, align 4
  %466 = load float, ptr %465, align 4
  %467 = call ptr @optimize_expr(float %466)
  %468 = alloca ptr, align 8
  store ptr %467, ptr %468, align 8
  %469 = getelementptr inbounds ptr, ptr %452, i32 0, i32 0
  %470 = load float, ptr %469, align 4
  %471 = load float, ptr %453, align 4
  %472 = load ptr, ptr %468, align 8
  %473 = call float @StructName_tree_set(%StructName undef, float %470, float %471, ptr %472)
  ; --- Begin Fused Kernel ---
  %474 = load float, ptr %453, align 4
  %475 = fadd float %474, 1
  ; --- End Fused Kernel ---
  store float %475, ptr %453, align 4
  br label %while_cond_176
while_end_178:
  %476 = getelementptr inbounds ptr, ptr %452, i32 0, i32 0
  %477 = load float, ptr %476, align 4
  %478 = fcmp oeq float %477, string:@.str.86
  %479 = uitofp i1 %478 to float
  %480 = fcmp one float %479, 0.0
  br i1 %480, label %then_179, label %end_181
then_179:
  %481 = getelementptr inbounds ptr, ptr %452, i32 0, i32 0
  %482 = load float, ptr %481, align 4
  %483 = call float @StructName_tree_get(%StructName undef, float %482, float 0)
  %484 = alloca float, align 4
  store float %483, ptr %484, align 4
  %485 = getelementptr inbounds %StructName, ptr %484, i32 0, i32 0
  %486 = load float, ptr %485, align 4
  %487 = fcmp oeq float %486, string:@.str.87
  %488 = uitofp i1 %487 to float
  %489 = fcmp one float %488, 0.0
  br i1 %489, label %then_182, label %end_184
then_182:
  %490 = getelementptr inbounds %StructName, ptr %484, i32 0, i32 0
  %491 = load float, ptr %490, align 4
  %492 = call float @StructName_tree_get(%StructName undef, float %491, float 0)
  %493 = alloca float, align 4
  store float %492, ptr %493, align 4
  %494 = load float, ptr %493, align 4
  %495 = fptoui float %494 to i64
  %496 = inttoptr i64 %495 to ptr
  ret ptr %496
unreachable_185:
  br label %end_184
end_184:
  br label %end_181
end_181:
  %497 = load ptr, ptr %452, align 8
  ret ptr %497
unreachable_186:
  ret ptr null
}

define ptr @optimize_stmt(ptr %arg_stmt) {
entry:
  %498 = alloca ptr, align 4
  store ptr %arg_stmt, ptr %498, align 4
  %499 = getelementptr inbounds ptr, ptr %498, i32 0, i32 0
  %500 = load float, ptr %499, align 4
  %501 = getelementptr inbounds %StructName, ptr %500, i32 0, i32 0
  %502 = load float, ptr %501, align 4
  %503 = fcmp one float %502, string:@.str.88
  %504 = uitofp i1 %503 to float
  %505 = fcmp one float %504, 0.0
  br i1 %505, label %then_187, label %end_189
then_187:
  %506 = getelementptr inbounds ptr, ptr %498, i32 0, i32 0
  %507 = load float, ptr %506, align 4
  %508 = call ptr @optimize_expr(float %507)
  %509 = getelementptr inbounds ptr, ptr %498, i32 0, i32 0
  store float ptr:%508, ptr %509, align 4
  br label %end_189
end_189:
  %510 = alloca float, align 4
  store float 0, ptr %510, align 4
  br label %while_cond_190
while_cond_190:
  %511 = load float, ptr %510, align 4
  %512 = getelementptr inbounds ptr, ptr %498, i32 0, i32 0
  %513 = load float, ptr %512, align 4
  %514 = call float @StructName_tree_size(%StructName undef, float %513)
  %515 = fcmp olt float %511, %514
  %516 = uitofp i1 %515 to float
  %517 = fcmp one float %516, 0.0
  br i1 %517, label %while_body_191, label %while_end_192
while_body_191:
  %518 = getelementptr inbounds ptr, ptr %498, i32 0, i32 0
  %519 = load float, ptr %518, align 4
  %520 = load float, ptr %510, align 4
  %521 = call float @StructName_tree_get(%StructName undef, float %519, float %520)
  %522 = alloca float, align 4
  store float %521, ptr %522, align 4
  %523 = load float, ptr %522, align 4
  %524 = call ptr @optimize_stmt(float %523)
  %525 = alloca ptr, align 8
  store ptr %524, ptr %525, align 8
  %526 = getelementptr inbounds ptr, ptr %498, i32 0, i32 0
  %527 = load float, ptr %526, align 4
  %528 = load float, ptr %510, align 4
  %529 = load ptr, ptr %525, align 8
  %530 = call float @StructName_tree_set(%StructName undef, float %527, float %528, ptr %529)
  ; --- Begin Fused Kernel ---
  %531 = load float, ptr %510, align 4
  %532 = fadd float %531, 1
  ; --- End Fused Kernel ---
  store float %532, ptr %510, align 4
  br label %while_cond_190
while_end_192:
  %533 = load ptr, ptr %498, align 8
  ret ptr %533
unreachable_193:
  ret ptr null
}

define ptr @optimize_program(ptr %arg_program) {
entry:
  %534 = alloca ptr, align 4
  store ptr %arg_program, ptr %534, align 4
  %535 = alloca float, align 4
  store float 0, ptr %535, align 4
  br label %while_cond_194
while_cond_194:
  %536 = load float, ptr %535, align 4
  %537 = getelementptr inbounds ptr, ptr %534, i32 0, i32 0
  %538 = load float, ptr %537, align 4
  %539 = call float @StructName_tree_size(%StructName undef, float %538)
  %540 = fcmp olt float %536, %539
  %541 = uitofp i1 %540 to float
  %542 = fcmp one float %541, 0.0
  br i1 %542, label %while_body_195, label %while_end_196
while_body_195:
  %543 = getelementptr inbounds ptr, ptr %534, i32 0, i32 0
  %544 = load float, ptr %543, align 4
  %545 = load float, ptr %535, align 4
  %546 = call float @StructName_tree_get(%StructName undef, float %544, float %545)
  %547 = alloca float, align 4
  store float %546, ptr %547, align 4
  %548 = load float, ptr %547, align 4
  %549 = call ptr @optimize_stmt(float %548)
  %550 = alloca ptr, align 8
  store ptr %549, ptr %550, align 8
  %551 = getelementptr inbounds ptr, ptr %534, i32 0, i32 0
  %552 = load float, ptr %551, align 4
  %553 = load float, ptr %535, align 4
  %554 = load ptr, ptr %550, align 8
  %555 = call float @StructName_tree_set(%StructName undef, float %552, float %553, ptr %554)
  ; --- Begin Fused Kernel ---
  %556 = load float, ptr %535, align 4
  %557 = fadd float %556, 1
  ; --- End Fused Kernel ---
  store float %557, ptr %535, align 4
  br label %while_cond_194
while_end_196:
  %558 = load ptr, ptr %534, align 8
  ret ptr %558
unreachable_197:
  ret ptr null
}

define ptr @expand_macros_expr(ptr %arg_expr) {
entry:
  %559 = alloca ptr, align 4
  store ptr %arg_expr, ptr %559, align 4
  %560 = alloca float, align 4
  store float 0, ptr %560, align 4
  br label %while_cond_198
while_cond_198:
  %561 = load float, ptr %560, align 4
  %562 = getelementptr inbounds ptr, ptr %559, i32 0, i32 0
  %563 = load float, ptr %562, align 4
  %564 = call float @StructName_tree_size(%StructName undef, float %563)
  %565 = fcmp olt float %561, %564
  %566 = uitofp i1 %565 to float
  %567 = fcmp one float %566, 0.0
  br i1 %567, label %while_body_199, label %while_end_200
while_body_199:
  %568 = getelementptr inbounds ptr, ptr %559, i32 0, i32 0
  %569 = load float, ptr %568, align 4
  %570 = load float, ptr %560, align 4
  %571 = call float @StructName_tree_get(%StructName undef, float %569, float %570)
  %572 = alloca float, align 4
  store float %571, ptr %572, align 4
  %573 = load float, ptr %572, align 4
  %574 = call ptr @expand_macros_expr(float %573)
  %575 = alloca ptr, align 8
  store ptr %574, ptr %575, align 8
  %576 = getelementptr inbounds ptr, ptr %559, i32 0, i32 0
  %577 = load float, ptr %576, align 4
  %578 = load float, ptr %560, align 4
  %579 = load ptr, ptr %575, align 8
  %580 = call float @StructName_tree_set(%StructName undef, float %577, float %578, ptr %579)
  ; --- Begin Fused Kernel ---
  %581 = load float, ptr %560, align 4
  %582 = fadd float %581, 1
  ; --- End Fused Kernel ---
  store float %582, ptr %560, align 4
  br label %while_cond_198
while_end_200:
  %583 = load ptr, ptr %559, align 8
  ret ptr %583
unreachable_201:
  ret ptr null
}

define ptr @expand_macros_stmt(ptr %arg_stmt) {
entry:
  %584 = alloca ptr, align 4
  store ptr %arg_stmt, ptr %584, align 4
  %585 = getelementptr inbounds ptr, ptr %584, i32 0, i32 0
  %586 = load float, ptr %585, align 4
  %587 = getelementptr inbounds %StructName, ptr %586, i32 0, i32 0
  %588 = load float, ptr %587, align 4
  %589 = fcmp one float %588, string:@.str.89
  %590 = uitofp i1 %589 to float
  %591 = fcmp one float %590, 0.0
  br i1 %591, label %then_202, label %end_204
then_202:
  %592 = getelementptr inbounds ptr, ptr %584, i32 0, i32 0
  %593 = load float, ptr %592, align 4
  %594 = call ptr @expand_macros_expr(float %593)
  %595 = getelementptr inbounds ptr, ptr %584, i32 0, i32 0
  store float ptr:%594, ptr %595, align 4
  br label %end_204
end_204:
  %596 = alloca float, align 4
  store float 0, ptr %596, align 4
  br label %while_cond_205
while_cond_205:
  %597 = load float, ptr %596, align 4
  %598 = getelementptr inbounds ptr, ptr %584, i32 0, i32 0
  %599 = load float, ptr %598, align 4
  %600 = call float @StructName_tree_size(%StructName undef, float %599)
  %601 = fcmp olt float %597, %600
  %602 = uitofp i1 %601 to float
  %603 = fcmp one float %602, 0.0
  br i1 %603, label %while_body_206, label %while_end_207
while_body_206:
  %604 = getelementptr inbounds ptr, ptr %584, i32 0, i32 0
  %605 = load float, ptr %604, align 4
  %606 = load float, ptr %596, align 4
  %607 = call float @StructName_tree_get(%StructName undef, float %605, float %606)
  %608 = alloca float, align 4
  store float %607, ptr %608, align 4
  %609 = load float, ptr %608, align 4
  %610 = call ptr @expand_macros_stmt(float %609)
  %611 = alloca ptr, align 8
  store ptr %610, ptr %611, align 8
  %612 = getelementptr inbounds ptr, ptr %584, i32 0, i32 0
  %613 = load float, ptr %612, align 4
  %614 = load float, ptr %596, align 4
  %615 = load ptr, ptr %611, align 8
  %616 = call float @StructName_tree_set(%StructName undef, float %613, float %614, ptr %615)
  ; --- Begin Fused Kernel ---
  %617 = load float, ptr %596, align 4
  %618 = fadd float %617, 1
  ; --- End Fused Kernel ---
  store float %618, ptr %596, align 4
  br label %while_cond_205
while_end_207:
  %619 = load ptr, ptr %584, align 8
  ret ptr %619
unreachable_208:
  ret ptr null
}

define ptr @expand_macros_program(ptr %arg_program) {
entry:
  %620 = alloca ptr, align 4
  store ptr %arg_program, ptr %620, align 4
  %621 = alloca float, align 4
  store float 0, ptr %621, align 4
  br label %while_cond_209
while_cond_209:
  %622 = load float, ptr %621, align 4
  %623 = getelementptr inbounds ptr, ptr %620, i32 0, i32 0
  %624 = load float, ptr %623, align 4
  %625 = call float @StructName_tree_size(%StructName undef, float %624)
  %626 = fcmp olt float %622, %625
  %627 = uitofp i1 %626 to float
  %628 = fcmp one float %627, 0.0
  br i1 %628, label %while_body_210, label %while_end_211
while_body_210:
  %629 = getelementptr inbounds ptr, ptr %620, i32 0, i32 0
  %630 = load float, ptr %629, align 4
  %631 = load float, ptr %621, align 4
  %632 = call float @StructName_tree_get(%StructName undef, float %630, float %631)
  %633 = alloca float, align 4
  store float %632, ptr %633, align 4
  %634 = load float, ptr %633, align 4
  %635 = call ptr @expand_macros_stmt(float %634)
  %636 = alloca ptr, align 8
  store ptr %635, ptr %636, align 8
  %637 = getelementptr inbounds ptr, ptr %620, i32 0, i32 0
  %638 = load float, ptr %637, align 4
  %639 = load float, ptr %621, align 4
  %640 = load ptr, ptr %636, align 8
  %641 = call float @StructName_tree_set(%StructName undef, float %638, float %639, ptr %640)
  ; --- Begin Fused Kernel ---
  %642 = load float, ptr %621, align 4
  %643 = fadd float %642, 1
  ; --- End Fused Kernel ---
  store float %643, ptr %621, align 4
  br label %while_cond_209
while_end_211:
  %644 = load ptr, ptr %620, align 8
  ret ptr %644
unreachable_212:
  ret ptr null
}

define ptr @check_expr(ptr %arg_expr, ptr %arg_scope) {
entry:
  %645 = alloca ptr, align 4
  store ptr %arg_expr, ptr %645, align 4
  %646 = alloca ptr, align 4
  store ptr %arg_scope, ptr %646, align 4
  %647 = fptoui float string:@.str.90 to i64
  %648 = inttoptr i64 %647 to ptr
  ret ptr %648
unreachable_213:
  ret ptr null
}

define ptr @typecheck_stmt(ptr %arg_stmt, ptr %arg_scope) {
entry:
  %649 = alloca ptr, align 4
  store ptr %arg_stmt, ptr %649, align 4
  %650 = alloca ptr, align 4
  store ptr %arg_scope, ptr %650, align 4
  %651 = alloca float, align 4
  store float 0, ptr %651, align 4
  br label %while_cond_214
while_cond_214:
  %652 = load float, ptr %651, align 4
  %653 = getelementptr inbounds ptr, ptr %649, i32 0, i32 0
  %654 = load float, ptr %653, align 4
  %655 = call float @StructName_tree_size(%StructName undef, float %654)
  %656 = fcmp olt float %652, %655
  %657 = uitofp i1 %656 to float
  %658 = fcmp one float %657, 0.0
  br i1 %658, label %while_body_215, label %while_end_216
while_body_215:
  %659 = getelementptr inbounds ptr, ptr %649, i32 0, i32 0
  %660 = load float, ptr %659, align 4
  %661 = load float, ptr %651, align 4
  %662 = call float @StructName_tree_get(%StructName undef, float %660, float %661)
  %663 = alloca float, align 4
  store float %662, ptr %663, align 4
  %664 = load float, ptr %663, align 4
  %665 = load ptr, ptr %650, align 8
  %666 = call float @typecheck_stmt_euclidean(float %664, ptr %665)
  %667 = alloca float, align 4
  store float %666, ptr %667, align 4
  %668 = getelementptr inbounds ptr, ptr %649, i32 0, i32 0
  %669 = load float, ptr %668, align 4
  %670 = load float, ptr %651, align 4
  %671 = load float, ptr %667, align 4
  %672 = call float @StructName_tree_set(%StructName undef, float %669, float %670, float %671)
  ; --- Begin Fused Kernel ---
  %673 = load float, ptr %651, align 4
  %674 = fadd float %673, 1
  ; --- End Fused Kernel ---
  store float %674, ptr %651, align 4
  br label %while_cond_214
while_end_216:
  %675 = load ptr, ptr %649, align 8
  ret ptr %675
unreachable_217:
  ret ptr null
}

define ptr @typecheck_program(ptr %arg_program) {
entry:
  %676 = alloca ptr, align 4
  store ptr %arg_program, ptr %676, align 4
  %677 = call float @StructName_tree_create(%StructName undef)
  %678 = alloca float, align 4
  store float %677, ptr %678, align 4
  %679 = alloca float, align 4
  store float 0, ptr %679, align 4
  br label %while_cond_218
while_cond_218:
  %680 = load float, ptr %679, align 4
  %681 = getelementptr inbounds ptr, ptr %676, i32 0, i32 0
  %682 = load float, ptr %681, align 4
  %683 = call float @StructName_tree_size(%StructName undef, float %682)
  %684 = fcmp olt float %680, %683
  %685 = uitofp i1 %684 to float
  %686 = fcmp one float %685, 0.0
  br i1 %686, label %while_body_219, label %while_end_220
while_body_219:
  %687 = getelementptr inbounds ptr, ptr %676, i32 0, i32 0
  %688 = load float, ptr %687, align 4
  %689 = load float, ptr %679, align 4
  %690 = call float @StructName_tree_get(%StructName undef, float %688, float %689)
  %691 = alloca float, align 4
  store float %690, ptr %691, align 4
  %692 = load float, ptr %691, align 4
  %693 = load float, ptr %678, align 4
  %694 = call ptr @typecheck_stmt(float %692, float %693)
  %695 = alloca ptr, align 8
  store ptr %694, ptr %695, align 8
  %696 = getelementptr inbounds ptr, ptr %676, i32 0, i32 0
  %697 = load float, ptr %696, align 4
  %698 = load float, ptr %679, align 4
  %699 = load ptr, ptr %695, align 8
  %700 = call float @StructName_tree_set(%StructName undef, float %697, float %698, ptr %699)
  ; --- Begin Fused Kernel ---
  %701 = load float, ptr %679, align 4
  %702 = fadd float %701, 1
  ; --- End Fused Kernel ---
  store float %702, ptr %679, align 4
  br label %while_cond_218
while_end_220:
  %703 = load ptr, ptr %676, align 8
  ret ptr %703
unreachable_221:
  ret ptr null
}

define ptr @llvm_init() {
entry:
  %704 = fptoui float 0.0 to i64
  %705 = inttoptr i64 %704 to ptr
  ret ptr %705
unreachable_222:
  ret ptr null
}

define ptr @llvm_next_reg(ptr %arg_gen) {
entry:
  %706 = alloca ptr, align 4
  store ptr %arg_gen, ptr %706, align 4
  %707 = getelementptr inbounds ptr, ptr %706, i32 0, i32 0
  %708 = load float, ptr %707, align 4
  %709 = alloca float, align 4
  store float %708, ptr %709, align 4
  %710 = getelementptr inbounds ptr, ptr %706, i32 0, i32 0
  %711 = load float, ptr %710, align 4
  %712 = fadd float %711, 1
  %713 = getelementptr inbounds ptr, ptr %706, i32 0, i32 0
  store float %712, ptr %713, align 4
  %714 = load float, ptr %709, align 4
  %715 = call float @StructName_int_to_string(%StructName undef, float %714)
  %716 = fadd float string:@.str.91, %715
  %717 = fptoui float %716 to i64
  %718 = inttoptr i64 %717 to ptr
  ret ptr %718
unreachable_223:
  ret ptr null
}

define ptr @generate_expr(ptr %arg_gen, ptr %arg_expr) {
entry:
  %719 = alloca ptr, align 4
  store ptr %arg_gen, ptr %719, align 4
  %720 = alloca ptr, align 4
  store ptr %arg_expr, ptr %720, align 4
  %721 = getelementptr inbounds ptr, ptr %720, i32 0, i32 0
  %722 = load float, ptr %721, align 4
  %723 = fcmp oeq float %722, string:@.str.92
  %724 = uitofp i1 %723 to float
  %725 = fcmp one float %724, 0.0
  br i1 %725, label %then_224, label %end_226
then_224:
  %726 = getelementptr inbounds ptr, ptr %720, i32 0, i32 0
  %727 = load float, ptr %726, align 4
  %728 = call float @StructName_int_to_string(%StructName undef, float %727)
  %729 = fptoui float %728 to i64
  %730 = inttoptr i64 %729 to ptr
  ret ptr %730
unreachable_227:
  br label %end_226
end_226:
  %731 = getelementptr inbounds ptr, ptr %720, i32 0, i32 0
  %732 = load float, ptr %731, align 4
  %733 = fcmp oeq float %732, string:@.str.93
  %734 = uitofp i1 %733 to float
  %735 = fcmp one float %734, 0.0
  br i1 %735, label %then_228, label %end_230
then_228:
  %736 = getelementptr inbounds ptr, ptr %720, i32 0, i32 0
  %737 = load float, ptr %736, align 4
  %738 = call float @StructName_float_to_string(%StructName undef, float %737)
  %739 = fptoui float %738 to i64
  %740 = inttoptr i64 %739 to ptr
  ret ptr %740
unreachable_231:
  br label %end_230
end_230:
  %741 = getelementptr inbounds ptr, ptr %720, i32 0, i32 0
  %742 = load float, ptr %741, align 4
  %743 = fcmp oeq float %742, string:@.str.94
  %744 = uitofp i1 %743 to float
  %745 = fcmp one float %744, 0.0
  br i1 %745, label %then_232, label %end_234
then_232:
  %746 = getelementptr inbounds ptr, ptr %720, i32 0, i32 0
  %747 = load float, ptr %746, align 4
  %748 = fadd float string:@.str.95, %747
  %749 = fptoui float %748 to i64
  %750 = inttoptr i64 %749 to ptr
  ret ptr %750
unreachable_235:
  br label %end_234
end_234:
  %751 = getelementptr inbounds ptr, ptr %720, i32 0, i32 0
  %752 = load float, ptr %751, align 4
  %753 = fcmp oeq float %752, string:@.str.96
  %754 = uitofp i1 %753 to float
  %755 = fcmp one float %754, 0.0
  br i1 %755, label %then_236, label %end_238
then_236:
  %756 = load ptr, ptr %719, align 8
  %757 = getelementptr inbounds ptr, ptr %720, i32 0, i32 0
  %758 = load float, ptr %757, align 4
  %759 = call float @StructName_tree_get(%StructName undef, float %758, float 0)
  %760 = call float @generate_expr_euclidean(ptr %756, float %759)
  %761 = alloca float, align 4
  store float %760, ptr %761, align 4
  %762 = load ptr, ptr %719, align 8
  %763 = getelementptr inbounds ptr, ptr %720, i32 0, i32 0
  %764 = load float, ptr %763, align 4
  %765 = call float @StructName_tree_get(%StructName undef, float %764, float 1)
  %766 = call float @generate_expr_euclidean(ptr %762, float %765)
  %767 = alloca float, align 4
  store float %766, ptr %767, align 4
  %768 = load ptr, ptr %719, align 8
  %769 = call float @llvm_next_reg_euclidean(ptr %768)
  %770 = alloca float, align 4
  store float %769, ptr %770, align 4
  %771 = getelementptr inbounds ptr, ptr %719, i32 0, i32 0
  %772 = load float, ptr %771, align 4
  %773 = fadd float %772, string:@.str.97
  %774 = load float, ptr %770, align 4
  %775 = fadd float %773, %774
  %776 = fadd float %775, string:@.str.98
  %777 = load float, ptr %761, align 4
  %778 = fadd float %776, %777
  %779 = fadd float %778, string:@.str.99
  %780 = load float, ptr %767, align 4
  %781 = fadd float %779, %780
  %782 = fadd float %781, string:@.str.100
  %783 = getelementptr inbounds ptr, ptr %719, i32 0, i32 0
  store float %782, ptr %783, align 4
  %784 = load float, ptr %770, align 4
  %785 = fptoui float %784 to i64
  %786 = inttoptr i64 %785 to ptr
  ret ptr %786
unreachable_239:
  br label %end_238
end_238:
  %787 = fptoui float string:@.str.101 to i64
  %788 = inttoptr i64 %787 to ptr
  ret ptr %788
unreachable_240:
  ret ptr null
}

define void @generate_stmt(ptr %arg_gen, ptr %arg_stmt) {
entry:
  %789 = alloca ptr, align 4
  store ptr %arg_gen, ptr %789, align 4
  %790 = alloca ptr, align 4
  store ptr %arg_stmt, ptr %790, align 4
  %791 = getelementptr inbounds ptr, ptr %790, i32 0, i32 0
  %792 = load float, ptr %791, align 4
  %793 = fcmp oeq float %792, string:@.str.102
  %794 = uitofp i1 %793 to float
  %795 = fcmp one float %794, 0.0
  br i1 %795, label %then_241, label %else_242
then_241:
  %796 = load ptr, ptr %789, align 8
  %797 = call float @llvm_next_reg_euclidean(ptr %796)
  %798 = alloca float, align 4
  store float %797, ptr %798, align 4
  %799 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  %800 = load float, ptr %799, align 4
  %801 = fadd float %800, string:@.str.103
  %802 = load float, ptr %798, align 4
  %803 = fadd float %801, %802
  %804 = fadd float %803, string:@.str.104
  %805 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  store float %804, ptr %805, align 4
  br label %end_243
else_242:
  %806 = getelementptr inbounds ptr, ptr %790, i32 0, i32 0
  %807 = load float, ptr %806, align 4
  %808 = fcmp oeq float %807, string:@.str.105
  %809 = uitofp i1 %808 to float
  %810 = fcmp one float %809, 0.0
  br i1 %810, label %then_244, label %else_245
then_244:
  %811 = load ptr, ptr %789, align 8
  %812 = call float @llvm_next_reg_euclidean(ptr %811)
  %813 = alloca float, align 4
  store float %812, ptr %813, align 4
  %814 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  %815 = load float, ptr %814, align 4
  %816 = fadd float %815, string:@.str.106
  %817 = load float, ptr %813, align 4
  %818 = fadd float %816, %817
  %819 = fadd float %818, string:@.str.107
  %820 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  store float %819, ptr %820, align 4
  br label %end_246
else_245:
  %821 = getelementptr inbounds ptr, ptr %790, i32 0, i32 0
  %822 = load float, ptr %821, align 4
  %823 = fcmp oeq float %822, string:@.str.108
  %824 = uitofp i1 %823 to float
  %825 = fcmp one float %824, 0.0
  br i1 %825, label %then_247, label %else_248
then_247:
  %826 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  %827 = load float, ptr %826, align 4
  %828 = fadd float %827, string:@.str.109
  %829 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  store float %828, ptr %829, align 4
  %830 = alloca float, align 4
  store float 0, ptr %830, align 4
  br label %while_cond_250
while_cond_250:
  %831 = load float, ptr %830, align 4
  %832 = getelementptr inbounds ptr, ptr %790, i32 0, i32 0
  %833 = load float, ptr %832, align 4
  %834 = call float @StructName_tree_size(%StructName undef, float %833)
  %835 = fcmp olt float %831, %834
  %836 = uitofp i1 %835 to float
  %837 = fcmp one float %836, 0.0
  br i1 %837, label %while_body_251, label %while_end_252
while_body_251:
  %838 = getelementptr inbounds ptr, ptr %790, i32 0, i32 0
  %839 = load float, ptr %838, align 4
  %840 = load float, ptr %830, align 4
  %841 = call float @StructName_tree_get(%StructName undef, float %839, float %840)
  %842 = alloca float, align 4
  store float %841, ptr %842, align 4
  %843 = load ptr, ptr %789, align 8
  %844 = load float, ptr %842, align 4
  %845 = call float @generate_stmt_euclidean(ptr %843, float %844)
  ; --- Begin Fused Kernel ---
  %846 = load float, ptr %830, align 4
  %847 = fadd float %846, 1
  ; --- End Fused Kernel ---
  store float %847, ptr %830, align 4
  br label %while_cond_250
while_end_252:
  %848 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  %849 = load float, ptr %848, align 4
  %850 = fadd float %849, string:@.str.110
  %851 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  store float %850, ptr %851, align 4
  br label %end_249
else_248:
  %852 = getelementptr inbounds ptr, ptr %790, i32 0, i32 0
  %853 = load float, ptr %852, align 4
  %854 = fcmp oeq float %853, string:@.str.111
  %855 = uitofp i1 %854 to float
  %856 = fcmp one float %855, 0.0
  br i1 %856, label %then_253, label %else_254
then_253:
  %857 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  %858 = load float, ptr %857, align 4
  %859 = fadd float %858, string:@.str.112
  %860 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  store float %859, ptr %860, align 4
  %861 = alloca float, align 4
  store float 0, ptr %861, align 4
  br label %while_cond_256
while_cond_256:
  %862 = load float, ptr %861, align 4
  %863 = getelementptr inbounds ptr, ptr %790, i32 0, i32 0
  %864 = load float, ptr %863, align 4
  %865 = call float @StructName_tree_size(%StructName undef, float %864)
  %866 = fcmp olt float %862, %865
  %867 = uitofp i1 %866 to float
  %868 = fcmp one float %867, 0.0
  br i1 %868, label %while_body_257, label %while_end_258
while_body_257:
  %869 = getelementptr inbounds ptr, ptr %790, i32 0, i32 0
  %870 = load float, ptr %869, align 4
  %871 = load float, ptr %861, align 4
  %872 = call float @StructName_tree_get(%StructName undef, float %870, float %871)
  %873 = alloca float, align 4
  store float %872, ptr %873, align 4
  %874 = load ptr, ptr %789, align 8
  %875 = load float, ptr %873, align 4
  %876 = call float @generate_stmt_euclidean(ptr %874, float %875)
  ; --- Begin Fused Kernel ---
  %877 = load float, ptr %861, align 4
  %878 = fadd float %877, 1
  ; --- End Fused Kernel ---
  store float %878, ptr %861, align 4
  br label %while_cond_256
while_end_258:
  %879 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  %880 = load float, ptr %879, align 4
  %881 = fadd float %880, string:@.str.113
  %882 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  store float %881, ptr %882, align 4
  br label %end_255
else_254:
  %883 = getelementptr inbounds ptr, ptr %790, i32 0, i32 0
  %884 = load float, ptr %883, align 4
  %885 = fcmp oeq float %884, string:@.str.114
  %886 = uitofp i1 %885 to float
  %887 = fcmp one float %886, 0.0
  br i1 %887, label %then_259, label %end_261
then_259:
  %888 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  %889 = load float, ptr %888, align 4
  %890 = fadd float %889, string:@.str.115
  %891 = getelementptr inbounds ptr, ptr %790, i32 0, i32 0
  %892 = load float, ptr %891, align 4
  %893 = fadd float %890, %892
  %894 = fadd float %893, string:@.str.116
  %895 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  store float %894, ptr %895, align 4
  %896 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  %897 = load float, ptr %896, align 4
  %898 = fadd float %897, string:@.str.117
  %899 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  store float %898, ptr %899, align 4
  %900 = alloca float, align 4
  store float 0, ptr %900, align 4
  br label %while_cond_262
while_cond_262:
  %901 = load float, ptr %900, align 4
  %902 = getelementptr inbounds ptr, ptr %790, i32 0, i32 0
  %903 = load float, ptr %902, align 4
  %904 = call float @StructName_tree_size(%StructName undef, float %903)
  %905 = fcmp olt float %901, %904
  %906 = uitofp i1 %905 to float
  %907 = fcmp one float %906, 0.0
  br i1 %907, label %while_body_263, label %while_end_264
while_body_263:
  %908 = getelementptr inbounds ptr, ptr %790, i32 0, i32 0
  %909 = load float, ptr %908, align 4
  %910 = load float, ptr %900, align 4
  %911 = call float @StructName_tree_get(%StructName undef, float %909, float %910)
  %912 = alloca float, align 4
  store float %911, ptr %912, align 4
  %913 = load ptr, ptr %789, align 8
  %914 = load float, ptr %912, align 4
  %915 = call float @generate_stmt_euclidean(ptr %913, float %914)
  ; --- Begin Fused Kernel ---
  %916 = load float, ptr %900, align 4
  %917 = fadd float %916, 1
  ; --- End Fused Kernel ---
  store float %917, ptr %900, align 4
  br label %while_cond_262
while_end_264:
  %918 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  %919 = load float, ptr %918, align 4
  %920 = fadd float %919, string:@.str.118
  %921 = getelementptr inbounds ptr, ptr %789, i32 0, i32 0
  store float %920, ptr %921, align 4
  br label %end_261
end_261:
  br label %end_255
end_255:
  br label %end_249
end_249:
  br label %end_246
end_246:
  br label %end_243
end_243:
  ret void
}

define ptr @generate_llvm(ptr %arg_program) {
entry:
  %922 = alloca ptr, align 4
  store ptr %arg_program, ptr %922, align 4
  %923 = call ptr @llvm_init()
  %924 = alloca ptr, align 8
  store ptr %923, ptr %924, align 8
  %925 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  %926 = load float, ptr %925, align 4
  %927 = fadd float %926, string:@.str.119
  %928 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  store float %927, ptr %928, align 4
  %929 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  %930 = load float, ptr %929, align 4
  %931 = fadd float %930, string:@.str.120
  %932 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  store float %931, ptr %932, align 4
  %933 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  %934 = load float, ptr %933, align 4
  %935 = fadd float %934, string:@.str.121
  %936 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  store float %935, ptr %936, align 4
  %937 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  %938 = load float, ptr %937, align 4
  %939 = fadd float %938, string:@.str.122
  %940 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  store float %939, ptr %940, align 4
  %941 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  %942 = load float, ptr %941, align 4
  %943 = fadd float %942, string:@.str.123
  %944 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  store float %943, ptr %944, align 4
  %945 = alloca float, align 4
  store float 0, ptr %945, align 4
  br label %while_cond_265
while_cond_265:
  %946 = load float, ptr %945, align 4
  %947 = getelementptr inbounds ptr, ptr %922, i32 0, i32 0
  %948 = load float, ptr %947, align 4
  %949 = call float @StructName_tree_size(%StructName undef, float %948)
  %950 = fcmp olt float %946, %949
  %951 = uitofp i1 %950 to float
  %952 = fcmp one float %951, 0.0
  br i1 %952, label %while_body_266, label %while_end_267
while_body_266:
  %953 = getelementptr inbounds ptr, ptr %922, i32 0, i32 0
  %954 = load float, ptr %953, align 4
  %955 = load float, ptr %945, align 4
  %956 = call float @StructName_tree_get(%StructName undef, float %954, float %955)
  %957 = alloca float, align 4
  store float %956, ptr %957, align 4
  %958 = load ptr, ptr %924, align 8
  %959 = load float, ptr %957, align 4
  call void @generate_stmt(ptr %958, float %959)
  ; --- Begin Fused Kernel ---
  %960 = load float, ptr %945, align 4
  %961 = fadd float %960, 1
  ; --- End Fused Kernel ---
  store float %961, ptr %945, align 4
  br label %while_cond_265
while_end_267:
  %962 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  %963 = load float, ptr %962, align 4
  %964 = fadd float %963, string:@.str.124
  %965 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  store float %964, ptr %965, align 4
  %966 = alloca float, align 4
  store float 0, ptr %966, align 4
  br label %while_cond_268
while_cond_268:
  %967 = load float, ptr %966, align 4
  %968 = getelementptr inbounds ptr, ptr %922, i32 0, i32 0
  %969 = load float, ptr %968, align 4
  %970 = call float @StructName_tree_size(%StructName undef, float %969)
  %971 = fcmp olt float %967, %970
  %972 = uitofp i1 %971 to float
  %973 = fcmp one float %972, 0.0
  br i1 %973, label %while_body_269, label %while_end_270
while_body_269:
  %974 = getelementptr inbounds ptr, ptr %922, i32 0, i32 0
  %975 = load float, ptr %974, align 4
  %976 = load float, ptr %966, align 4
  %977 = call float @StructName_tree_get(%StructName undef, float %975, float %976)
  %978 = alloca float, align 4
  store float %977, ptr %978, align 4
  %979 = getelementptr inbounds %StructName, ptr %978, i32 0, i32 0
  %980 = load float, ptr %979, align 4
  %981 = fcmp oeq float %980, string:@.str.125
  %982 = uitofp i1 %981 to float
  %983 = fcmp one float %982, 0.0
  br i1 %983, label %then_271, label %end_273
then_271:
  %984 = getelementptr inbounds %StructName, ptr %978, i32 0, i32 0
  %985 = load float, ptr %984, align 4
  %986 = fcmp one float %985, 0.0
  br i1 %986, label %then_274, label %end_276
then_274:
  %987 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  %988 = load float, ptr %987, align 4
  %989 = fadd float %988, string:@.str.126
  %990 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  store float %989, ptr %990, align 4
  %991 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  %992 = load float, ptr %991, align 4
  %993 = fadd float %992, string:@.str.127
  %994 = getelementptr inbounds %StructName, ptr %978, i32 0, i32 0
  %995 = load float, ptr %994, align 4
  %996 = fadd float %993, %995
  %997 = fadd float %996, string:@.str.128
  %998 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  store float %997, ptr %998, align 4
  br label %end_276
end_276:
  br label %end_273
end_273:
  ; --- Begin Fused Kernel ---
  %999 = load float, ptr %966, align 4
  %1000 = fadd float %999, 1
  ; --- End Fused Kernel ---
  store float %1000, ptr %966, align 4
  br label %while_cond_268
while_end_270:
  %1001 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  %1002 = load float, ptr %1001, align 4
  %1003 = fadd float %1002, string:@.str.129
  %1004 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  store float %1003, ptr %1004, align 4
  %1005 = getelementptr inbounds ptr, ptr %924, i32 0, i32 0
  %1006 = load float, ptr %1005, align 4
  %1007 = fptoui float %1006 to i64
  %1008 = inttoptr i64 %1007 to ptr
  ret ptr %1008
unreachable_277:
  ret ptr null
}

define ptr @compile(ptr %arg_source_code) {
entry:
  %1009 = alloca ptr, align 4
  store ptr %arg_source_code, ptr %1009, align 4
  %1010 = load ptr, ptr %1009, align 8
  %1011 = call float @lexer_init_euclidean(ptr %1010)
  %1012 = alloca float, align 4
  store float %1011, ptr %1012, align 4
  %1013 = call float @StructName_tree_create(%StructName undef)
  %1014 = alloca float, align 4
  store float %1013, ptr %1014, align 4
  br label %while_cond_278
while_cond_278:
  %1015 = fcmp one float 0.0, 0.0
  br i1 %1015, label %while_body_279, label %while_end_280
while_body_279:
  %1016 = load float, ptr %1012, align 4
  %1017 = call ptr @lexer_next_token(float %1016)
  %1018 = alloca ptr, align 8
  store ptr %1017, ptr %1018, align 8
  %1019 = load float, ptr %1014, align 4
  %1020 = load ptr, ptr %1018, align 8
  %1021 = call float @StructName_tree_push(%StructName undef, float %1019, ptr %1020)
  %1022 = getelementptr inbounds ptr, ptr %1018, i32 0, i32 0
  %1023 = load float, ptr %1022, align 4
  %1024 = fcmp oeq float %1023, string:@.str.130
  %1025 = uitofp i1 %1024 to float
  %1026 = fcmp one float %1025, 0.0
  br i1 %1026, label %then_281, label %end_283
then_281:
  br label %while_end_280
unreachable_284:
  br label %end_283
end_283:
  br label %while_cond_278
while_end_280:
  %1027 = load float, ptr %1014, align 4
  %1028 = call ptr @parser_init(float %1027)
  %1029 = alloca ptr, align 8
  store ptr %1028, ptr %1029, align 8
  %1030 = load ptr, ptr %1029, align 8
  %1031 = call ptr @parse_block(ptr %1030)
  %1032 = alloca ptr, align 8
  store ptr %1031, ptr %1032, align 8
  %1033 = alloca float, align 4
  store float 0.0, ptr %1033, align 4
  %1034 = load float, ptr %1033, align 4
  %1035 = call ptr @expand_macros_program(float %1034)
  store ptr %1035, ptr %1033, align 8
  %1036 = load float, ptr %1033, align 4
  %1037 = call ptr @typecheck_program(float %1036)
  store ptr %1037, ptr %1033, align 8
  %1038 = load float, ptr %1033, align 4
  %1039 = call ptr @optimize_program(float %1038)
  store ptr %1039, ptr %1033, align 8
  %1040 = load float, ptr %1033, align 4
  %1041 = call ptr @generate_llvm(float %1040)
  %1042 = alloca ptr, align 8
  store ptr %1041, ptr %1042, align 8
  %1043 = load ptr, ptr %1042, align 8
  ret ptr %1043
unreachable_285:
  ret ptr null
}

define void @user_main() {
entry:
  %1044 = load float, ptr @.str.131, align 4
  %1045 = call ptr @compile(float %1044)
  %1046 = alloca ptr, align 8
  store ptr %1045, ptr %1046, align 8
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
declare ptr @cartan_tokenize_bpe(ptr, ptr)
declare void @cartan_align_spans(ptr, ptr, ptr)
declare void @cartan_free_compute_graph()
declare void @cartan_fluid_precision_start(ptr, ptr)
declare void @cartan_fluid_precision_end()
declare void @cartan_sparsity_start(i32, float)
declare void @cartan_sparsity_end()
declare void @cartan_prune_graph(float)
@.str.0 = private unnamed_addr constant [2 x i8] c"\0a\00", align 1
@.str.1 = private unnamed_addr constant [3 x i8] c"\5c\30\00", align 1
@.str.2 = private unnamed_addr constant [2 x i8] c"\20\00", align 1
@.str.3 = private unnamed_addr constant [3 x i8] c"\5c\72\00", align 1
@.str.4 = private unnamed_addr constant [2 x i8] c"\7b\00", align 1
@.str.5 = private unnamed_addr constant [2 x i8] c"\7d\00", align 1
@.str.6 = private unnamed_addr constant [2 x i8] c"\28\00", align 1
@.str.7 = private unnamed_addr constant [2 x i8] c"\29\00", align 1
@.str.8 = private unnamed_addr constant [2 x i8] c"\5b\00", align 1
@.str.9 = private unnamed_addr constant [2 x i8] c"\5d\00", align 1
@.str.10 = private unnamed_addr constant [2 x i8] c"\3b\00", align 1
@.str.11 = private unnamed_addr constant [2 x i8] c"\2c\00", align 1
@.str.12 = private unnamed_addr constant [11 x i8] c"\49\64\65\6e\74\69\66\69\65\72\00", align 1
@.str.13 = private unnamed_addr constant [3 x i8] c"\66\6e\00", align 1
@.str.14 = private unnamed_addr constant [3 x i8] c"\46\6e\00", align 1
@.str.15 = private unnamed_addr constant [7 x i8] c"\73\74\72\75\63\74\00", align 1
@.str.16 = private unnamed_addr constant [7 x i8] c"\53\74\72\75\63\74\00", align 1
@.str.17 = private unnamed_addr constant [7 x i8] c"\74\65\6e\73\6f\72\00", align 1
@.str.18 = private unnamed_addr constant [7 x i8] c"\54\65\6e\73\6f\72\00", align 1
@.str.19 = private unnamed_addr constant [3 x i8] c"\69\66\00", align 1
@.str.20 = private unnamed_addr constant [3 x i8] c"\49\66\00", align 1
@.str.21 = private unnamed_addr constant [5 x i8] c"\65\6c\73\65\00", align 1
@.str.22 = private unnamed_addr constant [5 x i8] c"\45\6c\73\65\00", align 1
@.str.23 = private unnamed_addr constant [6 x i8] c"\77\68\69\6c\65\00", align 1
@.str.24 = private unnamed_addr constant [6 x i8] c"\57\68\69\6c\65\00", align 1
@.str.25 = private unnamed_addr constant [7 x i8] c"\72\65\74\75\72\6e\00", align 1
@.str.26 = private unnamed_addr constant [7 x i8] c"\52\65\74\75\72\6e\00", align 1
@.str.27 = private unnamed_addr constant [5 x i8] c"\6c\61\7a\79\00", align 1
@.str.28 = private unnamed_addr constant [5 x i8] c"\4c\61\7a\79\00", align 1
@.str.29 = private unnamed_addr constant [8 x i8] c"\75\6e\69\66\69\65\64\00", align 1
@.str.30 = private unnamed_addr constant [8 x i8] c"\55\6e\69\66\69\65\64\00", align 1
@.str.31 = private unnamed_addr constant [7 x i8] c"\6c\61\74\65\6e\74\00", align 1
@.str.32 = private unnamed_addr constant [7 x i8] c"\4c\61\74\65\6e\74\00", align 1
@.str.33 = private unnamed_addr constant [5 x i8] c"\76\6d\61\70\00", align 1
@.str.34 = private unnamed_addr constant [5 x i8] c"\56\6d\61\70\00", align 1
@.str.35 = private unnamed_addr constant [11 x i8] c"\6d\75\6c\74\69\6d\6f\64\61\6c\00", align 1
@.str.36 = private unnamed_addr constant [11 x i8] c"\4d\75\6c\74\69\6d\6f\64\61\6c\00", align 1
@.str.37 = private unnamed_addr constant [7 x i8] c"\76\65\63\74\6f\72\00", align 1
@.str.38 = private unnamed_addr constant [7 x i8] c"\56\65\63\74\6f\72\00", align 1
@.str.39 = private unnamed_addr constant [3 x i8] c"\61\74\00", align 1
@.str.40 = private unnamed_addr constant [3 x i8] c"\41\74\00", align 1
@.str.41 = private unnamed_addr constant [18 x i8] c"\40\61\67\65\6e\74\5f\61\63\63\65\73\73\69\62\6c\65\00", align 1
@.str.42 = private unnamed_addr constant [16 x i8] c"\41\67\65\6e\74\41\63\63\65\73\73\69\62\6c\65\00", align 1
@.str.43 = private unnamed_addr constant [8 x i8] c"\68\6f\74\73\77\61\70\00", align 1
@.str.44 = private unnamed_addr constant [8 x i8] c"\48\6f\74\53\77\61\70\00", align 1
@.str.45 = private unnamed_addr constant [6 x i8] c"\64\6f\75\62\74\00", align 1
@.str.46 = private unnamed_addr constant [6 x i8] c"\44\6f\75\62\74\00", align 1
@.str.47 = private unnamed_addr constant [4 x i8] c"\45\4f\46\00", align 1
@.str.48 = private unnamed_addr constant [7 x i8] c"\4c\42\72\61\63\65\00", align 1
@.str.49 = private unnamed_addr constant [27 x i8] c"\45\78\70\65\63\74\65\64\20\27\7b\27\20\62\65\66\6f\72\65\20\62\6c\6f\63\6b\2e\00", align 1
@.str.50 = private unnamed_addr constant [7 x i8] c"\52\42\72\61\63\65\00", align 1
@.str.51 = private unnamed_addr constant [4 x i8] c"\45\4f\46\00", align 1
@.str.52 = private unnamed_addr constant [7 x i8] c"\52\42\72\61\63\65\00", align 1
@.str.53 = private unnamed_addr constant [26 x i8] c"\45\78\70\65\63\74\65\64\20\27\7d\27\20\61\66\74\65\72\20\62\6c\6f\63\6b\2e\00", align 1
@.str.54 = private unnamed_addr constant [5 x i8] c"\4c\61\7a\79\00", align 1
@.str.55 = private unnamed_addr constant [8 x i8] c"\55\6e\69\66\69\65\64\00", align 1
@.str.56 = private unnamed_addr constant [7 x i8] c"\4c\61\74\65\6e\74\00", align 1
@.str.57 = private unnamed_addr constant [16 x i8] c"\41\67\65\6e\74\41\63\63\65\73\73\69\62\6c\65\00", align 1
@.str.58 = private unnamed_addr constant [3 x i8] c"\46\6e\00", align 1
@.str.59 = private unnamed_addr constant [7 x i8] c"\54\65\6e\73\6f\72\00", align 1
@.str.60 = private unnamed_addr constant [5 x i8] c"\56\6d\61\70\00", align 1
@.str.61 = private unnamed_addr constant [11 x i8] c"\4d\75\6c\74\69\6d\6f\64\61\6c\00", align 1
@.str.62 = private unnamed_addr constant [7 x i8] c"\56\65\63\74\6f\72\00", align 1
@.str.63 = private unnamed_addr constant [11 x i8] c"\49\64\65\6e\74\69\66\69\65\72\00", align 1
@.str.64 = private unnamed_addr constant [24 x i8] c"\45\78\70\65\63\74\65\64\20\66\75\6e\63\74\69\6f\6e\20\6e\61\6d\65\2e\00", align 1
@.str.65 = private unnamed_addr constant [7 x i8] c"\4c\50\61\72\65\6e\00", align 1
@.str.66 = private unnamed_addr constant [34 x i8] c"\45\78\70\65\63\74\65\64\20\27\28\27\20\61\66\74\65\72\20\66\75\6e\63\74\69\6f\6e\20\6e\61\6d\65\2e\00", align 1
@.str.67 = private unnamed_addr constant [7 x i8] c"\52\50\61\72\65\6e\00", align 1
@.str.68 = private unnamed_addr constant [31 x i8] c"\45\78\70\65\63\74\65\64\20\27\29\27\20\61\66\74\65\72\20\70\61\72\61\6d\65\74\65\72\73\2e\00", align 1
@.str.69 = private unnamed_addr constant [11 x i8] c"\49\64\65\6e\74\69\66\69\65\72\00", align 1
@.str.70 = private unnamed_addr constant [22 x i8] c"\45\78\70\65\63\74\65\64\20\74\65\6e\73\6f\72\20\6e\61\6d\65\2e\00", align 1
@.str.71 = private unnamed_addr constant [10 x i8] c"\53\65\6d\69\63\6f\6c\6f\6e\00", align 1
@.str.72 = private unnamed_addr constant [39 x i8] c"\45\78\70\65\63\74\65\64\20\27\3b\27\20\61\66\74\65\72\20\74\65\6e\73\6f\72\20\64\65\63\6c\61\72\61\74\69\6f\6e\2e\00", align 1
@.str.73 = private unnamed_addr constant [11 x i8] c"\49\64\65\6e\74\69\66\69\65\72\00", align 1
@.str.74 = private unnamed_addr constant [22 x i8] c"\45\78\70\65\63\74\65\64\20\76\65\63\74\6f\72\20\6e\61\6d\65\2e\00", align 1
@.str.75 = private unnamed_addr constant [9 x i8] c"\4c\42\72\61\63\6b\65\74\00", align 1
@.str.76 = private unnamed_addr constant [32 x i8] c"\45\78\70\65\63\74\65\64\20\27\5b\27\20\61\66\74\65\72\20\76\65\63\74\6f\72\20\6e\61\6d\65\2e\00", align 1
@.str.77 = private unnamed_addr constant [9 x i8] c"\52\42\72\61\63\6b\65\74\00", align 1
@.str.78 = private unnamed_addr constant [37 x i8] c"\45\78\70\65\63\74\65\64\20\27\5d\27\20\61\66\74\65\72\20\76\65\63\74\6f\72\20\64\69\6d\65\6e\73\69\6f\6e\2e\00", align 1
@.str.79 = private unnamed_addr constant [3 x i8] c"\41\74\00", align 1
@.str.80 = private unnamed_addr constant [11 x i8] c"\49\64\65\6e\74\69\66\69\65\72\00", align 1
@.str.81 = private unnamed_addr constant [32 x i8] c"\45\78\70\65\63\74\65\64\20\61\6e\63\68\6f\72\20\6e\61\6d\65\20\61\66\74\65\72\20\27\61\74\27\00", align 1
@.str.82 = private unnamed_addr constant [10 x i8] c"\53\65\6d\69\63\6f\6c\6f\6e\00", align 1
@.str.83 = private unnamed_addr constant [39 x i8] c"\45\78\70\65\63\74\65\64\20\27\3b\27\20\61\66\74\65\72\20\76\65\63\74\6f\72\20\64\65\63\6c\61\72\61\74\69\6f\6e\2e\00", align 1
@.str.84 = private unnamed_addr constant [7 x i8] c"\4c\42\72\61\63\65\00", align 1
@.str.85 = private unnamed_addr constant [30 x i8] c"\45\78\70\65\63\74\65\64\20\27\7b\27\20\61\66\74\65\72\20\6d\75\6c\74\69\6d\6f\64\61\6c\00", align 1
@.str.86 = private unnamed_addr constant [10 x i8] c"\54\72\61\6e\73\70\6f\73\65\00", align 1
@.str.87 = private unnamed_addr constant [10 x i8] c"\54\72\61\6e\73\70\6f\73\65\00", align 1
@.str.88 = private unnamed_addr constant [5 x i8] c"\4e\75\6c\6c\00", align 1
@.str.89 = private unnamed_addr constant [5 x i8] c"\4e\75\6c\6c\00", align 1
@.str.90 = private unnamed_addr constant [8 x i8] c"\46\6c\6f\61\74\33\32\00", align 1
@.str.91 = private unnamed_addr constant [2 x i8] c"\25\00", align 1
@.str.92 = private unnamed_addr constant [8 x i8] c"\49\6e\74\65\67\65\72\00", align 1
@.str.93 = private unnamed_addr constant [6 x i8] c"\46\6c\6f\61\74\00", align 1
@.str.94 = private unnamed_addr constant [11 x i8] c"\49\64\65\6e\74\69\66\69\65\72\00", align 1
@.str.95 = private unnamed_addr constant [2 x i8] c"\25\00", align 1
@.str.96 = private unnamed_addr constant [7 x i8] c"\42\69\6e\61\72\79\00", align 1
@.str.97 = private unnamed_addr constant [3 x i8] c"\20\20\00", align 1
@.str.98 = private unnamed_addr constant [15 x i8] c"\20\3d\20\66\61\64\64\20\66\6c\6f\61\74\20\00", align 1
@.str.99 = private unnamed_addr constant [3 x i8] c"\2c\20\00", align 1
@.str.100 = private unnamed_addr constant [2 x i8] c"\0a\00", align 1
@.str.101 = private unnamed_addr constant [4 x i8] c"\30\2e\30\00", align 1
@.str.102 = private unnamed_addr constant [11 x i8] c"\54\65\6e\73\6f\72\44\65\63\6c\00", align 1
@.str.103 = private unnamed_addr constant [3 x i8] c"\20\20\00", align 1
@.str.104 = private unnamed_addr constant [48 x i8] c"\20\3d\20\63\61\6c\6c\20\70\74\72\20\40\63\61\72\74\61\6e\5f\74\65\6e\73\6f\72\5f\61\6c\6c\6f\63\28\69\33\32\20\31\2c\20\69\33\32\20\30\29\0a\00", align 1
@.str.105 = private unnamed_addr constant [11 x i8] c"\56\65\63\74\6f\72\44\65\63\6c\00", align 1
@.str.106 = private unnamed_addr constant [3 x i8] c"\20\20\00", align 1
@.str.107 = private unnamed_addr constant [48 x i8] c"\20\3d\20\63\61\6c\6c\20\70\74\72\20\40\63\61\72\74\61\6e\5f\74\65\6e\73\6f\72\5f\61\6c\6c\6f\63\28\69\33\32\20\31\2c\20\69\33\32\20\30\29\0a\00", align 1
@.str.108 = private unnamed_addr constant [16 x i8] c"\4d\75\6c\74\69\6d\6f\64\61\6c\42\6c\6f\63\6b\00", align 1
@.str.109 = private unnamed_addr constant [48 x i8] c"\20\20\63\61\6c\6c\20\76\6f\69\64\20\40\63\61\72\74\61\6e\5f\72\74\5f\6d\75\6c\74\69\6d\6f\64\61\6c\5f\73\79\6e\63\5f\73\74\61\72\74\28\29\0a\00", align 1
@.str.110 = private unnamed_addr constant [46 x i8] c"\20\20\63\61\6c\6c\20\76\6f\69\64\20\40\63\61\72\74\61\6e\5f\72\74\5f\6d\75\6c\74\69\6d\6f\64\61\6c\5f\73\79\6e\63\5f\65\6e\64\28\29\0a\00", align 1
@.str.111 = private unnamed_addr constant [10 x i8] c"\56\6d\61\70\42\6c\6f\63\6b\00", align 1
@.str.112 = private unnamed_addr constant [30 x i8] c"\20\20\3b\20\2d\2d\2d\20\42\65\67\69\6e\20\56\6d\61\70\20\42\6c\6f\63\6b\20\2d\2d\2d\0a\00", align 1
@.str.113 = private unnamed_addr constant [28 x i8] c"\20\20\3b\20\2d\2d\2d\20\45\6e\64\20\56\6d\61\70\20\42\6c\6f\63\6b\20\2d\2d\2d\0a\00", align 1
@.str.114 = private unnamed_addr constant [13 x i8] c"\46\75\6e\63\74\69\6f\6e\44\65\63\6c\00", align 1
@.str.115 = private unnamed_addr constant [14 x i8] c"\64\65\66\69\6e\65\20\76\6f\69\64\20\40\00", align 1
@.str.116 = private unnamed_addr constant [6 x i8] c"\28\29\20\7b\0a\00", align 1
@.str.117 = private unnamed_addr constant [8 x i8] c"\65\6e\74\72\79\3a\0a\00", align 1
@.str.118 = private unnamed_addr constant [15 x i8] c"\20\20\72\65\74\20\76\6f\69\64\0a\7d\0a\0a\00", align 1
@.str.119 = private unnamed_addr constant [44 x i8] c"\64\65\63\6c\61\72\65\20\70\74\72\20\40\63\61\72\74\61\6e\5f\74\65\6e\73\6f\72\5f\61\6c\6c\6f\63\28\69\33\32\2c\20\69\33\32\29\0a\00", align 1
@.str.120 = private unnamed_addr constant [49 x i8] c"\64\65\63\6c\61\72\65\20\76\6f\69\64\20\40\63\61\72\74\61\6e\5f\72\74\5f\6d\75\6c\74\69\6d\6f\64\61\6c\5f\73\79\6e\63\5f\73\74\61\72\74\28\29\0a\00", align 1
@.str.121 = private unnamed_addr constant [47 x i8] c"\64\65\63\6c\61\72\65\20\76\6f\69\64\20\40\63\61\72\74\61\6e\5f\72\74\5f\6d\75\6c\74\69\6d\6f\64\61\6c\5f\73\79\6e\63\5f\65\6e\64\28\29\0a\00", align 1
@.str.122 = private unnamed_addr constant [55 x i8] c"\64\65\63\6c\61\72\65\20\76\6f\69\64\20\40\63\61\72\74\61\6e\5f\72\74\5f\72\65\67\69\73\74\65\72\5f\63\61\70\61\62\69\6c\69\74\79\28\70\74\72\2c\20\70\74\72\29\0a\00", align 1
@.str.123 = private unnamed_addr constant [39 x i8] c"\64\65\63\6c\61\72\65\20\70\74\72\20\40\63\61\72\74\61\6e\5f\72\74\5f\6c\6f\61\64\5f\61\65\72\28\70\74\72\29\0a\0a\00", align 1
@.str.124 = private unnamed_addr constant [29 x i8] c"\64\65\66\69\6e\65\20\69\33\32\20\40\6d\61\69\6e\28\29\20\7b\0a\65\6e\74\72\79\3a\0a\00", align 1
@.str.125 = private unnamed_addr constant [13 x i8] c"\46\75\6e\63\74\69\6f\6e\44\65\63\6c\00", align 1
@.str.126 = private unnamed_addr constant [41 x i8] c"\20\20\3b\20\53\69\6d\75\6c\61\74\65\64\20\72\65\67\69\73\74\72\61\74\69\6f\6e\20\73\74\72\69\6e\67\20\63\6f\6e\73\74\0a\00", align 1
@.str.127 = private unnamed_addr constant [59 x i8] c"\20\20\63\61\6c\6c\20\76\6f\69\64\20\40\63\61\72\74\61\6e\5f\72\74\5f\72\65\67\69\73\74\65\72\5f\63\61\70\61\62\69\6c\69\74\79\28\70\74\72\20\6e\75\6c\6c\2c\20\70\74\72\20\40\00", align 1
@.str.128 = private unnamed_addr constant [3 x i8] c"\29\0a\00", align 1
@.str.129 = private unnamed_addr constant [16 x i8] c"\20\20\72\65\74\20\69\33\32\20\30\0a\7d\0a\0a\00", align 1
@.str.130 = private unnamed_addr constant [4 x i8] c"\45\4f\46\00", align 1
@.str.131 = private unnamed_addr constant [35 x i8] c"\66\6e\20\74\65\73\74\28\29\20\7b\20\74\65\6e\73\6f\72\5b\31\32\38\5d\20\77\65\69\67\68\74\73\3b\20\7d\00", align 1
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

