import os

with open('compiler/src/type_checker.rs', 'r', encoding='utf-8') as f:
    code = f.read()

func_logic = '''                  if self.functions.contains_key(&mangled) {
                      *name = mangled;
                  } else {
                      *name = mangled.clone();
                  }
                  
                  if name.starts_with("ones_like") && args.len() == 1 {
                      return Ok(self.visit_expr(&mut args[0])?);
                  }
                  
                  Ok(CartanType::Unknown)
              },'''

code = code.replace('''                  if self.functions.contains_key(&mangled) {
                      *name = mangled;
                  } else {
                      // Try to mangle based on what's available, or just leave it
                      *name = mangled;
                  }
                  
                  Ok(CartanType::Unknown)
              },''', func_logic)

with open('compiler/src/type_checker.rs', 'w', encoding='utf-8') as f:
    f.write(code)
