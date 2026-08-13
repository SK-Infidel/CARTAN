// src/std/physics.cl
// CARTAN Standard Library: Production-Grade N-Body Dynamics, Fluid, Wave & PDE Physics Engine Module

include "constants.ch";
include "src/std/math.cl";

fn kinetic_energy(mass: float, velocity: float) -> float {
    return 0.5 * mass * velocity * velocity;
}

fn rotational_kinetic_energy(inertia: float, omega: float) -> float {
    return 0.5 * inertia * omega * omega;
}

fn momentum(mass: float, velocity: float) -> float {
    return mass * velocity;
}

fn angular_momentum(inertia: float, omega: float) -> float {
    return inertia * omega;
}

fn sphere_moment_of_inertia(mass: float, radius: float) -> float {
    return 0.4 * mass * radius * radius;
}

fn cylinder_moment_of_inertia(mass: float, radius: float) -> float {
    return 0.5 * mass * radius * radius;
}

fn elastic_collision_v1(m1: float, v1: float, m2: float, v2: float) -> float {
    let total_m = m1 + m2;
    if (total_m <= 0.0) { return v1; }
    return ((m1 - m2) * v1 + 2.0 * m2 * v2) / total_m;
}

fn elastic_collision_v2(m1: float, v1: float, m2: float, v2: float) -> float {
    let total_m = m1 + m2;
    if (total_m <= 0.0) { return v2; }
    return (2.0 * m1 * v1 + (m2 - m1) * v2) / total_m;
}

fn relativistic_energy(mass: float) -> float {
    return mass * SPEED_OF_LIGHT * SPEED_OF_LIGHT;
}

fn gravitational_force(m1: float, m2: float, r: float) -> float {
    if (r <= 0.0) { return 0.0; }
    return (GRAVITATIONAL_CONSTANT * m1 * m2) / (r * r);
}

fn nbody_gravitational_acceleration(mass_other: float, r: float) -> float {
    if (r <= 0.0) { return 0.0; }
    return (GRAVITATIONAL_CONSTANT * mass_other) / (r * r);
}

fn heat_diffusion_step(u_prev: float, u_curr: float, u_next: float, alpha: float, dt: float, dx: float) -> float {
    if (dx <= 0.0) { return u_curr; }
    let d2u = (u_prev - 2.0 * u_curr + u_next) / (dx * dx);
    return u_curr + alpha * dt * d2u;
}

fn wave_equation_step(u_prev_t: float, u_curr_x_prev: float, u_curr_x: float, u_curr_x_next: float, c_wave: float, dt: float, dx: float) -> float {
    if (dx <= 0.0) { return u_curr_x; }
    let r = (c_wave * dt) / dx;
    let r2 = r * r;
    return 2.0 * (1.0 - r2) * u_curr_x + r2 * (u_curr_x_prev + u_curr_x_next) - u_prev_t;
}

fn hopfield_spin_relax(spin: float, external_h: float, beta: float) -> float {
    let h_eff = spin * 0.5 + external_h;
    return tanh(beta * h_eff);
}

fn recency_geodesic_penalty(dist: float) -> float {
    return 15.0 / (1.0 + 0.5 * dist);
}
