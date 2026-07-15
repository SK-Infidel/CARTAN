import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_decl = '''        if self.match_token(&[TokenType::Extern]) {
            self.extern_function_declaration()
        } else if self.match_token(&[TokenType::Fn]) {'''
new_decl = '''        if self.match_token(&[TokenType::Macro]) {
            self.macro_declaration()
        } else if self.match_token(&[TokenType::Extern]) {
            self.extern_function_declaration()
        } else if self.match_token(&[TokenType::Fn]) {'''

if old_decl in code:
    code = code.replace(old_decl, new_decl)
    print("Added macro declaration dispatch")
else:
    print("Failed to find decl")

old_func = '''    fn function_declaration(&mut self, is_agent_accessible: bool) -> Result<Stmt, Diagnostic> {'''
new_func = '''    fn macro_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name = match self.consume(TokenType::Identifier("".to_string()), "Expected macro name")?.token_type.clone() {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected macro name", self.previous().span)),
        };
        self.consume(TokenType::LBrace, "Expected '{' after macro name")?;
        
        self.consume(TokenType::Pattern, "Expected 'pattern' block in macro")?;
        self.consume(TokenType::LBrace, "Expected '{' after 'pattern'")?;
        let pattern = self.block()?;
        
        self.consume(TokenType::Replace, "Expected 'replace' block in macro")?;
        self.consume(TokenType::LBrace, "Expected '{' after 'replace'")?;
        let replace = self.block()?;
        
        self.consume(TokenType::RBrace, "Expected '}' after macro body")?;
        
        Ok(Stmt::MacroDecl(crate::ast::MacroRule {
            name,
            pattern,
            replace,
        }))
    }

    fn function_declaration(&mut self, is_agent_accessible: bool) -> Result<Stmt, Diagnostic> {'''

if old_func in code:
    code = code.replace(old_func, new_func)
    print("Added macro_declaration fn")
else:
    print("Failed to find function_declaration")

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)

