// src/std/reasoning.ch
// CARTAN Standard Library: Absolute Zero Reasoning (AZR) & Verifiable Compiler Reward Header

extern fn geomind_azr_propose_task(level: float) -> string;
extern fn geomind_azr_solve_task(task_code: string) -> string;
extern fn geomind_azr_eval_reward(candidate_code: string) -> float;
extern fn geomind_azr_run_selfplay(iterations: float) -> float;
