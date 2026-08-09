// CARTAN Auto-Generated C/C++ FFI Header
// Module: src/std/math.car

#ifndef CARTAN_MATH_API_H
#define CARTAN_MATH_API_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

double cartan_math_abs(double x);
double cartan_math_sqrt(double x);
double cartan_math_pow(double base, double exp_val);
double cartan_math_sin(double x);
double cartan_math_cos(double x);
double cartan_math_tan(double x);
double cartan_math_clamp(double val, double min_val, double max_val);
double cartan_math_lerp(double a, double b, double t);

#ifdef __cplusplus
}
#endif

#endif // CARTAN_MATH_API_H
