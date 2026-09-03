# Compiler Core Squad Consensus: `Token.lexeme` Deprecation & Binary Operator Mapping

## 1. Discovery
Following the prefix stripping and comparison additions, `cartanc.exe` still generated:
```text
cartanc_stage2.ll:178:21: error: '%42' defined with type '' but expected ''
  178 |   %43 = fadd double %42, 0.0
```
Trace investigation into why `if (stmt != 0.0)` in [`src/cartanc/main.car:71`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/main.car#L71) fell through to `fadd` rather than matching `op == "!="` led to a fundamental architecture discovery in the lexer/parser interface.

## 2. Root Cause Analysis
In [`src/cartanc/ast.ch:41-44`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/ast.ch#L41):
```cartan
struct Token {
    token_type: ptr;
    span: Span;
}
```
`struct Token` has **no `lexeme` field**.
However, in [`src/cartanc/parser.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/parser.car):
- Line 1427 (`equality`): `let op = previous(self_ptr).lexeme;`
- Line 1437 (`comparison`): `let op = previous(self_ptr).lexeme;`
- Line 1447 (`term`): `let op = previous(self_ptr).lexeme;`
- Line 1457 (`factor`): `let op = previous(self_ptr).lexeme;`
- Line 1467 (`matmul`): `let op = previous(self_ptr).lexeme;`
- Line 1501 (`unary`): `let op = previous(self_ptr).lexeme;`

Because `struct Token` only has `token_type` at offset 0 and `span` at offset 8, `.lexeme` read `span.line` (the source code line number, e.g. `71.0`) as a float!
Consequently, every binary operation AST node was created with a line number instead of the operator string (`"!="`, `"+"`, etc.).
Because `op == 71.0`, `cartan_string_eq(op, "!=")` returned `0.0`, causing every operator comparison to fail and fall through to the default `fadd double`.

## 3. Proposed Fix
In [`src/cartanc/parser.car`](file:///C:/Users/rich-/source/repos/CARTAN/src/cartanc/parser.car), map `previous(self_ptr).token_type[0]` to the explicit string literal, exactly as `assignment` (lines 1361-1375) already correctly does:
1. In `equality` (lines 1426-1430):
   - `129.0` (`EqEq`) $\to$ `"=="`
   - `130.0` (`NotEq`) $\to$ `"!="`
2. In `comparison` (lines 1436-1440):
   - `131.0` (`Less`) $\to$ `"<"`
   - `132.0` (`LessEq`) $\to$ `"<="`
   - `133.0` (`Greater`) $\to$ `">"`
   - `134.0` (`GreaterEq`) $\to$ `">="`
3. In `term` (lines 1446-1450):
   - `113.0` (`Plus`) $\to$ `"+"`
   - `114.0` (`Minus`) $\to$ `"-"`
4. In `factor` (lines 1456-1460):
   - `115.0` (`Star`) $\to$ `"*"`
   - `116.0` (`Slash`) $\to$ `"/"`
   - `117.0` (`Percent`) $\to$ `"%"`
5. In `matmul` (lines 1466-1470):
   - `148.0` (`MatMul`) $\to$ `"@"`
6. In `unary` (lines 1498-1502):
   - `137.0` (`Not`) $\to$ `"!"`
   - `114.0` (`Minus`) $\to$ `"-"`
