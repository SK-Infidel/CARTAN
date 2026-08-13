// src/std/ingest.cl
// CARTAN Standard Library: Layer 1 Web Ingestion & Data Pipeline Module

include "src/std/http.cl";
include "src/std/string.cl";

fn ingest_fetch_url(url: string) -> string {
    return http_get(url);
}

fn ingest_parse_csv_line(line: string) -> float {
    let len = cartan_string_length(line);
    if (len <= 0.0) { return 0.0; }
    return 1.0;
}

fn ingest_parse_json_lines(payload: string) -> float {
    let len = cartan_string_length(payload);
    if (len <= 0.0) { return 0.0; }
    return 1.0;
}
