// src/std/reasoning.ch
// CARTAN Standard Library: Absolute Zero Reasoning (AZR) & Verifiable Compiler Reward Header

extern fn azr_framework_propose_task(level: float) -> string;
extern fn azr_framework_solve_task(task_code: string) -> string;
extern fn azr_framework_eval_binary_reward(candidate_code: string) -> float;
extern fn azr_framework_run_selfplay(iterations: float) -> float;
