# CARTAN Standard Library API Documentation

**Module**: `src/std/math.car`  
**Status**: Production-Grade Native CARTAN Implementation

---

## Exported Functions

### `math::abs(x: float) -> float`
- **Description**: Computes the absolute value of a scalar floating-point number.

### `math::sqrt(x: float) -> float`
- **Description**: Computes the principal square root of a scalar floating-point number.

### `math::pow(base: float, exp_val: float) -> float`
- **Description**: Raises `base` to the exponent `exp_val`.

### `math::sin(x: float) -> float`, `math::cos(x: float) -> float`, `math::tan(x: float) -> float`
- **Description**: Trigonometric functions operating in radians.

### `math::asin(x: float) -> float`, `math::acos(x: float) -> float`, `math::atan(x: float) -> float`
- **Description**: Inverse trigonometric functions returning principal values.

### `math::sinh(x: float) -> float`, `math::cosh(x: float) -> float`, `math::tanh(x: float) -> float`
- **Description**: Hyperbolic trigonometric functions.

### `math::clamp(val: float, min_val: float, max_val: float) -> float`
- **Description**: Clamps `val` within the inclusive range `[min_val, max_val]`.

### `math::lerp(a: float, b: float, t: float) -> float`
- **Description**: Performs linear interpolation between `a` and `b` by weight `t`.
