import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

hotswap_logic = '''            TokenType::HotSwap => {
                self.consume(TokenType::LParen, "Expected '(' after hotswap")?;
                let target = self.expression()?;
                self.consume(TokenType::Comma, "Expected ',' between target and new_graph")?;
                let new_graph = self.expression()?;
                self.consume(TokenType::RParen, "Expected ')' after hotswap arguments")?;
                Ok(Expr::HotSwap(Box::new(target), Box::new(new_graph)))
            },
            TokenType::IntLiteral(n) => Ok(Expr::Integer(n)),'''

code = code.replace('            TokenType::IntLiteral(n) => Ok(Expr::Integer(n)),', hotswap_logic)

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)
