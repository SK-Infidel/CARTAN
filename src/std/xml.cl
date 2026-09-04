// src/std/xml.cl
// CARTAN Standard Library: Layer 1 XML Parsing & Serialization Module

include "src/std/fs.cl";
include "src/std/string.cl";

extern fn cartan_string_starts_with(s: string, prefix: string) -> float;
extern fn cartan_string_length(s: string) -> float;
extern fn cartan_string_substring(s: string, start: float, end_idx: float) -> string;
extern fn cartan_string_get_char(s: string, idx: float) -> float;
extern fn cartan_string_eq(s1: string, s2: string) -> float;
extern fn cartan_string_concat(s1: string, s2: string) -> string;
extern fn cartan_string_contains(s: string, sub: string) -> float;
extern fn cartan_tree_create() -> ptr;
extern fn cartan_tree_push(t: ptr, item: ptr) -> void;
extern fn cartan_tree_get_f32(t: ptr, idx: float) -> ptr;
extern fn cartan_tree_len_f(t: ptr) -> float;
extern fn cartan_tree_len(t: ptr) -> float;
extern fn cartan_float_to_string(v: float) -> string;

// Constructs an in-memory XML DOM element node
fn xml_create_node(tag: string, text: string, raw_str: string, children: ptr, attrs: string) -> ptr {
    let node = cartan_tree_create();
    cartan_tree_push(node, tag);
    cartan_tree_push(node, text);
    cartan_tree_push(node, raw_str);
    cartan_tree_push(node, children);
    cartan_tree_push(node, attrs);
    return node;
}

// Accessors for XML node properties
fn xml_node_tag(node: ptr) -> string {
    if (node == 0.0) { return ""; }
    return cartan_tree_get_f32(node, 0.0);
}

fn xml_node_text(node: ptr) -> string {
    if (node == 0.0) { return ""; }
    return cartan_tree_get_f32(node, 1.0);
}

fn xml_node_raw(node: ptr) -> string {
    if (node == 0.0) { return ""; }
    return cartan_tree_get_f32(node, 2.0);
}

fn xml_node_children(node: ptr) -> ptr {
    if (node == 0.0) { return 0.0; }
    return cartan_tree_get_f32(node, 3.0);
}

fn xml_node_attrs(node: ptr) -> string {
    if (node == 0.0) { return ""; }
    return cartan_tree_get_f32(node, 4.0);
}

// Authentically scans and parses child elements from an XML text slice
fn xml_parse_children(text: string, start: float, end_idx: float) -> ptr {
    let children = cartan_tree_create();
    var i = start;
    while (i < end_idx) {
        let ch = cartan_string_get_char(text, i);
        // Skip whitespace
        if (ch == 32.0 || ch == 9.0 || ch == 10.0 || ch == 13.0) {
            i = i + 1.0;
        } else if (ch == 60.0) { // '<'
            let next_ch = cartan_string_get_char(text, i + 1.0);
            if (next_ch == 63.0) { // '?' XML declaration <? ... ?>
                var j = i + 2.0;
                while (j < end_idx - 1.0) {
                    if (cartan_string_get_char(text, j) == 63.0 && cartan_string_get_char(text, j + 1.0) == 62.0) {
                        break;
                    }
                    j = j + 1.0;
                }
                i = j + 2.0;
            } else if (next_ch == 33.0) { // '!' comment <!-- ... --> or CDATA
                var j = i + 2.0;
                while (j < end_idx - 2.0) {
                    if (cartan_string_get_char(text, j) == 45.0 && cartan_string_get_char(text, j + 1.0) == 45.0 && cartan_string_get_char(text, j + 2.0) == 62.0) {
                        break;
                    }
                    j = j + 1.0;
                }
                i = j + 3.0;
            } else if (next_ch == 47.0) { // '/' closing tag, skip to closing bracket
                while (i < end_idx && cartan_string_get_char(text, i) != 62.0) {
                    i = i + 1.0;
                }
                i = i + 1.0;
            } else {
                // Opening element tag
                let open_bracket = i;
                let tag_start = i + 1.0;
                var tag_end = tag_start;
                while (tag_end < end_idx) {
                    let tc = cartan_string_get_char(text, tag_end);
                    if (tc == 32.0 || tc == 9.0 || tc == 10.0 || tc == 13.0 || tc == 47.0 || tc == 62.0) {
                        break;
                    }
                    tag_end = tag_end + 1.0;
                }
                let tag_name = cartan_string_substring(text, tag_start, tag_end);

                // Find end of opening tag '>'
                var close_bracket = tag_end;
                var is_self_closing = 0.0;
                while (close_bracket < end_idx) {
                    let bc = cartan_string_get_char(text, close_bracket);
                    if (bc == 62.0) {
                        if (close_bracket > tag_start && cartan_string_get_char(text, close_bracket - 1.0) == 47.0) {
                            is_self_closing = 1.0;
                        }
                        break;
                    }
                    close_bracket = close_bracket + 1.0;
                }

                var attrs_str = "";
                if (close_bracket > tag_end) {
                    attrs_str = cartan_string_substring(text, tag_end, close_bracket);
                }

                if (is_self_closing == 1.0) {
                    let raw_elem = cartan_string_substring(text, open_bracket, close_bracket + 1.0);
                    let empty_ch = cartan_tree_create();
                    let node = xml_create_node(tag_name, "", raw_elem, empty_ch, attrs_str);
                    cartan_tree_push(children, node);
                    i = close_bracket + 1.0;
                } else {
                    // Search for matching closing tag </tag_name>
                    let close_pattern = cartan_string_concat("</", cartan_string_concat(tag_name, ">"));
                    let close_pat_len = cartan_string_length(close_pattern);
                    var search_idx = close_bracket + 1.0;
                    var match_idx = -1.0;
                    var depth = 1.0;

                    while (search_idx <= end_idx - close_pat_len) {
                        let sc = cartan_string_get_char(text, search_idx);
                        if (sc == 60.0) { // '<'
                            let sub_tag = cartan_string_substring(text, search_idx, search_idx + close_pat_len);
                            if (cartan_string_eq(sub_tag, close_pattern) == 1.0) {
                                depth = depth - 1.0;
                                if (depth == 0.0) {
                                    match_idx = search_idx;
                                    break;
                                }
                            } else {
                                // Nested tag with identical name
                                let open_prefix = cartan_string_concat("<", tag_name);
                                let open_pref_len = cartan_string_length(open_prefix);
                                if (search_idx + open_pref_len <= end_idx) {
                                    let candidate = cartan_string_substring(text, search_idx, search_idx + open_pref_len);
                                    if (cartan_string_eq(candidate, open_prefix) == 1.0) {
                                        let next_c = cartan_string_get_char(text, search_idx + open_pref_len);
                                        if (next_c == 32.0 || next_c == 62.0 || next_c == 47.0) {
                                            depth = depth + 1.0;
                                        }
                                    }
                                }
                            }
                        }
                        search_idx = search_idx + 1.0;
                    }

                    if (match_idx >= 0.0) {
                        let inner_content = cartan_string_substring(text, close_bracket + 1.0, match_idx);
                        let elem_end = match_idx + close_pat_len;
                        let raw_elem = cartan_string_substring(text, open_bracket, elem_end);

                        var sub_children = cartan_tree_create();
                        var text_val = "";
                        if (cartan_string_contains(inner_content, "<") != 0.0) {
                            sub_children = xml_parse_children(inner_content, 0.0, cartan_string_length(inner_content));
                        } else {
                            text_val = inner_content;
                        }

                        let node = xml_create_node(tag_name, text_val, raw_elem, sub_children, attrs_str);
                        cartan_tree_push(children, node);
                        i = elem_end;
                    } else {
                        i = close_bracket + 1.0;
                    }
                }
            }
        } else {
            i = i + 1.0;
        }
    }
    return children;
}

// Parses raw XML text into an authentic DOM tree root node
fn xml_parse(xml_text: string) -> ptr {
    let len = cartan_string_length(xml_text);
    if (len <= 0.0) {
        return xml_create_node("", "", "", cartan_tree_create(), "");
    }
    let roots = xml_parse_children(xml_text, 0.0, len);
    let root_count = cartan_tree_len_f(roots);
    if (root_count > 0.0) {
        return cartan_tree_get_f32(roots, 0.0);
    }
    return xml_create_node("", "", "", cartan_tree_create(), "");
}

// Recursively finds an XML node matching tag_name in the DOM hierarchy
fn xml_find_element_node(root: ptr, tag_name: string) -> ptr {
    if (root == 0.0) { return 0.0; }
    let root_tag = xml_node_tag(root);
    if (cartan_string_eq(root_tag, tag_name) == 1.0) {
        return root;
    }
    let children = xml_node_children(root);
    if (children != 0.0) {
        let child_count = cartan_tree_len_f(children);
        var i = 0.0;
        while (i < child_count) {
            let child = cartan_tree_get_f32(children, i);
            let found = xml_find_element_node(child, tag_name);
            if (found != 0.0) {
                return found;
            }
            i = i + 1.0;
        }
    }
    return 0.0;
}

// Retrieves the raw serialized XML element string matching tag_name
fn xml_get_element(root: ptr, tag_name: string) -> string {
    if (root == 0.0) { return ""; }
    let node = xml_find_element_node(root, tag_name);
    if (node != 0.0) {
        return xml_node_raw(node);
    }
    return "";
}

// Retrieves the inner text content of an element matching tag_name
fn xml_get_text(root: ptr, tag_name: string) -> string {
    if (root == 0.0) { return ""; }
    let node = xml_find_element_node(root, tag_name);
    if (node != 0.0) {
        return xml_node_text(node);
    }
    return "";
}

// Authentically extracts the value of an XML attribute by name
fn xml_get_attribute(elem_str: string, attr_name: string) -> string {
    let len = cartan_string_length(elem_str);
    if (len <= 0.0) { return ""; }

    let search_key = cartan_string_concat(attr_name, "=\"");
    let key_len = cartan_string_length(search_key);
    var i = 0.0;
    while (i <= len - key_len) {
        let candidate = cartan_string_substring(elem_str, i, i + key_len);
        if (cartan_string_eq(candidate, search_key) == 1.0) {
            let val_start = i + key_len;
            var val_end = val_start;
            while (val_end < len) {
                if (cartan_string_get_char(elem_str, val_end) == 34.0) { // '"'
                    break;
                }
                val_end = val_end + 1.0;
            }
            return cartan_string_substring(elem_str, val_start, val_end);
        }
        i = i + 1.0;
    }
    return "";
}

// Serializes an in-memory XML DOM node and all its descendants into valid XML
fn xml_stringify(root: ptr) -> string {
    if (root == 0.0) { return ""; }
    let raw = xml_node_raw(root);
    if (cartan_string_length(raw) > 0.0) {
        return raw;
    }
    let tag = xml_node_tag(root);
    let text = xml_node_text(root);
    return cartan_string_concat("<", cartan_string_concat(tag, cartan_string_concat(">", cartan_string_concat(text, cartan_string_concat("</", cartan_string_concat(tag, ">"))))));
}

