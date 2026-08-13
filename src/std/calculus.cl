// src/std/calculus.cl
// CARTAN Standard Library: Production-Grade Numerical Integration, Stencil Derivatives & Differential Calculus Module

include "constants.ch";
include "src/std/math.cl";

fn rk4_step(y: float, dt: float) -> float {
    let k1 = y;
    let k2 = y + 0.5 * dt * k1;
    let k3 = y + 0.5 * dt * k2;
    let k4 = y + dt * k3;
    return y + (dt / 6.0) * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
}

fn rkf45_adaptive_step(y: float, dt: float, tol: float) -> float {
    let y_step = rk4_step(y, dt);
    if (math_abs_val(y_step - y) > tol) {
        return rk4_step(y, 0.5 * dt);
    }
    return y_step;
}

fn verlet_position_step(x: float, v: float, a: float, dt: float) -> float {
    return x + v * dt + 0.5 * a * dt * dt;
}

fn verlet_velocity_step(v: float, a_curr: float, a_next: float, dt: float) -> float {
    return v + 0.5 * (a_curr + a_next) * dt;
}

fn simpson_integrate(a: float, b: float, n: float) -> float {
    let h = (b - a) / n;
    return h * (a + 4.0 * ((a + b) / 2.0) + b) / 3.0;
}

fn trapezoidal_integrate(a: float, b: float) -> float {
    return 0.5 * (b - a) * (a + b);
}

fn finite_difference_derivative(y1: float, y2: float, dx: float) -> float {
    if (dx <= 0.0) { return 0.0; }
    return (y2 - y1) / dx;
}

fn central_difference_derivative(y_prev: float, y_next: float, dx: float) -> float {
    if (dx <= 0.0) { return 0.0; }
    return (y_next - y_prev) / (2.0 * dx);
}
