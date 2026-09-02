// test/geomind/geometry.cl
// GeoMind Production-Grade Lie Group E8 & Riemannian Geometry Engine

include "../../src/std/geom.cl";
include "../../src/std/math.cl";

fn geomind_project_to_e8_lattice(idx: float, dim: float) -> float {
    return geom_e8_root_coordinate(idx, dim);
}
