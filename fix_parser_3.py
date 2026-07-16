import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('''            self.consume(TokenType::RParen, "Expected ')' after supervisor strategy")?;
            
            let body = self.block()?;''', '''            self.consume(TokenType::RParen, "Expected ')' after supervisor strategy")?;
            self.consume(TokenType::LBrace, "Expected '{' after mesh supervisor")?;
            let body = self.block()?;''')

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)
