import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

debug_logic = '''    fn declaration(&mut self) -> Result<Stmt, Diagnostic> {
        println!("declaration() at {:?}", self.peek());'''

code = code.replace('    fn declaration(&mut self) -> Result<Stmt, Diagnostic> {', debug_logic)

debug_logic2 = '''    fn statement(&mut self) -> Result<Stmt, Diagnostic> {
        println!("statement() at {:?}", self.peek());'''

code = code.replace('    fn statement(&mut self) -> Result<Stmt, Diagnostic> {', debug_logic2)

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)
