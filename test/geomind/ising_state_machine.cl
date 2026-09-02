include "../../src/std/physics.cl";
include "../../src/std/collections.cl";


struct IsingState {
    num_spins: float;
    temperature: float;
    spins: ptr;
}

fn geomind_ising_relax(spins: ptr, num_spins: float, temp: float, steps: float) -> ptr {
    if (spins == 0.0) { return spins; }
    var step = 0.0;
    while (step < steps) {
        var i = 0.0;
        while (i < num_spins) {
            let s = cartan_vec_get_f32(spins, i);
            let relaxed_s = hopfield_spin_relax(s, 0.0, temp);
            cartan_vec_set_f32(spins, i, relaxed_s);
            i = i + 1.0;
        }
        step = step + 1.0;
    }
    return spins;
}
