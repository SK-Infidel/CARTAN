import os

with open('src/lexer.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_code = '''                '#' => { self.advance(); tokens.push(Token { token_type: TokenType::Hash, lexeme: "#".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                '"' => {'''

new_code = '''                '#' => { self.advance(); tokens.push(Token { token_type: TokenType::Hash, lexeme: "#".to_string(), span: Span::new(start_line, start_col, self.col) }); }
                '$' => {
                    self.advance();
                    let mut placeholder = String::new();
                    while let Some(ch) = self.peek() {
                        if ch.is_ascii_alphanumeric() || ch == '_' {
                            placeholder.push(ch);
                            self.advance();
                        } else {
                            break;
                        }
                    }
                    if placeholder.is_empty() {
                        return Err(Diagnostic::error("Expected identifier after '$'", Span::new(start_line, start_col, self.col)));
                    }
                    tokens.push(Token { token_type: TokenType::Placeholder(placeholder.clone()), lexeme: format!("${}", placeholder), span: Span::new(start_line, start_col, self.col) });
                }
                '"' => {'''

if old_code in code:
    code = code.replace(old_code, new_code)
    print("Added $x parsing to lexer.rs")
else:
    print("Could not find line in lexer.rs")

with open('src/lexer.rs', 'w', encoding='utf-8') as f:
    f.write(code)
