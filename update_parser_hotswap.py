import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

if 'TokenType::HotSwap' not in code:
    hotswap_logic = '''        }
        if self.match_token(&[TokenType::HotSwap]) {
            self.consume(TokenType::LParen, "Expected '(' after hotswap")?;
            let target = self.expression()?;
            self.consume(TokenType::Comma, "Expected ',' between target and new_graph")?;
            let new_graph = self.expression()?;
            self.consume(TokenType::RParen, "Expected ')' after hotswap arguments")?;
            return Ok(Expr::HotSwap(Box::new(target), Box::new(new_graph)));
        }
        if self.match_token(&[TokenType::IntLiteral(0)]) {'''
    code = code.replace('        }\n        if self.match_token(&[TokenType::IntLiteral(0)]) {', hotswap_logic)

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)
