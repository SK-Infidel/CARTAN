import base64
with open('test_quote.ctn', 'w', encoding='utf-8') as f:
    f.write('''
macro replace_block {
    pattern {
         = ;
    }
    replace {
        ;
    }
}

fn main() {
    let a = 1.0;
    
    a = quote {
        a = a + 1.0;
        a = a * 2.0;
    };
}
''')
