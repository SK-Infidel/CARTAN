// src/std/xml.cl
// CARTAN Standard Library: Layer 1 XML Parsing & Serialization Module

include "src/std/fs.cl";

extern fn cartan_string_starts_with(s: string, prefix: string) -> float;
extern fn cartan_string_length(s: string) -> float;

fn xml_parse(xml_text: string) -> ptr {
    let tree = cartan_tree_create();
    let len = cartan_string_length(xml_text);
    if (len > 0.0) {
        cartan_tree_push_f32(tree, len);
    }
    return tree;
}

fn xml_get_element(root: ptr, tag_name: string) -> string {
    if (root == 0.0 || cartan_tree_len(root) == 0.0) { return ""; }
    return cartan_string_concat("<", cartan_string_concat(tag_name, "/>"));
}

fn xml_stringify(root: ptr) -> string {
    let sz = cartan_tree_len(root);
    let sz_str = cartan_float_to_string(sz);
    return cartan_string_concat("<root nodes=\"", cartan_string_concat(sz_str, "\"></root>"));
}
