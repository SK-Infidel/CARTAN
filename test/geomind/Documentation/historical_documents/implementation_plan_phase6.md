# Phase 6: Autonomous Metacognition (The "Sleep" Cycle)

This plan covers the implementation of **Phase 6** from the `roadmap.md`. The objective of this phase is to give GeoMind the ability to self-optimize and explore its own $E_8$ geometric coordinate field offline, mimicking biological REM sleep consolidation.

## User Review Required
> [!IMPORTANT]
> This phase introduces autonomous modification (deletion) of records within the `geometry_registry.db`. I strongly recommend we create a backup of the database before executing the `synaptic_pruning` routine for the first time.
> 
> **Question:** Do you approve of introducing `scikit-learn` for the topological clustering algorithms (KMeans/DBSCAN) required for Void Detection?

## Proposed Changes

We will create a new directory `utils/metacognition/` containing the core logic for the Sleep Cycle.

### `utils/metacognition`

#### [NEW] [sleep_cycle.py](file:///c:/Users/rich-/source/repos/GeoMind/utils/metacognition/sleep_cycle.py)
This will be the master script that runs the three phases of GeoMind's metacognition.
1. **`void_detection()`**:
   - Queries all known 248D coordinates from `geometry_registry.db`.
   - Uses `sklearn.cluster.KMeans` (or similar topological analysis) to find centroids of largest geometric voids (areas with low point density).
   - Algorithmically selects a seed URL conceptually related to the boundary concepts of the void, and automatically spawns the `GeometricCrawler` from Phase 5 to fill the gap.
2. **`synaptic_pruning()`**:
   - Constructs a K-Nearest Neighbors (KNN) graph of all concepts natively within the database.
   - Runs the `markov_density.py` PageRank algorithm over this internal graph.
   - Identifies orphaned, disconnected, or near-zero mass noise nodes and executes a SQL `DELETE` to prune them, optimizing structural density.
3. **`geometric_epiphanies()`**:
   - Uses pathfinding (e.g., A* or Dijkstra over the KNN graph) to find unexpectedly short vectors connecting two distantly related sub-disciplines (e.g., a short path bypassing traditional hierarchy to link a concept in Quantum Mechanics directly to a concept in Biology).
   - Formats and logs these discoveries as "epiphanies".

## Verification Plan

### Automated Tests
- I will run `sleep_cycle.py` in a dry-run mode (printing prune targets instead of deleting them) to ensure the PageRank math doesn't accidentally wipe out core WordNet nodes.

### Manual Verification
- I will trigger a single Sleep Cycle.
- We will verify that void detection successfully identifies a missing geometric region and queues a crawler job.
- We will verify that geometric epiphanies outputs logically sound, novel connections.
