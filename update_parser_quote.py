import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

quote_logic = '''        }
        if self.match_token(&[TokenType::Quote]) {
            self.consume(TokenType::LBrace, "Expected '{' after quote")?;
            let body = self.block()?;
            return Ok(Expr::Quote(body));
        }
        if self.match_token(&[TokenType::Macro]) {'''

code = code.replace('        }\n        if self.match_token(&[TokenType::Macro]) {', quote_logic)

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)
