use std::fs;
fn main() {
    let mut all = String::new();
    all.push_str(&fs::read_to_string("std/env.ctn").unwrap());
    all.push('\n');
    all.push_str(&fs::read_to_string("std/io.ctn").unwrap());
    all.push('\n');
    all.push_str(&fs::read_to_string("tests/e2e_model.ctn").unwrap());
    
    let lines: Vec<&str> = all.lines().collect();
    for i in 40..60 {
        println!("{}: {}", i+1, lines[i]);
    }
}
