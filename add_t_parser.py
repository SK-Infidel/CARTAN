import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

dot_logic = '''              } else if self.match_token(&[TokenType::Dot]) {
                  let name = match self.consume(TokenType::Identifier("".to_string()), "Expected property name after '.'")?.token_type.clone() {
                      TokenType::Identifier(s) => s,
                      _ => return Err(Diagnostic::error("Expected identifier", self.previous().span)),
                  };
                  if name == "T" {
                      expr = Expr::Transpose(Box::new(expr));
                      continue;
                  }
                  if self.match_token(&[TokenType::LParen]) {'''

code = code.replace('''              } else if self.match_token(&[TokenType::Dot]) {
                  let name = match self.consume(TokenType::Identifier("".to_string()), "Expected property name after '.'")?.token_type.clone() {
                      TokenType::Identifier(s) => s,
                      _ => return Err(Diagnostic::error("Expected identifier", self.previous().span)),
                  };
                  if self.match_token(&[TokenType::LParen]) {''', dot_logic)

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)
