import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('''    fn declaration(&mut self) -> Result<Stmt, Diagnostic> {
        println!("declaration() at {:?}", self.peek());''', '''    fn declaration(&mut self) -> Result<Stmt, Diagnostic> {''')

code = code.replace('''    fn statement(&mut self) -> Result<Stmt, Diagnostic> {
        println!("statement() at {:?}", self.peek());''', '''    fn statement(&mut self) -> Result<Stmt, Diagnostic> {''')

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)
