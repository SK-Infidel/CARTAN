import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('match self.consume(TokenType::Identifier("".to_string()), "Expected mesh identifier")?.token_type {', 'match self.consume(TokenType::Identifier("".to_string()), "Expected mesh identifier")?.token_type.clone() {')
code = code.replace('match self.consume(TokenType::StringLiteral("".to_string()), "Expected supervisor strategy string")?.token_type {', 'match self.consume(TokenType::StringLiteral("".to_string()), "Expected supervisor strategy string")?.token_type.clone() {')

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)
