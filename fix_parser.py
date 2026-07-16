import os

with open('compiler/src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('return Err(self.error("Expected identifier"))', 'return Err(Diagnostic::error("Expected identifier", self.peek().span))')
code = code.replace('return Err(self.error("Expected string literal"))', 'return Err(Diagnostic::error("Expected string literal", self.peek().span))')

with open('compiler/src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)
