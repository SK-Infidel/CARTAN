use crate::token::{Token, TokenType};
use crate::error::Diagnostic;
use crate::ast::{Stmt, Expr, FunctionDecl, ExternFunctionDecl, BlockStmt, Parameter, GenericBound, ManifoldSpace};

pub struct Parser {
    tokens: Vec<Token>,
    current: usize,
}

impl Parser {
    pub fn new(tokens: Vec<Token>) -> Self {
        Self { tokens, current: 0 }
    }

    fn peek(&self) -> &Token {
        &self.tokens[self.current]
    }

    fn previous(&self) -> &Token {
        &self.tokens[self.current - 1]
    }

    fn is_at_end(&self) -> bool {
        self.peek().token_type == TokenType::EOF
    }

    fn check(&self, t_type: &TokenType) -> bool {
        if self.is_at_end() {
            return false;
        }
        std::mem::discriminant(&self.peek().token_type) == std::mem::discriminant(t_type)
    }

    fn advance(&mut self) -> &Token {
        if !self.is_at_end() {
            self.current += 1;
        }
        self.previous()
    }

    fn match_token(&mut self, types: &[TokenType]) -> bool {
        for t in types {
            if self.check(t) {
                self.advance();
                return true;
            }
        }
        false
    }

    fn consume(&mut self, t_type: TokenType, message: &str) -> Result<&Token, Diagnostic> {
        if self.check(&t_type) {
            return Ok(self.advance());
        }
        Err(Diagnostic::error(message, self.peek().span))
    }

    pub fn parse(&mut self) -> Result<Vec<Stmt>, Diagnostic> {
        let mut statements = Vec::new();
        while !self.is_at_end() {
            statements.push(self.declaration()?);
        }
        Ok(statements)
    }

    fn declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let mut is_agent_accessible = false;
        if self.match_token(&[TokenType::AgentAccessible]) {
            is_agent_accessible = true;
        }

        if self.match_token(&[TokenType::Extern]) {
            self.extern_function_declaration()
        } else if self.match_token(&[TokenType::Fn]) {
            self.function_declaration(is_agent_accessible)
        } else if self.match_token(&[TokenType::Struct]) {
            self.struct_declaration()
        } else if self.match_token(&[TokenType::Var]) {
            self.var_declaration(false)
        } else if self.match_token(&[TokenType::Let]) {
            self.var_declaration(false)
        } else if self.match_token(&[TokenType::Const]) {
            self.var_declaration(true)
        } else if self.match_token(&[TokenType::Tensor]) {
            self.tensor_declaration()
        } else if self.match_token(&[TokenType::Parameter]) {
            self.parameter_declaration()
        } else if self.match_token(&[TokenType::Sequence]) {
            self.sequence_declaration()
        } else if self.match_token(&[TokenType::Block]) {
            self.block_declaration()
        } else if self.match_token(&[TokenType::Manifold]) {
            self.manifold_declaration()
        } else if self.match_token(&[TokenType::Topology]) {
            self.topology_declaration()
        } else if self.match_token(&[TokenType::Stream]) {
            self.stream_declaration()
        } else if self.match_token(&[TokenType::Import]) {
            self.import_declaration()
        } else {
            self.statement()
        }
    }

    fn stream_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let id_expr = self.expression()?;
        self.consume(TokenType::Colon, "Expected ':' after stream ID")?;
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected manifold name")?.clone();
        let manifold_name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected manifold name", name_token.span)),
        };
        self.consume(TokenType::Semicolon, "Expected ';' after stream declaration")?;
        Ok(Stmt::StreamDecl { id: id_expr, manifold_name })
    }

    fn import_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let path_token = self.consume(TokenType::StringLiteral(String::new()), "Expected string literal for import path")?;
        let path = match path_token.token_type.clone() {
            TokenType::StringLiteral(s) => s,
            _ => return Err(Diagnostic::error("Expected string literal for import path", path_token.span)),
        };
        self.consume(TokenType::Semicolon, "Expected ';' after import path")?;
        Ok(Stmt::Import { filepath: path })
    }

    fn manifold_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected manifold name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected manifold name", name_token.span)),
        };
        self.consume(TokenType::LBrace, "Expected '{' after manifold name")?;
        let body = self.block()?;
        Ok(Stmt::ManifoldDecl { name, body })
    }

    fn topology_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected topology name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected topology name", name_token.span)),
        };
        self.consume(TokenType::LBrace, "Expected '{' after topology name")?;
        let body = self.block()?;
        Ok(Stmt::TopologyDecl { name, body })
    }
    
    fn tensor_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected tensor name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected tensor name", name_token.span)),
        };
        self.tensor_declaration_with_name(name, false, None)
    }

    fn sequence_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected sequence name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected sequence name", name_token.span)),
        };
        self.consume(TokenType::LBracket, "Expected '[' after sequence name")?;
        let max_len = self.expression()?;
        self.consume(TokenType::RBracket, "Expected ']' after sequence size")?;
        self.consume(TokenType::Semicolon, "Expected ';' after sequence declaration")?;
        Ok(Stmt::SequenceDecl { name, max_len })
    }

    fn block_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected block name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected block name", name_token.span)),
        };
        self.consume(TokenType::LBracket, "Expected '[' after block name")?;
        let size = self.expression()?;
        self.consume(TokenType::RBracket, "Expected ']' after block size")?;
        self.consume(TokenType::Semicolon, "Expected ';' after block declaration")?;
        Ok(Stmt::BlockDecl { name, size })
    }

    fn parameter_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let mut optimizer = None;
        if self.match_token(&[TokenType::LBracket]) {
            let opt_token = self.consume(TokenType::Identifier("".to_string()), "Expected optimizer name (e.g. Adam)")?.clone();
            if let TokenType::Identifier(s) = opt_token.token_type {
                if s == "Adam" { optimizer = Some(crate::ast::OptimizerState::Adam); }
                else if s == "SGD" { optimizer = Some(crate::ast::OptimizerState::SGD); }
                else { return Err(Diagnostic::error(&format!("Unknown optimizer: {}", s), opt_token.span)); }
            }
            self.consume(TokenType::RBracket, "Expected ']' after optimizer")?;
        }
        
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected parameter name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected parameter name", name_token.span)),
        };
        self.tensor_declaration_with_name(name, true, optimizer)
    }

    fn tensor_declaration_with_name(&mut self, name: String, is_parameter: bool, optimizer: Option<crate::ast::OptimizerState>) -> Result<Stmt, Diagnostic> {
        self.consume(TokenType::LBracket, "Expected '[' after tensor name for shape")?;
        
        let mut shape = Vec::new();
        if !self.check(&TokenType::RBracket) {
            loop {
                shape.push(self.expression()?);
                if !self.match_token(&[TokenType::Comma]) {
                    break;
                }
            }
        }
        
        self.consume(TokenType::RBracket, "Expected ']' after tensor shape")?;
        
        let mut manifold = ManifoldSpace::Euclidean;
        if self.match_token(&[TokenType::In]) {
            let space_token = self.consume(TokenType::Identifier("".to_string()), "Expected manifold space name after 'in'")?.clone();
            let space_name = match space_token.token_type {
                TokenType::Identifier(s) => s,
                _ => return Err(Diagnostic::error("Expected manifold space name", space_token.span)),
            };
            manifold = match space_name.as_str() {
                "Minkowski" => ManifoldSpace::Minkowski,
                "PoincareDisk" => ManifoldSpace::PoincareDisk,
                "Euclidean" => ManifoldSpace::Euclidean,
                _ => ManifoldSpace::Custom(space_name),
            };
        }
        



        if let TokenType::Identifier(s) = &self.peek().token_type.clone() {
            if s == "under" {
                self.advance();
                self.consume(TokenType::Identifier("".to_string()), "Expected precision type after 'under'")?;
            }
        }
        
        let mut layout = None;
        if self.match_token(&[TokenType::Layout]) {
            self.consume(TokenType::LParen, "Expected '(' after layout")?;
            let layout_token = self.consume(TokenType::Identifier("".to_string()), "Expected layout type (SoA, Tiled)")?.clone();
            let layout_name = match layout_token.token_type {
                TokenType::Identifier(s) => s,
                _ => return Err(Diagnostic::error("Expected layout type", layout_token.span)),
            };
            
            if layout_name == "SoA" {
                layout = Some(crate::ast::MemoryLayout::SoA);
            } else if layout_name == "Tiled" {
                self.consume(TokenType::LParen, "Expected '(' after Tiled")?;
                let x_token = self.consume(TokenType::IntLiteral(0), "Expected integer for Tile width")?.clone();
                let x = match x_token.token_type {
                    TokenType::IntLiteral(v) => v as u32,
                    _ => return Err(Diagnostic::error("Expected integer", x_token.span)),
                };
                self.consume(TokenType::Comma, "Expected ','")?;
                let y_token = self.consume(TokenType::IntLiteral(0), "Expected integer for Tile height")?.clone();
                let y = match y_token.token_type {
                    TokenType::IntLiteral(v) => v as u32,
                    _ => return Err(Diagnostic::error("Expected integer", y_token.span)),
                };
                self.consume(TokenType::RParen, "Expected ')' after Tiled dims")?;
                layout = Some(crate::ast::MemoryLayout::Tiled(x, y));
            } else {
                layout = Some(crate::ast::MemoryLayout::Default);
            }
            self.consume(TokenType::RParen, "Expected ')' after layout definition")?;
        }
        
        let mut location = None;
        if self.match_token(&[TokenType::AtLocation]) {
            self.consume(TokenType::LParen, "Expected '('")?;
            let loc_str = match self.consume(TokenType::StringLiteral("".to_string()), "Expected location string")?.token_type.clone() {
                TokenType::StringLiteral(s) => s,
                _ => "".to_string(),
            };
            location = Some(loc_str);
            self.consume(TokenType::RParen, "Expected ')'")?;
        }
        
        let mut backend = crate::ast::StorageBackend::Memory;
        if self.match_token(&[TokenType::AtBackend]) {
            self.consume(TokenType::LParen, "Expected '('")?;
            let backend_str = match self.consume(TokenType::StringLiteral("".to_string()), "Expected backend string")?.token_type.clone() {
                TokenType::StringLiteral(s) => s,
                _ => "".to_string(),
            };
            if backend_str == "NVMe" {
                backend = crate::ast::StorageBackend::NVMe;
            }
            self.consume(TokenType::RParen, "Expected ')'")?;
        }
        
        self.consume(TokenType::Semicolon, "Expected ';' after declaration")?;

        if is_parameter {
            Ok(Stmt::ParameterDecl {
                name,
                shape,
                manifold,
                layout,
                location,
                backend,
                optimizer,
            })
        } else {
            Ok(Stmt::TensorDecl {
                name,
                shape,
                manifold,
                layout,
                location,
                backend,
            })
        }
    }

    
    fn block(&mut self) -> Result<BlockStmt, Diagnostic> {
        let mut statements = Vec::new();
        while !self.check(&TokenType::RBrace) && !self.is_at_end() {
            statements.push(self.declaration()?);
        }
        self.consume(TokenType::RBrace, "Expected '}' after block")?;
        Ok(BlockStmt { statements })
    }


    fn struct_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected struct name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected struct name", name_token.span)),
        };

        self.consume(TokenType::LBrace, "Expected '{' before struct body")?;
        
        let mut fields = Vec::new();
        while !self.check(&TokenType::RBrace) && !self.is_at_end() {
            fields.push(self.declaration()?);
        }
        
        self.consume(TokenType::RBrace, "Expected '}' after struct body")?;
        
        Ok(Stmt::StructDecl { name, fields })
    }



    fn function_declaration(&mut self, is_agent_accessible: bool) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected function name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected function name", name_token.span)),
        };

        // Parse optional generic bounds
        let mut generic_bounds = Vec::new();
        if self.match_token(&[TokenType::Less]) {
            loop {
                let p_name = match self.consume(TokenType::Identifier("".to_string()), "Expected generic parameter name")?.token_type.clone() {
                    TokenType::Identifier(s) => s,
                    _ => "".to_string(),
                };
                self.consume(TokenType::Colon, "Expected ':' after generic parameter name")?;
                let p_bound = match self.consume(TokenType::Identifier("".to_string()), "Expected generic bound")?.token_type.clone() {
                    TokenType::Identifier(s) => s,
                    _ => "".to_string(),
                };
                generic_bounds.push(GenericBound { name: p_name, bound: p_bound });
                
                if !self.match_token(&[TokenType::Comma]) {
                    break;
                }
            }
            self.consume(TokenType::Greater, "Expected '>' after generic bounds")?;
        }

        self.consume(TokenType::LParen, "Expected '(' after function name")?;
        
        let mut parameters = Vec::new();
        if !self.check(&TokenType::RParen) {
            loop {
                let mut is_borrow = false;
                let mut is_mutable = false;
                if self.match_token(&[TokenType::Ampersand]) {
                    is_borrow = true;
                    if self.match_token(&[TokenType::Mut]) {
                        is_mutable = true;
                    }
                }

                let p_name = match self.consume(TokenType::Identifier("".to_string()), "Expected parameter name")?.token_type.clone() {
                    TokenType::Identifier(s) => s,
                    _ => "".to_string(),
                };
                self.consume(TokenType::Colon, "Expected ':' after parameter name")?;
                
                let p_type = if self.match_token(&[TokenType::Tensor]) {
                    "tensor".to_string()
                } else {
                    match self.consume(TokenType::Identifier("".to_string()), "Expected parameter type")?.token_type.clone() {
                        TokenType::Identifier(s) => s,
                        _ => "tensor".to_string(),
                    }
                };
                
                parameters.push(Parameter {
                    name: p_name,
                    type_name: p_type,
                    is_borrow,
                    is_mutable,
                });
                
                if !self.match_token(&[TokenType::Comma]) {
                    break;
                }
            }
        }
        self.consume(TokenType::RParen, "Expected ')' after parameters")?;

        let mut return_type = None;
        if self.match_token(&[TokenType::Arrow]) {
            if self.match_token(&[TokenType::Tensor]) {
                return_type = Some("tensor".to_string());
            } else {
                return_type = match self.consume(TokenType::Identifier("".to_string()), "Expected return type")?.token_type.clone() {
                    TokenType::Identifier(s) => Some(s),
                    _ => None,
                };
            }
        }

        self.consume(TokenType::LBrace, "Expected '{' before function body")?;
        let body = self.block()?;

        Ok(Stmt::FunctionDecl(FunctionDecl {
            name,
            generic_bounds,
            parameters,
            return_type,
            is_agent_accessible,
            body,
        }))
    }

    fn extern_function_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        self.consume(TokenType::Fn, "Expected 'fn' after 'extern'")?;
        
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected function name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected function name", name_token.span)),
        };

        self.consume(TokenType::LParen, "Expected '(' after function name")?;
        
        let mut parameters = Vec::new();
        if !self.check(&TokenType::RParen) {
            loop {
                let mut is_borrow = false;
                let mut is_mutable = false;
                if self.match_token(&[TokenType::Ampersand]) {
                    is_borrow = true;
                    if self.match_token(&[TokenType::Mut]) {
                        is_mutable = true;
                    }
                }

                let p_name = match self.consume(TokenType::Identifier("".to_string()), "Expected parameter name")?.token_type.clone() {
                    TokenType::Identifier(s) => s,
                    _ => "".to_string(),
                };
                self.consume(TokenType::Colon, "Expected ':' after parameter name")?;
                
                let p_type = match self.consume(TokenType::Identifier("".to_string()), "Expected parameter type")?.token_type.clone() {
                    TokenType::Identifier(s) => s,
                    _ => "tensor".to_string(), // Default or error fallback
                };
                
                parameters.push(Parameter {
                    name: p_name,
                    type_name: p_type,
                    is_borrow,
                    is_mutable,
                });
                
                if !self.match_token(&[TokenType::Comma]) {
                    break;
                }
            }
        }
        self.consume(TokenType::RParen, "Expected ')' after parameters")?;

        let mut return_type = None;
        if self.match_token(&[TokenType::Arrow]) {
            return_type = match self.consume(TokenType::Identifier("".to_string()), "Expected return type")?.token_type.clone() {
                TokenType::Identifier(s) => Some(s),
                _ => None,
            };
        }

        self.consume(TokenType::Semicolon, "Expected ';' after extern function declaration")?;

        Ok(Stmt::ExternFunctionDecl(ExternFunctionDecl {
            name,
            parameters,
            return_type,
        }))
    }

    fn var_declaration(&mut self, is_const: bool) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected variable name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected variable name", name_token.span)),
        };

        let value = if self.match_token(&[TokenType::Eq]) {
            if self.match_token(&[TokenType::Tensor]) {
                return self.tensor_declaration_with_name(name, false, None);
            }
            if self.match_token(&[TokenType::Parameter]) {
                return self.tensor_declaration_with_name(name, true, None);
            }
            self.expression()?
        } else {
            return Err(Diagnostic::error("Expected '=' after variable name", self.peek().span));
        };

        self.consume(TokenType::Semicolon, "Expected ';' after variable declaration")?;

        Ok(Stmt::VarDecl { name, is_const, value })
    }

    fn statement(&mut self) -> Result<Stmt, Diagnostic> {
        if self.match_token(&[TokenType::LBrace]) {
            Ok(Stmt::Block(self.block()?))
        } else if self.match_token(&[TokenType::While]) {
            self.consume(TokenType::LParen, "Expected '(' after 'while'")?;
            let condition = self.expression()?;
            self.consume(TokenType::RParen, "Expected ')' after condition")?;
            self.consume(TokenType::LBrace, "Expected '{' after while condition")?;
            let body = self.block()?;
            Ok(Stmt::While { condition, body })
        } else if self.match_token(&[TokenType::If]) {
            self.consume(TokenType::LParen, "Expected '(' after 'if'")?;
            let condition = self.expression()?;
            self.consume(TokenType::RParen, "Expected ')' after condition")?;
            self.consume(TokenType::LBrace, "Expected '{' after if condition")?;
            let true_block = self.block()?;
            let mut false_block = None;
            if self.match_token(&[TokenType::Else]) {
                // To support `else if`, we would need more logic. 
                // But simple `else { }` is what we have in AST for now.
                self.consume(TokenType::LBrace, "Expected '{' after 'else'")?;
                false_block = Some(self.block()?);
            }
            Ok(Stmt::If { condition, true_block, false_block })
        } else if self.match_token(&[TokenType::Match]) {
            self.consume(TokenType::LParen, "Expected '(' after 'match'")?;
            let condition = self.expression()?;
            self.consume(TokenType::RParen, "Expected ')' after condition")?;
            self.consume(TokenType::LBrace, "Expected '{' after match condition")?;
            
            let mut arms = Vec::new();
            while !self.check(&TokenType::RBrace) && !self.is_at_end() {
                let pattern = if self.match_token(&[TokenType::Identifier("_".to_string())]) {
                    None
                } else {
                    Some(self.expression()?)
                };
                
                self.consume(TokenType::FatArrow, "Expected '=>' after match pattern")?;
                self.consume(TokenType::LBrace, "Expected '{' before match arm body")?;
                let body = self.block()?;
                
                arms.push((pattern, Box::new(Stmt::Block(body))));
                
                self.match_token(&[TokenType::Comma]); // Optional comma
            }
            self.consume(TokenType::RBrace, "Expected '}' after match arms")?;
            Ok(Stmt::Match { condition, arms })
        } else if self.match_token(&[TokenType::Break]) {
            self.consume(TokenType::Semicolon, "Expected ';' after 'break'")?;
            Ok(Stmt::Break)
        } else if self.match_token(&[TokenType::Continue]) {
            self.consume(TokenType::Semicolon, "Expected ';' after 'continue'")?;
            Ok(Stmt::Continue)
        } else if self.match_token(&[TokenType::Try]) {
            self.consume(TokenType::LBrace, "Expected '{' after 'try'")?;
            let try_block = self.block()?;
            self.consume(TokenType::Catch, "Expected 'catch' after 'try' block")?;
            self.consume(TokenType::LParen, "Expected '(' after 'catch'")?;
            let catch_var = match self.consume(TokenType::Identifier("".to_string()), "Expected catch variable name")?.token_type.clone() {
                TokenType::Identifier(s) => s,
                _ => "".to_string(),
            };
            self.consume(TokenType::RParen, "Expected ')' after catch variable")?;
            self.consume(TokenType::LBrace, "Expected '{' after catch condition")?;
            let catch_block = self.block()?;
            Ok(Stmt::TryCatch { try_block, catch_var, catch_block })
        } else if self.match_token(&[TokenType::Return]) {
            let value = if !self.check(&TokenType::Semicolon) {
                Some(self.expression()?)
            } else {
                None
            };
            self.consume(TokenType::Semicolon, "Expected ';' after return value")?;
            Ok(Stmt::Return { value })
        } else if self.match_token(&[TokenType::Backward]) {
            let expr = self.expression()?;
            self.consume(TokenType::Semicolon, "Expected ';' after backward expression")?;
            Ok(Stmt::Backward(expr))
        } else if self.match_token(&[TokenType::AsyncCompute]) {
            self.consume(TokenType::LBrace, "Expected '{' after async_compute")?;
            Ok(Stmt::AsyncCompute(self.block()?))
        } else if self.match_token(&[TokenType::Under]) {
            self.consume(TokenType::Fluid, "Expected 'fluid' after 'under'")?;
            self.consume(TokenType::LParen, "Expected '(' after 'fluid'")?;
            let primary_type = match self.consume(TokenType::Identifier("".to_string()), "Expected primary precision type")?.token_type.clone() {
                TokenType::Identifier(s) => s,
                _ => "".to_string(),
            };
            self.consume(TokenType::Comma, "Expected ','")?;
            let fallback_type = match self.consume(TokenType::Identifier("".to_string()), "Expected fallback precision type")?.token_type.clone() {
                TokenType::Identifier(s) => s,
                _ => "".to_string(),
            };
            self.consume(TokenType::RParen, "Expected ')'")?;
            self.consume(TokenType::LBrace, "Expected '{'")?;
            Ok(Stmt::FluidPrecisionBlock {
                primary_type,
                fallback_type,
                block: self.block()?,
            })
        } else if self.match_token(&[TokenType::With]) {
            self.consume(TokenType::Sparsity, "Expected 'sparsity' after 'with'")?;
            self.consume(TokenType::LParen, "Expected '(' after 'sparsity'")?;
            let block_size = self.expression()?;
            self.consume(TokenType::Comma, "Expected ','")?;
            let density = self.expression()?;
            self.consume(TokenType::RParen, "Expected ')'")?;
            self.consume(TokenType::LBrace, "Expected '{'")?;
            Ok(Stmt::SparsityBlock {
                block_size,
                density,
                block: self.block()?,
            })
        } else if self.match_token(&[TokenType::AbsorbLayerWeights]) {
            self.consume(TokenType::LParen, "Expected '(' after 'absorb_layer_weights'")?;
            
            let donor_path = match self.peek().token_type.clone() {
                TokenType::StringLiteral(s) => {
                    self.advance();
                    s
                },
                _ => return Err(Diagnostic::error("Expected string literal for donor path", self.peek().span)),
            };
            
            self.consume(TokenType::Comma, "Expected ',' after donor path")?;
            
            let local_tensor = match self.peek().token_type.clone() {
                TokenType::Identifier(s) => {
                    self.advance();
                    s
                },
                _ => return Err(Diagnostic::error("Expected identifier for local tensor", self.peek().span)),
            };
            
            self.consume(TokenType::RParen, "Expected ')' after absorb_layer_weights arguments")?;
            self.consume(TokenType::Semicolon, "Expected ';' after absorb_layer_weights")?;
            
            Ok(Stmt::AbsorbWeights { donor_path, local_tensor })
        } else if self.match_token(&[TokenType::ProjectVocab]) {
            self.consume(TokenType::LParen, "Expected '(' after 'project_vocab'")?;
            
            let source_tensor = match self.peek().token_type.clone() {
                TokenType::Identifier(s) => {
                    self.advance();
                    s
                },
                _ => return Err(Diagnostic::error("Expected identifier for source tensor", self.peek().span)),
            };
            
            self.consume(TokenType::Comma, "Expected ',' after source tensor")?;
            
            let target_vocab = match self.peek().token_type.clone() {
                TokenType::Identifier(s) => {
                    self.advance();
                    s
                },
                _ => return Err(Diagnostic::error("Expected identifier for target vocab", self.peek().span)),
            };
            
            self.consume(TokenType::RParen, "Expected ')' after project_vocab arguments")?;
            self.consume(TokenType::Semicolon, "Expected ';' after project_vocab")?;
            
            Ok(Stmt::ProjectVocab { source_tensor, target_vocab })
        } else if self.match_token(&[TokenType::Emit]) {
            self.consume(TokenType::Spike, "Expected 'spike' after 'emit'")?;
            self.consume(TokenType::LParen, "Expected '(' after 'spike'")?;
            let intensity = self.expression()?;
            self.consume(TokenType::RParen, "Expected ')' after intensity expression")?;
            self.consume(TokenType::Semicolon, "Expected ';' after emit spike")?;
            Ok(Stmt::EmitSpike { intensity })
        } else {
            self.expression_statement()
        }
    }

    fn expression_statement(&mut self) -> Result<Stmt, Diagnostic> {
        let expr = self.expression()?;
        self.consume(TokenType::Semicolon, "Expected ';' after expression")?;
        Ok(Stmt::Expr(expr))
    }

    fn expression(&mut self) -> Result<Expr, Diagnostic> {
        self.assignment()
    }

    fn assignment(&mut self) -> Result<Expr, Diagnostic> {
        let expr = self.equality()?;
        if self.match_token(&[TokenType::Eq, TokenType::PlusEq, TokenType::MinusEq, TokenType::StarEq, TokenType::SlashEq]) {
            let op = self.previous().token_type.clone();
            let value = self.assignment()?;
            
            let final_value = match op {
                TokenType::Eq => value,
                TokenType::PlusEq => Expr::BinaryOp { left: Box::new(expr.clone()), op: "+".to_string(), right: Box::new(value) },
                TokenType::MinusEq => Expr::BinaryOp { left: Box::new(expr.clone()), op: "-".to_string(), right: Box::new(value) },
                TokenType::StarEq => Expr::BinaryOp { left: Box::new(expr.clone()), op: "*".to_string(), right: Box::new(value) },
                TokenType::SlashEq => Expr::BinaryOp { left: Box::new(expr.clone()), op: "/".to_string(), right: Box::new(value) },
                _ => value,
            };
            
            return Ok(Expr::Assignment {
                target: Box::new(expr),
                value: Box::new(final_value),
            });
        }
        Ok(expr)
    }

    fn equality(&mut self) -> Result<Expr, Diagnostic> {
        let mut expr = self.comparison()?;
        while self.match_token(&[TokenType::EqEq, TokenType::NotEq]) {
            let op = self.previous().lexeme.clone();
            let right = self.comparison()?;
            expr = Expr::BinaryOp { left: Box::new(expr), op, right: Box::new(right) };
        }
        Ok(expr)
    }

    fn comparison(&mut self) -> Result<Expr, Diagnostic> {
        let mut expr = self.term()?;
        while self.match_token(&[TokenType::Greater, TokenType::GreaterEq, TokenType::Less, TokenType::LessEq]) {
            let op = self.previous().lexeme.clone();
            let right = self.term()?;
            expr = Expr::BinaryOp { left: Box::new(expr), op, right: Box::new(right) };
        }
        Ok(expr)
    }

    fn term(&mut self) -> Result<Expr, Diagnostic> {
        let mut expr = self.factor()?;
        while self.match_token(&[TokenType::Plus, TokenType::Minus]) {
            let op = self.previous().lexeme.clone();
            let right = self.factor()?;
            expr = Expr::BinaryOp { left: Box::new(expr), op, right: Box::new(right) };
        }
        Ok(expr)
    }

    fn factor(&mut self) -> Result<Expr, Diagnostic> {
        let mut expr = self.matmul()?;
        while self.match_token(&[TokenType::Star, TokenType::Slash]) {
            let op = self.previous().lexeme.clone();
            let right = self.matmul()?;
            expr = Expr::BinaryOp { left: Box::new(expr), op, right: Box::new(right) };
        }
        Ok(expr)
    }
    
    fn matmul(&mut self) -> Result<Expr, Diagnostic> {
        let mut expr = self.unary()?;
        while self.match_token(&[TokenType::MatMul]) {
            let op = self.previous().lexeme.clone();
            let right = self.unary()?;
            expr = Expr::BinaryOp { left: Box::new(expr), op, right: Box::new(right) };
        }
        Ok(expr)
    }

    fn unary(&mut self) -> Result<Expr, Diagnostic> {
        if self.match_token(&[TokenType::Attention]) {
            self.consume(TokenType::LParen, "Expected '(' after @attention")?;
            let routing_tok = self.consume(TokenType::Identifier("".to_string()), "Expected routing keyword")?.clone();
            if routing_tok.lexeme != "routing" {
                return Err(Diagnostic::error("Expected 'routing'", routing_tok.span));
            }
            self.consume(TokenType::Eq, "Expected '='")?;
            let routing_val = match self.consume(TokenType::StringLiteral("".to_string()), "Expected routing string")?.token_type.clone() {
                TokenType::StringLiteral(s) => s,
                _ => "".to_string(),
            };
            self.consume(TokenType::RParen, "Expected ')'")?;
            
            let target = self.unary()?;
            return Ok(Expr::Attention { target: Box::new(target), routing: routing_val });
        }
        if self.match_token(&[TokenType::Not, TokenType::Minus]) {
            let op = self.previous().lexeme.clone();
            let right = self.unary()?;
            return Ok(Expr::UnaryOp { op, right: Box::new(right) });
        }
        self.call()
    }

    fn call(&mut self) -> Result<Expr, Diagnostic> {
        let mut expr = self.primary()?;
        loop {
            if self.match_token(&[TokenType::LParen]) {
                let mut args = Vec::new();
                if !self.check(&TokenType::RParen) {
                    loop {
                        args.push(self.expression()?);
                        if !self.match_token(&[TokenType::Comma]) {
                            break;
                        }
                    }
                }
                self.consume(TokenType::RParen, "Expected ')' after arguments")?;
                if let Expr::Identifier(name) = expr {
                    if name == "mse_loss" && args.len() == 2 {
                        expr = Expr::MSELoss(Box::new(args[0].clone()), Box::new(args[1].clone()));
                    } else if name == "tokenize_bpe" && args.len() == 2 {
                        if let Expr::StringLiteral(tokenizer_path) = &args[1] {
                            expr = Expr::TokenizeBPE {
                                text: Box::new(args[0].clone()),
                                tokenizer_path: tokenizer_path.clone(),
                            };
                        } else {
                            return Err(Diagnostic::error("tokenize_bpe second argument must be a string literal path to tokenizer.json", self.previous().span));
                        }
                    } else if name == "align_spans" && args.len() == 3 {
                        if let (Expr::StringLiteral(vocab_a), Expr::StringLiteral(vocab_b)) = (&args[0], &args[1]) {
                            expr = Expr::AlignSpans {
                                vocab_a: vocab_a.clone(),
                                vocab_b: vocab_b.clone(),
                                projection_matrix: Box::new(args[2].clone()),
                            };
                        } else {
                            return Err(Diagnostic::error("align_spans first two arguments must be string literal paths to vocab files", self.previous().span));
                        }
                    } else {
                        expr = Expr::FunctionCall { name, args };
                    }
                } else {
                    return Err(Diagnostic::error("Can only call functions by name", self.previous().span));
                }
            } else if self.match_token(&[TokenType::Dot]) {
                let name = match self.consume(TokenType::Identifier("".to_string()), "Expected property name after '.'")?.token_type.clone() {
                    TokenType::Identifier(s) => s,
                    _ => return Err(Diagnostic::error("Expected identifier", self.previous().span)),
                };
                if self.match_token(&[TokenType::LParen]) {
                    let mut args = Vec::new();
                    if !self.check(&TokenType::RParen) {
                        loop {
                            args.push(self.expression()?);
                            if !self.match_token(&[TokenType::Comma]) {
                                break;
                            }
                        }
                    }
                    self.consume(TokenType::RParen, "Expected ')' after arguments")?;

                    if let Expr::Identifier(obj_name) = &expr {
                        if obj_name == "Cartan" {
                            if name == "lex_and_embed" && args.len() == 1 {
                                expr = Expr::LexAndEmbed(Box::new(args[0].clone()));
                                continue;
                            } else if name == "align_geodesics" && args.len() == 2 {
                                expr = Expr::AlignGeodesics(Box::new(args[0].clone()), Box::new(args[1].clone()));
                                continue;
                            } else if name == "GeometricBridge" && args.len() == 2 {
                                expr = Expr::GeometricBridge(Box::new(args[0].clone()), Box::new(args[1].clone()));
                                continue;
                            } else if name == "transpose_weights" && args.len() == 2 {
                                expr = Expr::TransposeWeights(Box::new(args[0].clone()), Box::new(args[1].clone()));
                                continue;
                            } else if name == "reflect_repo" && args.len() == 0 {
                                expr = Expr::ReflectRepo;
                                continue;
                            } else if name == "hot_swap" && args.len() == 2 {
                                expr = Expr::HotSwap(Box::new(args[0].clone()), Box::new(args[1].clone()));
                                continue;
                            }
                        }
                    }

                    expr = Expr::MethodCall {
                        object: Box::new(expr),
                        method_name: name,
                        args,
                    };
                } else {
                    expr = Expr::PropertyAccess {
                        object: Box::new(expr),
                        property_name: name,
                    };
                }

            } else if self.match_token(&[TokenType::LBracket]) {
                let index = self.expression()?;
                self.consume(TokenType::RBracket, "Expected ']' after index")?;
                expr = Expr::IndexAccess {
                    object: Box::new(expr),
                    index: Box::new(index),
                };
            } else {
                break;
            }
        }
        Ok(expr)
    }

    
    fn primary(&mut self) -> Result<Expr, Diagnostic> {
        if self.match_token(&[TokenType::Stream]) {
            let mut modalities = Vec::new();
            if self.match_token(&[TokenType::LBracket]) {
                if !self.check(&TokenType::RBracket) {
                    loop {
                        let mut m_str = String::new();
                        while !self.check(&TokenType::Comma) && !self.check(&TokenType::RBracket) && !self.is_at_end() {
                            let tok = self.advance().clone();
                            m_str.push_str(&tok.lexeme);
                        }
                        if m_str.is_empty() {
                            return Err(Diagnostic::error("Expected modality identifier", self.previous().span));
                        }
                        modalities.push(m_str);
                        if !self.match_token(&[TokenType::Comma]) {
                            break;
                        }
                    }
                }
                self.consume(TokenType::RBracket, "Expected ']' after modalities")?;
            }
            self.consume(TokenType::LParen, "Expected '(' after 'stream'")?;
            let uri = match self.consume(TokenType::StringLiteral("".to_string()), "Expected stream URI string")?.token_type.clone() {
                TokenType::StringLiteral(s) => s,
                _ => return Err(Diagnostic::error("Expected string literal", self.previous().span)),
            };
            self.consume(TokenType::RParen, "Expected ')' after stream URI")?;
            return Ok(Expr::StreamInit { modalities, uri });
        }
        
        if self.match_token(&[TokenType::SievingCache]) {
            self.consume(TokenType::LParen, "Expected '(' after SievingCache")?;
            self.consume(TokenType::RParen, "Expected ')' after SievingCache")?;
            return Ok(Expr::SievingCacheInit);
        }
        
        if self.match_token(&[TokenType::FractalAttentionBlock]) {
            self.consume(TokenType::LParen, "Expected '(' after FractalAttentionBlock")?;
            self.consume(TokenType::RParen, "Expected ')' after FractalAttentionBlock")?;
            return Ok(Expr::FractalAttentionInit);
        }

        if self.match_token(&[TokenType::ElasticVocabulary]) {
            self.consume(TokenType::LParen, "Expected '(' after ElasticVocabulary")?;
            self.consume(TokenType::RParen, "Expected ')' after ElasticVocabulary")?;
            return Ok(Expr::ElasticVocabularyInit);
        }

        if self.match_token(&[TokenType::Spike]) {
            return Ok(Expr::SpikePrimitive);
        }

        if self.match_token(&[TokenType::LBracket]) {
            let mut elements = Vec::new();
            if !self.check(&TokenType::RBracket) {
                loop {
                    elements.push(self.expression()?);
                    if !self.match_token(&[TokenType::Comma]) {
                        break;
                    }
                }
            }
            self.consume(TokenType::RBracket, "Expected ']' after array elements")?;
            return Ok(Expr::ArrayDecl { elements });
        }

        if self.match_token(&[TokenType::Neuron]) {
            return Ok(Expr::NeuronPrimitive);
        }

        if self.match_token(&[TokenType::BoolLiteral(false)]) {
            return Ok(Expr::Boolean(self.previous().lexeme == "true"));
        }
        
        let token = self.advance().clone();
        match token.token_type {
            TokenType::IntLiteral(n) => Ok(Expr::Integer(n)),
            TokenType::FloatLiteral(n) => Ok(Expr::Float(n)),
            TokenType::StringLiteral(s) => Ok(Expr::StringLiteral(s)),
            TokenType::Identifier(s) => Ok(Expr::Identifier(s)),
            _ => Err(Diagnostic::error("Expected expression", token.span)),
        }
    }
}
