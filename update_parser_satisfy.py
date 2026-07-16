import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

satisfy_logic = '''        }
        if self.match_token(&[TokenType::Backtrack]) {
            self.consume(TokenType::Semicolon, "Expected ';' after backtrack")?;
            return Ok(Stmt::Backtrack);
        }
        if self.match_token(&[TokenType::Satisfy]) {
            self.consume(TokenType::LParen, "Expected '(' after satisfy")?;
            let condition = self.expression()?;
            self.consume(TokenType::RParen, "Expected ')' after satisfy condition")?;
            let body = self.block()?;
            let mut otherwise = None;
            if self.match_token(&[TokenType::Otherwise]) {
                otherwise = Some(self.block()?);
            }
            return Ok(Stmt::Satisfy { condition, body, otherwise });
        }
        if self.match_token(&[TokenType::Return]) {'''

code = code.replace('        }\n        if self.match_token(&[TokenType::Return]) {', satisfy_logic)

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)
