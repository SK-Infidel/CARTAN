// test/geomind/test_azr.cl
// Verification script for Absolute Zero Reasoning (AZR) Self-Play Engine

include "azr_engine.cl";

fn main() -> float {
    printf("[AZR Test] Initializing AZR Self-Play Test Verification...\n");
    let reward = geomind_azr_run_selfplay(3.0);
    printf("[AZR Test] Mean Self-Play Reward: %s\n", cartan_float_to_string(reward));
    static_assert(reward == 1.0, "AZR mean self-play reward must equal 1.0");
    printf("[AZR Test] SUCCESS: All 3 AZR Self-Play Iterations Verified!\n");
    return 0.0;
}
