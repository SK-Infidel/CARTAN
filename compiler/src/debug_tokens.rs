use std::fs;
use crate::lexer::Lexer;

fn main() {
    let src = fs::read_to_string("../tests/e2e_model.ctn").unwrap();
    let mut lexer = Lexer::new(&src);
    let tokens = lexer.tokenize().unwrap();
    for t in tokens {
        if t.span.line >= 40 && t.span.line <= 45 {
            println!("{:?} ", t);
        }
    }
}
