// src/std/conscious_agent.cl
// CARTAN Standard Library: Donald Hoffman Conscious Realism Network Architecture
// Integrates Row-Stochastic Kernels, Ising Glauber Attractors, and Non-Euclidean Metrics

include "src/std/math.cl";
include "src/std/tensor.cl";
include "src/std/markov.cl";
include "test/geomind/ising_state_machine.cl";
include "src/std/string.cl";
include "src/std/fs.cl";

struct ConsciousAgent {
    d_x: float;
    d_g: float;
    d_w: float;
    beta: float;
    P: ptr;
    D: ptr;
    A: ptr;
    T_composite: ptr;
    pi_stationary: ptr;
    L_P: ptr;
    L_A: ptr;
    spins: ptr;
    J_matrix: ptr;
    h_bias: ptr;
    W_xg: ptr;
    x_buf: ptr;
    x_prev: ptr;
    g_buf: ptr;
}

// Allocates and initializes a Conscious Agent instance with verified non-Euclidean stochastic kernels
fn conscious_agent_create(d_x: float, d_g: float, d_w: float, beta: float) -> ConsciousAgent {
    let P_size = d_w * d_x;
    let D_size = d_x * d_g;
    let A_size = d_g * d_w;
    let T_size = d_w * d_w;

    let P = tensor_alloc(P_size);
    let D = tensor_alloc(D_size);
    let A = tensor_alloc(A_size);
    let T_composite = tensor_alloc(T_size);
    let pi_stat = tensor_alloc(d_w);

    let L_P = tensor_alloc(P_size);
    let L_A = tensor_alloc(A_size);

    let spins = tensor_alloc(d_g);
    let J_mat = tensor_alloc(d_g * d_g);
    let h_bias = tensor_alloc(d_g);
    let W_xg = tensor_alloc(d_x * d_g);

    let x_buf = tensor_alloc(d_x);
    let x_prev = tensor_alloc(d_x);
    let g_buf = tensor_alloc(d_g);

    var init_i = 0.0;
    while (init_i < d_x) {
        x_buf[init_i] = 1.0 / d_x;
        x_prev[init_i] = 1.0 / d_x;
        init_i = init_i + 1.0;
    }

    // Initialize Perception logits with harmonic non-trivial spatial phase structure
    var r = 0.0;
    while (r < d_w) {
        var c = 0.0;
        while (c < d_x) {
            let angle = (r + 1.0) * (c + 1.0) * 0.314159265;
            L_P[r * d_x + c] = sin(angle) * 1.5;
            c = c + 1.0;
        }
        r = r + 1.0;
    }
    markov_row_softmax(L_P, d_w, d_x, P);

    // Initialize Action logits
    r = 0.0;
    while (r < d_g) {
        var c = 0.0;
        while (c < d_w) {
            let angle = (r + 2.0) * (c + 1.0) * 0.271828;
            L_A[r * d_w + c] = cos(angle) * 1.5;
            c = c + 1.0;
        }
        r = r + 1.0;
    }
    markov_row_softmax(L_A, d_g, d_w, A);

    // Initialize Perceptual-to-Ising coupling W_xg
    r = 0.0;
    while (r < d_x) {
        var c = 0.0;
        while (c < d_g) {
            let w_val = sin((r + 1.0) * 1.414 + (c + 1.0) * 1.732);
            W_xg[r * d_g + c] = w_val * 0.5;
            c = c + 1.0;
        }
        r = r + 1.0;
    }

    // Initialize Ising spin coupling J (anti-ferromagnetic competitive ring)
    var i = 0.0;
    while (i < d_g) {
        spins[i] = sin((i + 1.0) * 0.5);
        var j = 0.0;
        while (j < d_g) {
            if (i == j) {
                J_mat[i * d_g + j] = 0.0;
            } else {
                let dist = fabs(i - j);
                J_mat[i * d_g + j] = -0.4 / (1.0 + dist);
            }
            j = j + 1.0;
        }
        i = i + 1.0;
    }

    // Initial default Decision matrix D (uniform initial stochastic mapping)
    r = 0.0;
    let unif_g = 1.0 / d_g;
    while (r < d_x) {
        var c = 0.0;
        while (c < d_g) {
            D[r * d_g + c] = unif_g;
            c = c + 1.0;
        }
        r = r + 1.0;
    }

    // Compute initial composite transition matrix T = (P * D) * A
    let PD_temp = tensor_alloc(d_w * d_g);
    markov_matrix_mult(P, D, PD_temp, d_w, d_x, d_g);
    markov_matrix_mult(PD_temp, A, T_composite, d_w, d_g, d_w);
    free(PD_temp);

    // Compute initial stationary state
    markov_stationary_distribution(T_composite, pi_stat, d_w, 50.0);

    let agent = ConsciousAgent {
        d_x: d_x,
        d_g: d_g,
        d_w: d_w,
        beta: beta,
        P: P,
        D: D,
        A: A,
        T_composite: T_composite,
        pi_stationary: pi_stat,
        L_P: L_P,
        L_A: L_A,
        spins: spins,
        J_matrix: J_mat,
        h_bias: h_bias,
        W_xg: W_xg,
        x_buf: x_buf,
        x_prev: x_prev,
        g_buf: g_buf
    };

    return agent;
}

// Executes the Perception step: projects world state w_in into experiential state x_out
fn conscious_agent_perceive(agent: ConsciousAgent, w_in: ptr, x_out: ptr) {
    if (w_in == 0.0 || x_out == 0.0) { return; }
    let d_x = agent.d_x;
    let d_w = agent.d_w;
    let P = agent.P;

    var c = 0.0;
    var sum_x = 0.0;
    while (c < d_x) {
        var dot = 0.0;
        var r = 0.0;
        while (r < d_w) {
            dot = dot + w_in[r] * P[r * d_x + c];
            r = r + 1.0;
        }
        x_out[c] = dot;
        sum_x = sum_x + dot;
        c = c + 1.0;
    }

    // Row-stochastic normalization guard
    if (sum_x > 0.0) {
        let inv_sx = 1.0 / sum_x;
        c = 0.0;
        while (c < d_x) {
            x_out[c] = x_out[c] * inv_sx;
            c = c + 1.0;
        }
    }
}

// Executes the Decision step via the Ising State Machine mean-field Glauber relaxation
fn conscious_agent_decide_ising(agent: ConsciousAgent, x_in: ptr, g_out: ptr, steps: float) -> float {
    if (x_in == 0.0 || g_out == 0.0) { return 0.0; }
    let d_x = agent.d_x;
    let d_g = agent.d_g;
    let beta = agent.beta;
    let spins = agent.spins;
    let J_mat = agent.J_matrix;
    let h_bias = agent.h_bias;
    let W_xg = agent.W_xg;

    // Compute external magnetic bias field: h_bias = x_in * W_xg
    var c = 0.0;
    while (c < d_g) {
        var dot = 0.0;
        var r = 0.0;
        while (r < d_x) {
            dot = dot + x_in[r] * W_xg[r * d_g + c];
            r = r + 1.0;
        }
        h_bias[c] = dot;
        c = c + 1.0;
    }

    // Run Ising Glauber relaxation steps
    geomind_ising_decision_step(spins, J_mat, h_bias, d_g, beta, steps);

    // Compute thermodynamic free energy (decision certainty/entropy metric)
    let free_energy = geomind_ising_free_energy(spins, J_mat, h_bias, d_g, beta);

    // Read out action probability distribution from relaxed spins: g_i proportional to exp(2 * s_i)
    var max_s = spins[0];
    var i = 1.0;
    while (i < d_g) {
        if (spins[i] > max_s) { max_s = spins[i]; }
        i = i + 1.0;
    }

    var sum_exp = 0.0;
    i = 0.0;
    while (i < d_g) {
        let ev = exp(2.0 * (spins[i] - max_s));
        g_out[i] = ev;
        sum_exp = sum_exp + ev;
        i = i + 1.0;
    }

    if (sum_exp <= 0.0) { sum_exp = 1.0; }
    let inv_se = 1.0 / sum_exp;
    i = 0.0;
    while (i < d_g) {
        g_out[i] = g_out[i] * inv_se;
        i = i + 1.0;
    }

    return free_energy;
}

// Executes the Action step: projects action state g_in into updated world state w_out
fn conscious_agent_act(agent: ConsciousAgent, g_in: ptr, w_out: ptr) {
    if (g_in == 0.0 || w_out == 0.0) { return; }
    let d_g = agent.d_g;
    let d_w = agent.d_w;
    let A = agent.A;

    var c = 0.0;
    var sum_w = 0.0;
    while (c < d_w) {
        var dot = 0.0;
        var r = 0.0;
        while (r < d_g) {
            dot = dot + g_in[r] * A[r * d_w + c];
            r = r + 1.0;
        }
        w_out[c] = dot;
        sum_w = sum_w + dot;
        c = c + 1.0;
    }

    if (sum_w > 0.0) {
        let inv_sw = 1.0 / sum_w;
        c = 0.0;
        while (c < d_w) {
            w_out[c] = w_out[c] * inv_sw;
            c = c + 1.0;
        }
    }
}

// Executes one complete agent cycle: w_in -> x -> g -> w_out
fn conscious_agent_cycle(agent: ConsciousAgent, w_in: ptr, w_out: ptr, ising_steps: float) -> float {
    if (w_in == 0.0 || w_out == 0.0) { return 0.0; }
    let x_buf = agent.x_buf;
    let x_prev = agent.x_prev;
    let g_buf = agent.g_buf;
    let d_x = agent.d_x;

    // Cache prior experience vector x_prev = x_buf before perceptual transition
    var i = 0.0;
    while (i < d_x) {
        x_prev[i] = x_buf[i];
        i = i + 1.0;
    }

    // 1. Perception: W -> X
    conscious_agent_perceive(agent, w_in, x_buf);

    // 2. Decision via Ising Dynamics: X -> G
    let f_energy = conscious_agent_decide_ising(agent, x_buf, g_buf, ising_steps);

    // 3. Action: G -> W
    conscious_agent_act(agent, g_buf, w_out);

    return f_energy;
}

// Computes non-Euclidean spherical Bhattacharyya distance between current and prior experience (Experiential Change over Time)
fn conscious_agent_experiential_change(agent: ConsciousAgent) -> float {
    let d_x = agent.d_x;
    return markov_bhattacharyya_distance(agent.x_buf, agent.x_prev, d_x);
}

// Computes Shannon entropy H(X) = -sum x_i * ln(x_i) measuring breadth vs sharpness of conscious experience
fn conscious_agent_experiential_entropy(agent: ConsciousAgent) -> float {
    let d_x = agent.d_x;
    let x_buf = agent.x_buf;
    var h = 0.0;
    var i = 0.0;
    while (i < d_x) {
        let p = x_buf[i];
        if (p > 0.000001) {
            h = h - (p * log(p));
        }
        i = i + 1.0;
    }
    return h;
}

// Identifies the dominant active qualia index in experience space X
fn conscious_agent_dominant_qualia(agent: ConsciousAgent) -> float {
    let d_x = agent.d_x;
    let x_buf = agent.x_buf;
    var max_idx = 0.0;
    var max_val = x_buf[0];
    var i = 1.0;
    while (i < d_x) {
        if (x_buf[i] > max_val) {
            max_val = x_buf[i];
            max_idx = i;
        }
        i = i + 1.0;
    }
    return max_idx;
}

// Measures intensity (probability salience) of dominant qualia
fn conscious_agent_dominant_qualia_intensity(agent: ConsciousAgent) -> float {
    let d_x = agent.d_x;
    let x_buf = agent.x_buf;
    var max_val = x_buf[0];
    var i = 1.0;
    while (i < d_x) {
        if (x_buf[i] > max_val) {
            max_val = x_buf[i];
        }
        i = i + 1.0;
    }
    return max_val;
}

// Updates Decision matrix D based on empirical empirical correlation between x_buf and g_buf
fn conscious_agent_update_decision_kernel(agent: ConsciousAgent, lr: float) {
    if (lr <= 0.0) { return; }
    let d_x = agent.d_x;
    let d_g = agent.d_g;
    let d_w = agent.d_w;
    let D = agent.D;
    let x_buf = agent.x_buf;
    let g_buf = agent.g_buf;

    // Hebbian association on simplex: D_new = (1 - lr) * D + lr * (x^T * g)
    var r = 0.0;
    while (r < d_x) {
        let r_offset = r * d_g;
        var c = 0.0;
        var row_sum = 0.0;
        while (c < d_g) {
            let update = x_buf[r] * g_buf[c];
            let new_val = D[r_offset + c] * (1.0 - lr) + update * lr;
            D[r_offset + c] = new_val;
            row_sum = row_sum + new_val;
            c = c + 1.0;
        }
        if (row_sum > 0.0) {
            let inv_rs = 1.0 / row_sum;
            c = 0.0;
            while (c < d_g) {
                D[r_offset + c] = D[r_offset + c] * inv_rs;
                c = c + 1.0;
            }
        }
        r = r + 1.0;
    }

    // Recompute composite operator T = P * D * A
    let P = agent.P;
    let A = agent.A;
    let T_comp = agent.T_composite;
    let pi_stat = agent.pi_stationary;

    let PD_temp = tensor_alloc(d_w * d_g);
    markov_matrix_mult(P, D, PD_temp, d_w, d_x, d_g);
    markov_matrix_mult(PD_temp, A, T_comp, d_w, d_g, d_w);
    free(PD_temp);

    // Update stationary distribution
    markov_stationary_distribution(T_comp, pi_stat, d_w, 20.0);
}

// Executes an interaction step between two mutually coupled conscious agents (W1 = X2, W2 = X1)
fn conscious_network_step(agent1: ConsciousAgent, agent2: ConsciousAgent, w1: ptr, w2: ptr, w1_next: ptr, w2_next: ptr, ising_steps: float, lr: float) -> float {
    // Agent 1 processes input from Agent 2's world state (w2)
    let F1 = conscious_agent_cycle(agent1, w2, w1_next, ising_steps);
    // Agent 2 processes input from Agent 1's world state (w1)
    let F2 = conscious_agent_cycle(agent2, w1, w2_next, ising_steps);

    // Update decision kernels
    if (lr > 0.0) {
        conscious_agent_update_decision_kernel(agent1, lr);
        conscious_agent_update_decision_kernel(agent2, lr);
    }
    return (F1 + F2) * 0.5;
}

// Releases all allocated buffers belonging to a Conscious Agent
fn conscious_agent_free(agent: ConsciousAgent) {
    free(agent.P);
    free(agent.D);
    free(agent.A);
    free(agent.T_composite);
    free(agent.pi_stationary);
    free(agent.L_P);
    free(agent.L_A);
    free(agent.spins);
    free(agent.J_matrix);
    free(agent.h_bias);
    free(agent.W_xg);
    free(agent.x_buf);
    free(agent.x_prev);
    free(agent.g_buf);
    free(agent);
}

// Serializes a rich Hoffman Conscious Realism telemetry entry to structured JSONL log
fn conscious_telemetry_log_step(log_file: string, step: float, tau: float, q_id: float, q_int: float, h_x: float, delta_x: float, f_energy: float, x_pos: float, y_pos: float, z_pos: float) {
    var line = "{\"step\": ";
    line = cartan_string_concat(line, cartan_float_to_string(step));
    line = cartan_string_concat(line, ", \"time_arrow_tau\": ");
    line = cartan_string_concat(line, cartan_float_to_string(tau));
    line = cartan_string_concat(line, ", \"active_qualia_id\": ");
    line = cartan_string_concat(line, cartan_float_to_string(q_id));
    line = cartan_string_concat(line, ", \"qualia_intensity\": ");
    line = cartan_string_concat(line, cartan_float_to_string(q_int));
    line = cartan_string_concat(line, ", \"experiential_entropy_hx\": ");
    line = cartan_string_concat(line, cartan_float_to_string(h_x));
    line = cartan_string_concat(line, ", \"experiential_change_delta_x\": ");
    line = cartan_string_concat(line, cartan_float_to_string(delta_x));
    line = cartan_string_concat(line, ", \"ising_free_energy\": ");
    line = cartan_string_concat(line, cartan_float_to_string(f_energy));
    line = cartan_string_concat(line, ", \"headset_interface_3d\": [");
    line = cartan_string_concat(line, cartan_float_to_string(x_pos));
    line = cartan_string_concat(line, ", ");
    line = cartan_string_concat(line, cartan_float_to_string(y_pos));
    line = cartan_string_concat(line, ", ");
    line = cartan_string_concat(line, cartan_float_to_string(z_pos));
    line = cartan_string_concat(line, "]}\n");
    cartan_append_file(log_file, line);
}
