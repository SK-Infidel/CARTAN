# tools/eval_analogy_benchmark.py
# Automated Empirical Analogy Benchmark & Geometric Gap Telemetry Engine
# Evaluates 262,144-vocabulary embeddings across multiple non-Euclidean representations
# Operating strictly with ZERO expert priming, ZERO mocks, and real PyTorch/NumPy tensor ops.

import os
import sys
import json
import math
import time
import numpy as np
import torch
from safetensors import safe_open
from tokenizers import Tokenizer

def load_canonical_benchmark():
    benchmark_path = "test/geomind/trainingdata/analogy_benchmark.json"
    if not os.path.exists(benchmark_path):
        print(f"[ERROR] Benchmark dataset not found at {benchmark_path}")
        sys.exit(1)
    with open(benchmark_path, "r", encoding="utf-8") as f:
        return json.load(f)

def run_benchmark():
    sys.stdout.reconfigure(encoding='utf-8')
    print("=" * 80)
    print("  GEOMIND MANIFOLD ANALOGY BENCHMARK & GAP TELEMETRY ENGINE")
    print("  Strict Zero-Expert Priming | Full 262,144 Candidate Vocabulary")
    print("=" * 80)

    dataset = load_canonical_benchmark()
    total_queries = sum(len(pairs) for pairs in dataset.values())
    print(f"\n[Dataset] Loaded {total_queries} canonical quadruplets across {len(dataset)} categories:")
    for cat, pairs in dataset.items():
        print(f"  - {cat:20}: {len(pairs)} pairs")

    # Ingest Gemma 2560D embeddings
    sf_path = "cache_google_gemma-4-E4B-it_model.safetensors"
    if not os.path.exists(sf_path):
        print(f"[ERROR] Donor safetensors not found: {sf_path}")
        sys.exit(1)

    print(f"\n[Embeddings] Loading authentic Gemma 2560D weights from {sf_path}...")
    sf = safe_open(sf_path, framework="pt", device="cpu")
    emb_raw = sf.get_tensor("model.language_model.embed_tokens.weight").to(torch.float32)
    vocab_size, hidden_dim = emb_raw.shape
    print(f"  Shape: {vocab_size:,} vocab x {hidden_dim} dim")

    # Dynkin weights for 8 maximal Lie subgroups
    # SO(16)=2.0, E7xSU(2)=3.0, E6xF4=4.0, D8=1.0, A8=5.0, G2xF4=2.5, SU(3)^3=1.5, SO(8)^2=2.0
    dynkin_weights = torch.tensor([2.0, 3.0, 4.0, 1.0, 5.0, 2.5, 1.5, 2.0], dtype=torch.float32)
    
    # -------------------------------------------------------------------------
    # REPRESENTATION PREPARATIONS
    # -------------------------------------------------------------------------
    print("\n[Representations] Pre-computing geometric coordinate spaces...")
    
    # Rep A: Raw Flat Euclidean (Normalized to S^2559)
    emb_A = torch.nn.functional.normalize(emb_raw, p=2, dim=1)
    
    # Rep B: Centered & Normalized (Removing global cone effect)
    mean_vec = emb_raw.mean(dim=0, keepdim=True)
    emb_centered = emb_raw - mean_vec
    emb_B = torch.nn.functional.normalize(emb_centered, p=2, dim=1)

    # Rep C: Killing-Cartan Metric Tensor Weighted Space
    # Slices into 8 Lie streams (320 dims each), scales by sqrt(kappa_s)
    emb_C_blocks = []
    for s in range(8):
        block = emb_centered[:, s*320:(s+1)*320]
        block_weighted = block * math.sqrt(dynkin_weights[s].item())
        emb_C_blocks.append(block_weighted)
    emb_C_tensor = torch.cat(emb_C_blocks, dim=1)
    emb_C = torch.nn.functional.normalize(emb_C_tensor, p=2, dim=1)

    representations = [
        ("A: Flat Euclidean (Normalized S^2559)", emb_A, False),
        ("B: Centered Manifold (Cone Purged)", emb_B, False),
        ("C: Killing-Cartan Dynkin Manifold (S_G^2559)", emb_C, False),
        ("D: Riemannian Geodesic Parallel Transport", emb_B, True)
    ]

    # -------------------------------------------------------------------------
    # EVALUATION HARNESS
    # -------------------------------------------------------------------------
    results_summary = []

    for rep_name, emb_matrix, use_parallel_transport in representations:
        print("\n" + "=" * 80)
        print(f"  EVALUATING: {rep_name}")
        print("=" * 80)

        rep_stats = {
            "name": rep_name,
            "top1": 0, "top5": 0, "top10": 0, "top50": 0,
            "mrr_sum": 0.0, "margin_sum": 0.0,
            "cat_stats": {}
        }

        start_time = time.time()

        for cat, pairs in dataset.items():
            cat_top1 = 0
            cat_top5 = 0
            cat_mrr = 0.0

            for q in pairs:
                a_id = q["a_id"]
                b_id = q["b_id"]
                c_id = q["c_id"]
                d_id = q["d_id"]

                va = emb_matrix[a_id]
                vb = emb_matrix[b_id]
                vc = emb_matrix[c_id]
                vd = emb_matrix[d_id]

                if not use_parallel_transport:
                    # Standard vector arithmetic: vt = va - vb + vc
                    vt = va - vb + vc
                    vt = torch.nn.functional.normalize(vt.unsqueeze(0), p=2, dim=1)
                else:
                    # Riemannian Logarithmic map: v_b = log_b(a) in T_b M
                    cos_ba = torch.clamp(torch.dot(vb, va), -0.9999, 0.9999)
                    theta_ba = torch.acos(cos_ba)
                    sin_ba = torch.sin(theta_ba)
                    if sin_ba.abs() > 1e-6:
                        log_b_a = (theta_ba / sin_ba) * (va - vb * cos_ba)
                    else:
                        log_b_a = va - vb

                    # Levi-Civita Parallel Transport along geodesic b -> c:
                    cos_bc = torch.clamp(torch.dot(vb, vc), -0.9999, 0.9999)
                    # P_{b->c}(v) = v - (c . v) / (1 + b . c) * (b + c)
                    dot_c_v = torch.dot(vc, log_b_a)
                    denom = 1.0 + cos_bc
                    if denom.abs() > 1e-6:
                        p_v = log_b_a - (dot_c_v / denom) * (vb + vc)
                    else:
                        p_v = log_b_a

                    # Riemannian Exponential map at c: exp_c(p_v)
                    p_norm = torch.norm(p_v)
                    if p_norm > 1e-6:
                        exp_c = vc * torch.cos(p_norm) + (p_v / p_norm) * torch.sin(p_norm)
                    else:
                        exp_c = vc
                    vt = torch.nn.functional.normalize(exp_c.unsqueeze(0), p=2, dim=1)

                # Compute cosine similarities across all 262,144 candidates
                sims = torch.mm(vt, emb_matrix.t()).squeeze(0)

                # Strictly mask query tokens a, b, c from candidate competition
                sims[a_id] = -999.0
                sims[b_id] = -999.0
                sims[c_id] = -999.0

                # Target evaluation
                target_sim = sims[d_id].item()
                # 1-based rank: number of candidates with similarity strictly greater than target + 1
                rank = (sims > target_sim).sum().item() + 1
                reciprocal_rank = 1.0 / rank

                # Margin against best non-target candidate
                sims_ex = sims.clone()
                sims_ex[d_id] = -999.0
                top_runner_up_sim = sims_ex.max().item()
                margin = target_sim - top_runner_up_sim

                if rank == 1:
                    rep_stats["top1"] += 1
                    cat_top1 += 1
                if rank <= 5:
                    rep_stats["top5"] += 1
                    cat_top5 += 1
                if rank <= 10:
                    rep_stats["top10"] += 1
                if rank <= 50:
                    rep_stats["top50"] += 1

                rep_stats["mrr_sum"] += reciprocal_rank
                rep_stats["margin_sum"] += margin
                cat_mrr += reciprocal_rank

            cat_n = len(pairs)
            rep_stats["cat_stats"][cat] = {
                "top1_acc": (cat_top1 / cat_n) * 100.0,
                "top5_acc": (cat_top5 / cat_n) * 100.0,
                "mrr": cat_mrr / cat_n
            }
            print(f"  [{cat:15}] Top-1: {cat_top1}/{cat_n} ({(cat_top1/cat_n)*100:.1f}%) | Top-5: {cat_top5}/{cat_n} ({(cat_top5/cat_n)*100:.1f}%) | MRR: {cat_mrr/cat_n:.4f}")

        elapsed = time.time() - start_time
        rep_stats["elapsed"] = elapsed
        rep_stats["mrr"] = rep_stats["mrr_sum"] / total_queries
        rep_stats["top1_pct"] = (rep_stats["top1"] / total_queries) * 100.0
        rep_stats["top5_pct"] = (rep_stats["top5"] / total_queries) * 100.0
        rep_stats["top10_pct"] = (rep_stats["top10"] / total_queries) * 100.0
        rep_stats["top50_pct"] = (rep_stats["top50"] / total_queries) * 100.0
        rep_stats["avg_margin"] = rep_stats["margin_sum"] / total_queries

        print("-" * 80)
        print(f"  Summary for {rep_name}:")
        print(f"    Top-1 Accuracy: {rep_stats['top1']}/{total_queries} ({rep_stats['top1_pct']:.2f}%)")
        print(f"    Top-5 Accuracy: {rep_stats['top5']}/{total_queries} ({rep_stats['top5_pct']:.2f}%)")
        print(f"    Top-10 Accuracy: {rep_stats['top10']}/{total_queries} ({rep_stats['top10_pct']:.2f}%)")
        print(f"    Top-50 Accuracy: {rep_stats['top50']}/{total_queries} ({rep_stats['top50_pct']:.2f}%)")
        print(f"    Mean Reciprocal Rank (MRR): {rep_stats['mrr']:.4f}")
        print(f"    Average Cosine Margin:      {rep_stats['avg_margin']:+.4f}")
        print(f"    Evaluation Latency:         {elapsed:.2f}s ({elapsed/total_queries*1000:.1f} ms/query)")

        results_summary.append(rep_stats)

    # -------------------------------------------------------------------------
    # COMPARATIVE TELEMETRY TABLE
    # -------------------------------------------------------------------------
    print("\n" + "=" * 80)
    print("  EMPIRICAL COMPARATIVE TELEMETRY: MINDING THE GEOMETRIC GAP")
    print("=" * 80)
    print(f"{'Representation':45} | {'Top-1':8} | {'Top-5':8} | {'Top-10':8} | {'MRR':7} | {'Avg Margin':10}")
    print("-" * 80)
    for r in results_summary:
        print(f"{r['name'][:45]:45} | {r['top1_pct']:6.1f}% | {r['top5_pct']:6.1f}% | {r['top10_pct']:6.1f}% | {r['mrr']:7.4f} | {r['avg_margin']:+10.4f}")
    print("=" * 80)

    # Save telemetry results to disk
    out_json = "test/geomind/trainingdata/analogy_telemetry_results.json"
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(results_summary, f, indent=2)
    print(f"\n[Telemetry] Full benchmark results saved to {out_json}")

if __name__ == "__main__":
    main = run_benchmark
    main()
