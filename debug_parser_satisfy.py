import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

debug_logic = '''        } else if self.match_token(&[TokenType::Satisfy]) {
            self.consume(TokenType::LParen, "Expected '(' after satisfy")?;
            let condition = self.expression()?;
            self.consume(TokenType::RParen, "Expected ')' after satisfy condition")?;
            let body = self.block()?;
            println!("Finished parsing body of satisfy, next token is: {:?}", self.peek());
            let mut otherwise = None;
            if self.match_token(&[TokenType::Otherwise]) {
                println!("Matched otherwise!");
                otherwise = Some(self.block()?);
            } else {
                println!("Did NOT match otherwise!");
            }
            Ok(Stmt::Satisfy { condition, body, otherwise })'''

code = code.replace('''        } else if self.match_token(&[TokenType::Satisfy]) {
            self.consume(TokenType::LParen, "Expected '(' after satisfy")?;
            let condition = self.expression()?;
            self.consume(TokenType::RParen, "Expected ')' after satisfy condition")?;
            let body = self.block()?;
            let mut otherwise = None;
            if self.match_token(&[TokenType::Otherwise]) {
                otherwise = Some(self.block()?);
            }
            Ok(Stmt::Satisfy { condition, body, otherwise })''', debug_logic)

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)
