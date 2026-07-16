import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

if 'TokenType::Mesh' not in code:
    mesh_logic = '''        } else if self.match_token(&[TokenType::Mesh]) {
            let name = match self.consume(TokenType::Identifier("".to_string()), "Expected mesh identifier")?.token_type {
                TokenType::Identifier(id) => id,
                _ => return Err("Expected identifier".to_string()),
            };
            self.consume(TokenType::Supervisor, "Expected 'supervisor' after mesh name")?;
            self.consume(TokenType::LParen, "Expected '(' after 'supervisor'")?;
            let strategy = match self.consume(TokenType::StringLiteral("".to_string()), "Expected supervisor strategy string")?.token_type {
                TokenType::StringLiteral(s) => s,
                _ => return Err("Expected string literal".to_string()),
            };
            self.consume(TokenType::RParen, "Expected ')' after supervisor strategy")?;
            
            let body = self.block()?;
            Ok(Stmt::MeshBlock { name, strategy, body })
        } else if self.match_token(&[TokenType::Topology]) {'''
    code = code.replace('        } else if self.match_token(&[TokenType::Topology]) {', mesh_logic)

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)
