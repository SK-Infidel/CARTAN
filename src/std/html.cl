// src/std/html.cl
// CARTAN Standard Library: HTML Parsing, Sanitization, Link Extraction & URL Resolution

include "src/std/string.cl";
include "src/std/prompt_scaffold.cl";

// Decodes common HTML entities to plain UTF-8 / ASCII characters
fn html_decode_entities(text: string) -> string {
    if (text == 0.0) { return ""; }
    var s = cartan_string_replace(text, "&nbsp;", " ");
    s = cartan_string_replace(s, "&quot;", "\"");
    s = cartan_string_replace(s, "&#39;", "'");
    s = cartan_string_replace(s, "&apos;", "'");
    s = cartan_string_replace(s, "&lt;", "<");
    s = cartan_string_replace(s, "&gt;", ">");
    s = cartan_string_replace(s, "&mdash;", "--");
    s = cartan_string_replace(s, "&ndash;", "-");
    s = cartan_string_replace(s, "&amp;", "&");
    return s;
}

// Extracts attribute value from an HTML tag string (handles attr="value" and attr='value')
fn html_extract_attribute(tag: string, attr_name: string) -> string {
    if (tag == 0.0 || attr_name == 0.0) { return ""; }
    let target_dq = cartan_string_concat(attr_name, "=\"");
    let pos_dq = string_index_of_offset_ignore_case(tag, target_dq, 0.0);
    if (pos_dq >= 0.0) {
        let v_start = pos_dq + cartan_string_length(target_dq);
        let q_pos = string_index_of_offset_ignore_case(tag, "\"", v_start);
        if (q_pos > v_start) {
            return cartan_string_substring(tag, v_start, q_pos);
        }
    }
    let target_sq = cartan_string_concat(attr_name, "='");
    let pos_sq = string_index_of_offset_ignore_case(tag, target_sq, 0.0);
    if (pos_sq >= 0.0) {
        let v_start_sq = pos_sq + cartan_string_length(target_sq);
        let q_pos_sq = string_index_of_offset_ignore_case(tag, "'", v_start_sq);
        if (q_pos_sq > v_start_sq) {
            return cartan_string_substring(tag, v_start_sq, q_pos_sq);
        }
    }
    return "";
}

// Case-insensitively excises subtree blocks (<script>...</script>, <style>...</style>, etc.)
fn html_remove_tag_block(html: string, open_tag: string, close_tag: string) -> string {
    if (html == 0.0) { return ""; }
    var cur = html;
    var pos = string_index_of_offset_ignore_case(cur, open_tag, 0.0);
    var guard = 0.0;
    while (pos >= 0.0 && guard < 100.0) {
        let close_pos = string_index_of_offset_ignore_case(cur, close_tag, pos);
        if (close_pos >= 0.0) {
            let end_idx = close_pos + cartan_string_length(close_tag);
            let s_pre = cartan_string_substring(cur, 0.0, pos);
            let s_post = cartan_string_substring(cur, end_idx, cartan_string_length(cur));
            cur = cartan_string_concat(s_pre, s_post);
            pos = string_index_of_offset_ignore_case(cur, open_tag, pos);
        } else {
            break;
        }
        guard = guard + 1.0;
    }
    return cur;
}

// Extracts and entity-decodes text within the <title>...</title> tag
fn html_extract_title(html: string) -> string {
    if (html == 0.0) { return ""; }
    let t_open = string_index_of_offset_ignore_case(html, "<title>", 0.0);
    if (t_open >= 0.0) {
        let t_close = string_index_of_offset_ignore_case(html, "</title>", t_open);
        if (t_close > t_open + 7.0) {
            let raw_t = cartan_string_substring(html, t_open + 7.0, t_close);
            return html_decode_entities(raw_t);
        }
    }
    return "";
}

// Strips all HTML markup tags using span slicing while injecting line breaks on block boundaries
fn html_strip_tags(html: string) -> string {
    if (html == 0.0) { return ""; }
    let len = cartan_string_length(html);
    let scaffold = prompt_scaffold_create(len + 1024.0);
    var i = 0.0;
    while (i < len) {
        let next_lt = string_index_of_offset_ignore_case(html, "<", i);
        if (next_lt < 0.0) {
            let rem_span = cartan_string_substring(html, i, len);
            prompt_scaffold_append(scaffold, rem_span);
            break;
        }
        if (next_lt > i) {
            let text_span = cartan_string_substring(html, i, next_lt);
            prompt_scaffold_append(scaffold, text_span);
        }
        let next_gt = string_index_of_offset_ignore_case(html, ">", next_lt);
        if (next_gt < 0.0) {
            break;
        }
        let tag_content = cartan_string_substring(html, next_lt + 1.0, next_gt);
        if (cartan_string_starts_with(tag_content, "p") == 1.0 ||
            cartan_string_starts_with(tag_content, "/p") == 1.0 ||
            cartan_string_starts_with(tag_content, "div") == 1.0 ||
            cartan_string_starts_with(tag_content, "/div") == 1.0 ||
            cartan_string_starts_with(tag_content, "br") == 1.0 ||
            cartan_string_starts_with(tag_content, "/tr") == 1.0 ||
            cartan_string_starts_with(tag_content, "h1") == 1.0 ||
            cartan_string_starts_with(tag_content, "h2") == 1.0 ||
            cartan_string_starts_with(tag_content, "h3") == 1.0) {
            prompt_scaffold_append(scaffold, "\n");
        } else if (cartan_string_starts_with(tag_content, "li") == 1.0) {
            prompt_scaffold_append(scaffold, "\n* ");
        }
        i = next_gt + 1.0;
    }
    let raw_res = prompt_scaffold_get_text(scaffold);
    let res = cartan_string_concat(raw_res, "");
    prompt_scaffold_free(scaffold);
    return res;
}

// Resolves relative URLs against base URL (protocol, domain, path)
fn url_resolve(base_url: string, link_url: string) -> string {
    if (link_url == 0.0 || cartan_string_length(link_url) == 0.0) { return ""; }
    if (cartan_string_starts_with(link_url, "http://") == 1.0 ||
        cartan_string_starts_with(link_url, "https://") == 1.0) {
        return link_url;
    }
    if (cartan_string_starts_with(link_url, "//") == 1.0) {
        return cartan_string_concat("https:", link_url);
    }
    var origin = base_url;
    let proto_idx = string_index_of_offset_ignore_case(base_url, "://", 0.0);
    if (proto_idx >= 0.0) {
        let slash_after = string_index_of_offset_ignore_case(base_url, "/", proto_idx + 3.0);
        if (slash_after >= 0.0) {
            origin = cartan_string_substring(base_url, 0.0, slash_after);
        }
    }
    if (cartan_string_starts_with(link_url, "/") == 1.0) {
        return cartan_string_concat(origin, link_url);
    }
    var dir_base = origin;
    let b_len = cartan_string_length(base_url);
    var last_slash = -1.0;
    var bi = b_len - 1.0;
    while (bi >= 0.0) {
        if (cartan_string_get_char(base_url, bi) == 47.0) {
            last_slash = bi;
            break;
        }
        bi = bi - 1.0;
    }
    if (last_slash > proto_idx + 2.0) {
        dir_base = cartan_string_substring(base_url, 0.0, last_slash + 1.0);
    } else {
        dir_base = cartan_string_concat(origin, "/");
    }
    return cartan_string_concat(dir_base, link_url);
}

// SSRF target checker: blocks loopback, link-local, and private RFC-1918 IPv4/IPv6 ranges
fn url_is_ssrf_blacklisted(url: string) -> float {
    if (url == 0.0 || cartan_string_length(url) == 0.0) { return 1.0; }
    var host = url;
    let proto_idx = string_index_of_offset_ignore_case(url, "://", 0.0);
    if (proto_idx >= 0.0) {
        let host_start = proto_idx + 3.0;
        var host_end = string_index_of_offset_ignore_case(url, "/", host_start);
        if (host_end < 0.0) {
            host_end = string_index_of_offset_ignore_case(url, "?", host_start);
        }
        if (host_end < 0.0) {
            host_end = string_index_of_offset_ignore_case(url, "#", host_start);
        }
        if (host_end >= 0.0) {
            host = cartan_string_substring(url, host_start, host_end);
        } else {
            host = cartan_string_substring(url, host_start, cartan_string_length(url));
        }
    }
    let colon_idx = string_index_of_offset_ignore_case(host, ":", 0.0);
    if (colon_idx >= 0.0 && cartan_string_starts_with(host, "[") == 0.0) {
        host = cartan_string_substring(host, 0.0, colon_idx);
    }

    if (cartan_string_contains(host, "localhost") == 1.0 ||
        cartan_string_starts_with(host, "127.") == 1.0 ||
        cartan_string_starts_with(host, "0.0.0.0") == 1.0 ||
        cartan_string_contains(host, "[::1]") == 1.0 ||
        cartan_string_starts_with(host, "10.") == 1.0 ||
        cartan_string_starts_with(host, "192.168.") == 1.0 ||
        cartan_string_starts_with(host, "169.254.") == 1.0 ||
        cartan_string_starts_with(host, "172.16.") == 1.0 ||
        cartan_string_starts_with(host, "172.17.") == 1.0 ||
        cartan_string_starts_with(host, "172.18.") == 1.0 ||
        cartan_string_starts_with(host, "172.19.") == 1.0 ||
        cartan_string_starts_with(host, "172.20.") == 1.0 ||
        cartan_string_starts_with(host, "172.21.") == 1.0 ||
        cartan_string_starts_with(host, "172.22.") == 1.0 ||
        cartan_string_starts_with(host, "172.23.") == 1.0 ||
        cartan_string_starts_with(host, "172.24.") == 1.0 ||
        cartan_string_starts_with(host, "172.25.") == 1.0 ||
        cartan_string_starts_with(host, "172.26.") == 1.0 ||
        cartan_string_starts_with(host, "172.27.") == 1.0 ||
        cartan_string_starts_with(host, "172.28.") == 1.0 ||
        cartan_string_starts_with(host, "172.29.") == 1.0 ||
        cartan_string_starts_with(host, "172.30.") == 1.0 ||
        cartan_string_starts_with(host, "172.31.") == 1.0) {
        return 1.0;
    }
    return 0.0;
}

// Extracts <a href="..."> links from HTML and formats an enumerated followable link registry
fn html_extract_links(html: string, base_url: string, max_links: float) -> string {
    if (html == 0.0) { return ""; }
    var links_out = "";
    var count = 0.0;
    var pos = string_index_of_offset_ignore_case(html, "<a ", 0.0);
    let len = cartan_string_length(html);
    while (pos >= 0.0 && pos < len && count < max_links) {
        let a_close = string_index_of_offset_ignore_case(html, "</a>", pos);
        if (a_close < 0.0) { break; }
        let a_tag_end = string_index_of_offset_ignore_case(html, ">", pos);
        if (a_tag_end > pos && a_tag_end < a_close) {
            let a_header = cartan_string_substring(html, pos, a_tag_end);
            var href = html_extract_attribute(a_header, "href");
            if (cartan_string_length(href) > 0.0 &&
                cartan_string_starts_with(href, "#") == 0.0 &&
                cartan_string_starts_with(href, "javascript:") == 0.0 &&
                cartan_string_starts_with(href, "mailto:") == 0.0) {
                let inner_raw = cartan_string_substring(html, a_tag_end + 1.0, a_close);
                let inner_clean = html_strip_tags(inner_raw);
                var label = html_decode_entities(inner_clean);
                if (cartan_string_length(label) == 0.0) {
                    label = href;
                }
                if (cartan_string_length(label) > 60.0) {
                    label = cartan_string_substring(label, 0.0, 60.0);
                }
                let resolved = url_resolve(base_url, href);
                count = count + 1.0;
                var line = "  [";
                line = cartan_string_concat(line, cartan_float_to_string(count));
                line = cartan_string_concat(line, "] ");
                line = cartan_string_concat(line, label);
                line = cartan_string_concat(line, " -> ");
                line = cartan_string_concat(line, resolved);
                line = cartan_string_concat(line, "\n");
                links_out = cartan_string_concat(links_out, line);
            }
        }
        pos = string_index_of_offset_ignore_case(html, "<a ", a_close + 4.0);
    }
    return links_out;
}
