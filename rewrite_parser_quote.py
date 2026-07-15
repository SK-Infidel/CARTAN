import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_parser = '''            TokenType::Identifier(s) => Ok(Expr::Identifier(s)),
            TokenType::Placeholder(s) => Ok(Expr::Placeholder(s)),'''
new_parser = '''            TokenType::Identifier(s) => Ok(Expr::Identifier(s)),
            TokenType::Placeholder(s) => Ok(Expr::Placeholder(s)),
            TokenType::Quote => {
                self.consume(TokenType::LBrace, "Expected '{' after 'quote'")?;
                let block = self.block()?;
                Ok(Expr::Quote(block))
            },'''

if old_parser in code:
    code = code.replace(old_parser, new_parser)
    with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Added quote parsing to parser.rs")
else:
    print("Could not find Expr parsing in parser.rs")
