import os

with open('src/parser.rs', 'r', encoding='utf-8') as f:
    code = f.read()

old_param = '''                let p_type = if self.match_token(&[TokenType::Tensor]) {
                    "tensor".to_string()
                } else {
                    println!("Next token: {:?}", self.peek()); match self.consume(TokenType::Identifier("".to_string()), "Expected parameter type")?.token_type.clone() {
                        TokenType::Identifier(s) => s,
                        _ => "tensor".to_string(),
                    }
                };
                
                parameters.push(Parameter {
                    name: p_name,
                    type_name: p_type,
                    is_borrow,
                    is_mutable,
                });'''

new_param = '''                let mut p_shape = Vec::new();
                let p_type = if self.match_token(&[TokenType::Tensor]) {
                    if self.match_token(&[TokenType::LBracket]) {
                        if !self.check(&TokenType::RBracket) {
                            loop {
                                p_shape.push(self.expression()?);
                                if !self.match_token(&[TokenType::Comma]) {
                                    break;
                                }
                            }
                        }
                        self.consume(TokenType::RBracket, "Expected ']' after tensor shape in parameter")?;
                    }
                    "tensor".to_string()
                } else {
                    println!("Next token: {:?}", self.peek()); match self.consume(TokenType::Identifier("".to_string()), "Expected parameter type")?.token_type.clone() {
                        TokenType::Identifier(s) => s,
                        _ => "tensor".to_string(),
                    }
                };
                
                let mut p_manifold = None;
                if self.match_token(&[TokenType::In]) {
                    let space_token = self.consume(TokenType::Identifier("".to_string()), "Expected manifold space name after 'in'")?.clone();
                    let space_name = match space_token.token_type {
                        TokenType::Identifier(s) => s,
                        _ => return Err(Diagnostic::error("Expected manifold space name", space_token.span)),
                    };
                    p_manifold = Some(match space_name.as_str() {
                        "Minkowski" => ManifoldSpace::Minkowski,
                        "PoincareDisk" => ManifoldSpace::PoincareDisk,
                        "Euclidean" => ManifoldSpace::Euclidean,
                        _ => ManifoldSpace::Custom(space_name),
                    });
                }
                
                parameters.push(Parameter {
                    name: p_name,
                    type_name: p_type,
                    shape: p_shape,
                    manifold: p_manifold,
                    is_borrow,
                    is_mutable,
                });'''

code = code.replace(old_param, new_param)

# Also fix extern_function_declaration which has "sequence" parsing
old_param_extern = '''                let p_type = if self.match_token(&[TokenType::Tensor]) {
                    "tensor".to_string()
                } else if self.match_token(&[TokenType::Sequence]) {
                    "sequence".to_string()
                } else {
                    println!("Next token: {:?}", self.peek()); match self.consume(TokenType::Identifier("".to_string()), "Expected parameter type")?.token_type.clone() {
                        TokenType::Identifier(s) => s,
                        _ => "tensor".to_string(), // Default or error fallback
                    }
                };
                
                parameters.push(Parameter {
                    name: p_name,
                    type_name: p_type,
                    is_borrow,
                    is_mutable,
                });'''

new_param_extern = '''                let mut p_shape = Vec::new();
                let p_type = if self.match_token(&[TokenType::Tensor]) {
                    if self.match_token(&[TokenType::LBracket]) {
                        if !self.check(&TokenType::RBracket) {
                            loop {
                                p_shape.push(self.expression()?);
                                if !self.match_token(&[TokenType::Comma]) {
                                    break;
                                }
                            }
                        }
                        self.consume(TokenType::RBracket, "Expected ']' after tensor shape in parameter")?;
                    }
                    "tensor".to_string()
                } else if self.match_token(&[TokenType::Sequence]) {
                    "sequence".to_string()
                } else {
                    println!("Next token: {:?}", self.peek()); match self.consume(TokenType::Identifier("".to_string()), "Expected parameter type")?.token_type.clone() {
                        TokenType::Identifier(s) => s,
                        _ => "tensor".to_string(), // Default or error fallback
                    }
                };
                
                let mut p_manifold = None;
                if self.match_token(&[TokenType::In]) {
                    let space_token = self.consume(TokenType::Identifier("".to_string()), "Expected manifold space name after 'in'")?.clone();
                    let space_name = match space_token.token_type {
                        TokenType::Identifier(s) => s,
                        _ => return Err(Diagnostic::error("Expected manifold space name", space_token.span)),
                    };
                    p_manifold = Some(match space_name.as_str() {
                        "Minkowski" => ManifoldSpace::Minkowski,
                        "PoincareDisk" => ManifoldSpace::PoincareDisk,
                        "Euclidean" => ManifoldSpace::Euclidean,
                        _ => ManifoldSpace::Custom(space_name),
                    });
                }
                
                parameters.push(Parameter {
                    name: p_name,
                    type_name: p_type,
                    shape: p_shape,
                    manifold: p_manifold,
                    is_borrow,
                    is_mutable,
                });'''

code = code.replace(old_param_extern, new_param_extern)

with open('src/parser.rs', 'w', encoding='utf-8') as f:
    f.write(code)

print("done")
