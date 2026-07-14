use crate::token::{Token, TokenType, Span};
use crate::error::Diagnostic;
use std::collections::HashMap;

pub struct Lexer {
    source: Vec<char>,
    current: usize,
    line: usize,
    col: usize,
    keywords: HashMap<String, TokenType>,
}

impl Lexer {
    pub fn new(source: &str) -> Self {
        let mut keywords = HashMap::new();
        keywords.insert("fn".to_string(), TokenType::Fn);
        keywords.insert("extern".to_string(), TokenType::Extern);
        keywords.insert("let".to_string(), TokenType::Let);
        keywords.insert("var".to_string(), TokenType::Var);
        keywords.insert("const".to_string(), TokenType::Const);
        keywords.insert("struct".to_string(), TokenType::Struct);
        keywords.insert("stream".to_string(), TokenType::Stream);
        keywords.insert("sequence".to_string(), TokenType::Sequence);
        keywords.insert("block".to_string(), TokenType::Block);
        keywords.insert("tensor".to_string(), TokenType::Tensor);
        keywords.insert("parameter".to_string(), TokenType::Parameter);
        keywords.insert("layout".to_string(), TokenType::Layout);
        keywords.insert("manifold".to_string(), TokenType::Manifold);
        keywords.insert("topology".to_string(), TokenType::Topology);
        keywords.insert("mut".to_string(), TokenType::Mut);
        keywords.insert("if".to_string(), TokenType::If);
        keywords.insert("match".to_string(), TokenType::Match);
        keywords.insert("else".to_string(), TokenType::Else);
        keywords.insert("while".to_string(), TokenType::While);
        keywords.insert("for".to_string(), TokenType::For);
        keywords.insert("return".to_string(), TokenType::Return);
        keywords.insert("break".to_string(), TokenType::Break);
        keywords.insert("continue".to_string(), TokenType::Continue);
        keywords.insert("try".to_string(), TokenType::Try);
        keywords.insert("catch".to_string(), TokenType::Catch);
        keywords.insert("throw".to_string(), TokenType::Throw);
        keywords.insert("import".to_string(), TokenType::Import);
        keywords.insert("in".to_string(), TokenType::In);
        keywords.insert("backward".to_string(), TokenType::Backward);
        keywords.insert("async_compute".to_string(), TokenType::AsyncCompute);
        keywords.insert("SievingCache".to_string(), TokenType::SievingCache);
        keywords.insert("FractalAttentionBlock".to_string(), TokenType::FractalAttentionBlock);
        keywords.insert("ElasticVocabulary".to_string(), TokenType::ElasticVocabulary);
        keywords.insert("emit".to_string(), TokenType::Emit);
        keywords.insert("spike".to_string(), TokenType::Spike);
        keywords.insert("neuron".to_string(), TokenType::Neuron);
        keywords.insert("under".to_string(), TokenType::Under);
        keywords.insert("absorb_layer_weights".to_string(), TokenType::AbsorbLayerWeights);
        keywords.insert("project_vocab".to_string(), TokenType::ProjectVocab);
        keywords.insert("fluid".to_string(), TokenType::Fluid);
        keywords.insert("with".to_string(), TokenType::With);
        keywords.insert("sparsity".to_string(), TokenType::Sparsity);
        keywords.insert("true".to_string(), TokenType::BoolLiteral(true));
        keywords.insert("false".to_string(), TokenType::BoolLiteral(false));

        Self {
            source: source.chars().collect(),
            current: 0,
            line: 1,
            col: 1,
            keywords,
        }
    }

    fn peek(&self) -> Option<char> {
        self.source.get(self.current).copied()
    }
    
    fn peek_next(&self) -> Option<char> {
        self.source.get(self.current + 1).copied()
    }

    fn advance(&mut self) -> Option<char> {
        let c = self.peek();
        if let Some(ch) = c {
            self.current += 1;
            if ch == '\n' {
                self.line += 1;
                self.col = 1;
            } else {
                self.col += 1;
            }
        }
        c
    }

    fn match_char(&mut self, expected: char) -> bool {
        if self.peek() == Some(expected) {
            self.advance();
            true
        } else {
            false
        }
    }

    pub fn tokenize(&mut self) -> Result<Vec<Token>, Diagnostic> {
        let mut tokens = Vec::new();

        while let Some(c) = self.peek() {
            let start_col = self.col;
            let start_line = self.line;

            match c {
                ' ' | '\r' | '\t' | '\n' | '\u{FEFF}' => { self.advance(); }
                '@' => {
                    self.advance();
                    let mut ident = String::new();
                    while let Some(ch) = self.peek() {
                        if ch.is_ascii_alphabetic() || ch == '_' {
                            ident.push(ch);
                            self.advance();
                        } else {
                            break;
                        }
                    }
                    
                    if ident == "location" {
                        tokens.push(Token { token_type: TokenType::AtLocation, lexeme: "@location".to_string(), span: Span::new(start_line, start_col, self.col) });
                    } else if ident == "backend" {
                        tokens.push(Token { token_type: TokenType::AtBackend, lexeme: "@backend".to_string(), span: Span::new(start_line, start_col, self.col) });
                    } else if ident == "attention" {
                        tokens.push(Token { token_type: TokenType::Attention, lexeme: "@attention".to_string(), span: Span::new(start_line, start_col, self.col) });
                    } else if ident == "agent_accessible" {
                        tokens.push(Token { token_type: TokenType::AgentAccessible, lexeme: "@agent_accessible".to_string(), span: Span::new(start_line, start_col, self.col) });
                    } else if ident.is_empty() {
                        tokens.push(Token { token_type: TokenType::MatMul, lexeme: "@".to_string(), span: Span::new(start_line, start_col, self.col) });
                    } else {
                        return Err(Diagnostic::error(
                            &format!("Unknown decorator: @{}", ident),
                            Span::new(start_line, start_col, self.col)
                        ));
                    }
                }
                '/' => {
                    if self.peek_next() == Some('/') {
                        while self.peek().is_some() && self.peek() != Some('\n') {
                            self.advance();
                        }
                    } else if self.match_char('=') {
                        tokens.push(Token { token_type: TokenType::SlashEq, lexeme: "/=".to_string(), span: Span::new(start_line, start_col, self.col) });
                    } else {
                        self.advance();
                        tokens.push(Token { token_type: TokenType::Slash, lexeme: "/".to_string(), span: Span::new(start_line, start_col, self.col) });
                    }
                }
                '+' => {
                    self.advance();
                    if self.match_char('=') { tokens.push(Token { token_type: TokenType::PlusEq, lexeme: "+=".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else { tokens.push(Token { token_type: TokenType::Plus, lexeme: "+".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                }
                '-' => {
                    self.advance();
                    if self.match_char('=') { tokens.push(Token { token_type: TokenType::MinusEq, lexeme: "-=".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else if self.match_char('>') { tokens.push(Token { token_type: TokenType::Arrow, lexeme: "->".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else { tokens.push(Token { token_type: TokenType::Minus, lexeme: "-".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                }
                '*' => {
                    self.advance();
                    if self.match_char('=') { tokens.push(Token { token_type: TokenType::StarEq, lexeme: "*=".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else { tokens.push(Token { token_type: TokenType::Star, lexeme: "*".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                }
                '=' => {
                    self.advance();
                    if self.match_char('=') { tokens.push(Token { token_type: TokenType::EqEq, lexeme: "==".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else if self.match_char('>') { tokens.push(Token { token_type: TokenType::FatArrow, lexeme: "=>".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else { tokens.push(Token { token_type: TokenType::Eq, lexeme: "=".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                }
                '!' => {
                    self.advance();
                    if self.match_char('=') { tokens.push(Token { token_type: TokenType::NotEq, lexeme: "!=".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else { tokens.push(Token { token_type: TokenType::Not, lexeme: "!".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                }
                '<' => {
                    self.advance();
                    if self.match_char('=') { tokens.push(Token { token_type: TokenType::LessEq, lexeme: "<=".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else if self.match_char('<') {
                        if self.match_char('=') { tokens.push(Token { token_type: TokenType::ShiftLeftEq, lexeme: "<<=".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                        else { tokens.push(Token { token_type: TokenType::ShiftLeft, lexeme: "<<".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    }
                    else { tokens.push(Token { token_type: TokenType::Less, lexeme: "<".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                }
                '>' => {
                    self.advance();
                    if self.match_char('=') { tokens.push(Token { token_type: TokenType::GreaterEq, lexeme: ">=".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else if self.match_char('>') {
                        if self.match_char('=') { tokens.push(Token { token_type: TokenType::ShiftRightEq, lexeme: ">>=".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                        else { tokens.push(Token { token_type: TokenType::ShiftRight, lexeme: ">>".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    }
                    else { tokens.push(Token { token_type: TokenType::Greater, lexeme: ">".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                }
                '&' => {
                    self.advance();
                    if self.match_char('&') { tokens.push(Token { token_type: TokenType::And, lexeme: "&&".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else if self.match_char('=') { tokens.push(Token { token_type: TokenType::AmpersandEq, lexeme: "&=".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else { tokens.push(Token { token_type: TokenType::Ampersand, lexeme: "&".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                }
                '|' => {
                    self.advance();
                    if self.match_char('|') { tokens.push(Token { token_type: TokenType::Or, lexeme: "||".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else if self.match_char('=') { tokens.push(Token { token_type: TokenType::PipeEq, lexeme: "|=".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else { tokens.push(Token { token_type: TokenType::Pipe, lexeme: "|".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                }
                '^' => {
                    self.advance();
                    if self.match_char('=') { tokens.push(Token { token_type: TokenType::CaretEq, lexeme: "^=".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                    else { tokens.push(Token { token_type: TokenType::Caret, lexeme: "^".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                }
                '(' => { self.advance(); tokens.push(Token { token_type: TokenType::LParen, lexeme: "(".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                ')' => { self.advance(); tokens.push(Token { token_type: TokenType::RParen, lexeme: ")".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                '{' => { self.advance(); tokens.push(Token { token_type: TokenType::LBrace, lexeme: "{".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                '}' => { self.advance(); tokens.push(Token { token_type: TokenType::RBrace, lexeme: "}".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                '[' => { self.advance(); tokens.push(Token { token_type: TokenType::LBracket, lexeme: "[".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                ']' => { self.advance(); tokens.push(Token { token_type: TokenType::RBracket, lexeme: "]".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                ',' => { self.advance(); tokens.push(Token { token_type: TokenType::Comma, lexeme: ",".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                ';' => { self.advance(); tokens.push(Token { token_type: TokenType::Semicolon, lexeme: ";".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                ':' => { self.advance(); tokens.push(Token { token_type: TokenType::Colon, lexeme: ":".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                '.' => { self.advance(); tokens.push(Token { token_type: TokenType::Dot, lexeme: ".".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                '#' => { self.advance(); tokens.push(Token { token_type: TokenType::Hash, lexeme: "#".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                '"' => {
                    self.advance(); // skip quote
                    let mut string_val = String::new();
                    while let Some(ch) = self.peek() {
                        if ch == '"' { break; }
                        string_val.push(ch);
                        self.advance();
                    }
                    if self.peek().is_none() {
                        return Err(Diagnostic::error("Unterminated string literal", Span::new(start_line, start_col, self.col)));
                    }
                    self.advance(); // skip closing quote
                    tokens.push(Token { token_type: TokenType::StringLiteral(string_val.clone()), lexeme: format!("\"{}\"", string_val), span: Span::new(start_line, start_col, self.col) });
                }
                c if c.is_ascii_digit() => {
                    let mut num_str = String::new();
                    while let Some(ch) = self.peek() {
                        if ch.is_ascii_digit() {
                            num_str.push(ch);
                            self.advance();
                        } else {
                            break;
                        }
                    }
                    if self.peek() == Some('.') {
                        num_str.push('.');
                        self.advance();
                        while let Some(ch) = self.peek() {
                            if ch.is_ascii_digit() {
                                num_str.push(ch);
                                self.advance();
                            } else {
                                break;
                            }
                        }
                        tokens.push(Token { token_type: TokenType::FloatLiteral(num_str.parse().unwrap()), lexeme: num_str, span: Span::new(start_line, start_col, self.col) });
                    } else {
                        tokens.push(Token { token_type: TokenType::IntLiteral(num_str.parse().unwrap()), lexeme: num_str, span: Span::new(start_line, start_col, self.col) });
                    }
                }
                c if c.is_ascii_alphabetic() || c == '_' => {
                    let mut ident = String::new();
                    while let Some(ch) = self.peek() {
                        if ch.is_ascii_alphanumeric() || ch == '_' {
                            ident.push(ch);
                            self.advance();
                        } else {
                            break;
                        }
                    }
                    if let Some(t_type) = self.keywords.get(&ident) {
                        tokens.push(Token { token_type: t_type.clone(), lexeme: ident, span: Span::new(start_line, start_col, self.col) });
                    } else {
                        tokens.push(Token { token_type: TokenType::Identifier(ident.clone()), lexeme: ident, span: Span::new(start_line, start_col, self.col) });
                    }
                }
                _ => {
                    return Err(Diagnostic::error(
                        &format!("Unexpected character: {}", c),
                        Span::new(start_line, start_col, self.col)
                    ));
                }
            }
        }
        
        tokens.push(Token { token_type: TokenType::EOF, lexeme: "".to_string(), span: Span::new(self.line, self.col, self.col) });
        Ok(tokens)
    }
}
