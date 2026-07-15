import os

with open('src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_primary = '''        match token.token_type {
            TokenType::IntLiteral(n) => Ok(Expr::Integer(n)),
            TokenType::FloatLiteral(n) => Ok(Expr::Float(n)),
            TokenType::StringLiteral(s) => Ok(Expr::StringLiteral(s)),
            TokenType::Identifier(s) => Ok(Expr::Identifier(s)),
            _ => Err(Diagnostic::error("Expected expression", token.span)),
        }'''

new_primary = '''        match token.token_type {
            TokenType::IntLiteral(n) => Ok(Expr::Integer(n)),
            TokenType::FloatLiteral(n) => Ok(Expr::Float(n)),
            TokenType::StringLiteral(s) => Ok(Expr::StringLiteral(s)),
            TokenType::Identifier(s) => Ok(Expr::Identifier(s)),
            TokenType::Placeholder(s) => Ok(Expr::Placeholder(s)),
            _ => Err(Diagnostic::error("Expected expression", token.span)),
        }'''

if old_primary in code:
    code = code.replace(old_primary, new_primary)
    print("Added Placeholder parsing to parser.rs primary()")
else:
    print("Could not find primary() match in parser.rs")

with open('src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)

