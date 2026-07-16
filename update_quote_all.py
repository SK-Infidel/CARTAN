import os

with open('compiler/src/token.rs', 'r', encoding='utf-8') as f:
    code = f.read()
if 'Quote,' not in code:
    code = code.replace('Backtrack,', 'Backtrack,\n    Quote,')
with open('compiler/src/token.rs', 'w', encoding='utf-8') as f:
    f.write(code)

with open('compiler/src/lexer.rs', 'r', encoding='utf-8') as f:
    code = f.read()
if 'quote' not in code:
    code = code.replace('keywords.insert("backtrack".to_string(), TokenType::Backtrack);', 'keywords.insert("backtrack".to_string(), TokenType::Backtrack);\n        keywords.insert("quote".to_string(), TokenType::Quote);')
with open('compiler/src/lexer.rs', 'w', encoding='utf-8') as f:
    f.write(code)

with open('compiler/src/ast.rs', 'r', encoding='utf-8') as f:
    code = f.read()
if 'Quote(' not in code:
    code = code.replace('HotSwap(Box<Expr>, Box<Expr>),', 'HotSwap(Box<Expr>, Box<Expr>),\n    Quote(BlockStmt),')
with open('compiler/src/ast.rs', 'w', encoding='utf-8') as f:
    f.write(code)

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()
if 'Expr::Quote' not in code:
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
