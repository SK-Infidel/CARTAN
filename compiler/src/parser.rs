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

        let mut is_lazy = false;
        let mut is_unified = false;
        let mut is_latent = false;
        while self.check(&TokenType::Lazy) || self.check(&TokenType::Unified) || self.check(&TokenType::Latent) {
            if self.match_token(&[TokenType::Lazy]) { is_lazy = true; }
            if self.match_token(&[TokenType::Unified]) { is_unified = true; }
            if self.match_token(&[TokenType::Latent]) { is_latent = true; }
        }

        if self.match_token(&[TokenType::Macro]) {
            self.macro_declaration()
        } else if self.match_token(&[TokenType::Extern]) {
            self.extern_function_declaration()
        } else if self.match_token(&[TokenType::Fn]) {
            self.function_declaration(is_agent_accessible)
        } else if self.match_token(&[TokenType::Struct]) {
            self.struct_declaration()
        } else if self.match_token(&[TokenType::Ptr]) {
            self.var_declaration(false)
        } else if self.match_token(&[TokenType::Var]) {
            self.var_declaration(false)
        } else if self.match_token(&[TokenType::Let]) {
            self.var_declaration(false)
        } else if self.match_token(&[TokenType::Const]) {
            self.var_declaration(true)
        } else if self.match_token(&[TokenType::Tensor]) {
            self.tensor_declaration(is_lazy, is_unified, is_latent)
        } else if self.match_token(&[TokenType::Vector]) {
            self.vector_declaration()
        } else if self.match_token(&[TokenType::Parameter]) {
            self.parameter_declaration()
        } else if self.match_token(&[TokenType::Sequence]) {
            self.sequence_declaration()
        } else if self.match_token(&[TokenType::Struct]) {
            self.struct_declaration()
        } else if self.match_token(&[TokenType::Import]) {
            self.import_declaration()
        } else if self.match_token(&[TokenType::Pipeline]) {
            self.pipeline_declaration()
        } else if self.match_token(&[TokenType::Layer]) {
            self.layer_declaration()
        } else if self.match_token(&[TokenType::Graph]) {
            self.graph_declaration()
        } else if self.match_token(&[TokenType::Rule]) {
            self.rule_declaration()
        } else if self.match_token(&[TokenType::KnowledgeBase]) {
            self.knowledge_base_declaration()
        } else if self.match_token(&[TokenType::Evolve]) {
            self.evolve_declaration()
        } else if self.match_token(&[TokenType::Spawn]) {
            self.spawn_declaration()
        } else if self.match_token(&[TokenType::Trait]) {
            self.trait_declaration()
        } else if self.match_token(&[TokenType::Impl]) {
            self.impl_declaration()
        } else if self.match_token(&[TokenType::Receive]) {
            self.receive_declaration()
        } else if self.match_token(&[TokenType::Satisfy]) {
            let condition = self.expression()?;
            self.consume(TokenType::LBrace, "Expected '{' before satisfy body")?;
            let body = self.block()?;
            let mut otherwise = None;
            if self.match_token(&[TokenType::Otherwise]) {
                self.consume(TokenType::LBrace, "Expected '{' before otherwise body")?;
                otherwise = Some(self.block()?);
            }
            Ok(Stmt::Satisfy { condition, body, otherwise })
        } else if self.match_token(&[TokenType::Dataframe]) {
            self.dataframe_declaration()
        } else if self.match_token(&[TokenType::Jit]) {
            self.consume(TokenType::LBrace, "Expected '{' after 'jit'")?;
            let body = self.block()?;
            Ok(Stmt::JitBlock(body))
        } else if self.match_token(&[TokenType::Block]) {
            self.block_declaration()
        } else if self.match_token(&[TokenType::Lattice]) {
            self.lattice_declaration()
        } else if self.match_token(&[TokenType::Tree]) {
            self.tree_declaration()
        } else if self.match_token(&[TokenType::Manifold]) {
            self.manifold_declaration()
        } else if self.match_token(&[TokenType::Mesh]) {
            let name = match self.consume(TokenType::Identifier("".to_string()), "Expected mesh identifier")?.token_type.clone() {
                TokenType::Identifier(id) => id,
                _ => return Err(Diagnostic::error("Expected identifier", self.peek().span)),
            };
            self.consume(TokenType::Supervisor, "Expected 'supervisor' after mesh name")?;
            self.consume(TokenType::LParen, "Expected '(' after 'supervisor'")?;
            let strategy = match self.consume(TokenType::StringLiteral("".to_string()), "Expected supervisor strategy string")?.token_type.clone() {
                TokenType::StringLiteral(s) => s,
                _ => return Err(Diagnostic::error("Expected string literal", self.peek().span)),
            };
            self.consume(TokenType::RParen, "Expected ')' after supervisor strategy")?;
            self.consume(TokenType::LBrace, "Expected '{' after mesh supervisor")?;
            let body = self.block()?;
            Ok(Stmt::MeshBlock { name, strategy, body })
        } else if self.match_token(&[TokenType::Multimodal]) {
            self.consume(TokenType::LBrace, "Expected '{' after 'multimodal'")?;
            let body = self.block()?;
            Ok(Stmt::MultimodalBlock { body })
        } else if self.match_token(&[TokenType::Vmap]) {
            self.consume(TokenType::LBrace, "Expected '{' after 'vmap'")?;
            let body = self.block()?;
            Ok(Stmt::VmapBlock { body })
        } else if self.match_token(&[TokenType::Doubt]) {
            self.consume(TokenType::LBrace, "Expected '{' after 'doubt'")?;
            let body = self.block()?;
            Ok(Stmt::DoubtBlock { body })
        } else if self.match_token(&[TokenType::Chain]) {
            self.consume(TokenType::LBrace, "Expected '{' after 'chain'")?;
            let body = self.block()?;
            Ok(Stmt::ChainBlock { body })
        } else if self.match_token(&[TokenType::Route]) {
            self.consume(TokenType::LBrace, "Expected '{' after 'route'")?;
            let body = self.block()?;
            Ok(Stmt::RouteBlock { body })
        } else if self.match_token(&[TokenType::Grok]) {
            self.consume(TokenType::LBrace, "Expected '{' after 'grok'")?;
            let body = self.block()?;
            Ok(Stmt::GrokBlock { body })
        } else if self.match_token(&[TokenType::Override]) {
            self.consume(TokenType::LBrace, "Expected '{' after 'override'")?;
            let body = self.block()?;
            Ok(Stmt::OverrideBlock { body })
        } else if self.match_token(&[TokenType::Tool]) {
            if let Stmt::FunctionDecl(decl) = self.function_declaration(false)? {
                Ok(Stmt::ToolDecl(decl))
            } else {
                Err(Diagnostic::error("Expected function declaration after 'tool'", self.peek().span))
            }
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
        let path_token = self.consume(TokenType::StringLiteral(String::new()), "Expected string literal for import path/uri")?;
        let path = match path_token.token_type.clone() {
            TokenType::StringLiteral(s) => s,
            _ => return Err(Diagnostic::error("Expected string literal for import path/uri", path_token.span)),
        };
        
        if self.match_token(&[TokenType::As]) {
            let alias_token = self.consume(TokenType::Identifier("".to_string()), "Expected alias after 'as'")?.clone();
            let alias = match alias_token.token_type {
                TokenType::Identifier(s) => s,
                _ => return Err(Diagnostic::error("Expected alias identifier", alias_token.span)),
            };
            self.consume(TokenType::Semicolon, "Expected ';' after import statement")?;
            Ok(Stmt::ImportModel { uri: path, alias })
        } else {
            self.consume(TokenType::Semicolon, "Expected ';' after import path")?;
            Ok(Stmt::Import { filepath: path })
        }
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
    
    fn tensor_declaration(&mut self, is_lazy: bool, is_unified: bool, is_latent: bool) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected tensor name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected tensor name", name_token.span)),
        };
        self.tensor_declaration_with_name(name, false, None, is_lazy, is_unified, is_latent)
    }

    fn vector_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected vector name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected vector name", name_token.span)),
        };

        self.consume(TokenType::LBracket, "Expected '[' after vector name")?;
        
        let mut data_type = None;
        let mut dim_expr = None;

        // If the first thing is an identifier followed by a comma, it's the data type (e.g. f32, 16)
        if let TokenType::Identifier(ref dt) = self.peek().token_type {
            let next_is_comma = if self.current + 1 < self.tokens.len() {
                self.tokens[self.current + 1].token_type == TokenType::Comma
            } else {
                false
            };
            if next_is_comma {
                data_type = Some(dt.clone());
                self.advance(); // consume identifier
                self.advance(); // consume comma
            }
        }

        dim_expr = Some(self.expression()?);
        
        self.consume(TokenType::RBracket, "Expected ']' after vector dimension")?;

        let mut space = crate::ast::VectorSpace::AmbientEuclidean;
        if self.match_token(&[TokenType::At]) {
            let anchor_token = self.consume(TokenType::Identifier("".to_string()), "Expected anchor variable name after 'at'")?.clone();
            let anchor_name = match anchor_token.token_type {
                TokenType::Identifier(s) => s,
                _ => return Err(Diagnostic::error("Expected anchor variable name", anchor_token.span)),
            };
            space = crate::ast::VectorSpace::TangentSpace { anchor: anchor_name };
        }

        self.consume(TokenType::Semicolon, "Expected ';' after vector declaration")?;

        Ok(Stmt::VectorDecl {
            name,
            data_type,
            dim: dim_expr.unwrap(),
            space,
        })
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

    fn lattice_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected lattice name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected lattice name", name_token.span)),
        };
        self.consume(TokenType::LBracket, "Expected '[' after lattice name")?;
        let lattice_type_token = self.consume(TokenType::Identifier("".to_string()), "Expected lattice type (e.g. E8, Boolean)")?.clone();
        let lattice_type = match lattice_type_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected lattice type", lattice_type_token.span)),
        };
        self.consume(TokenType::Comma, "Expected ',' after lattice type")?;
        let dim = self.expression()?;
        self.consume(TokenType::RBracket, "Expected ']' after lattice dimension")?;
        self.consume(TokenType::Semicolon, "Expected ';' after lattice declaration")?;
        Ok(Stmt::LatticeDecl { name, lattice_type, dim })
    }

    fn tree_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected tree name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected tree name", name_token.span)),
        };
        self.consume(TokenType::Less, "Expected '<' after tree name")?;
        let element_type_token = self.consume(TokenType::Identifier("".to_string()), "Expected tree element type (e.g. tensor)")?.clone();
        let element_type = match element_type_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected tree element type", element_type_token.span)),
        };
        self.consume(TokenType::Greater, "Expected '>' after tree element type")?;
        self.consume(TokenType::Semicolon, "Expected ';' after tree declaration")?;
        Ok(Stmt::TreeDecl { name, element_type })
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
        self.tensor_declaration_with_name(name, true, optimizer, false, false, false)
    }

    fn tensor_declaration_with_name(&mut self, name: String, is_parameter: bool, optimizer: Option<crate::ast::OptimizerState>, is_lazy: bool, is_unified: bool, is_latent: bool) -> Result<Stmt, Diagnostic> {
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
        



        if self.match_token(&[TokenType::Under]) {
            self.consume(TokenType::Identifier("".to_string()), "Expected precision type after 'under'")?;
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
                is_lazy,
                is_unified,
                is_latent,
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




    fn pipeline_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected pipeline name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected pipeline name", name_token.span)),
        };

        self.consume(TokenType::LBrace, "Expected '{' before pipeline body")?;
        let mut layers = Vec::new();
        while !self.check(&TokenType::RBrace) && !self.is_at_end() {
            layers.push(self.expression()?);
            if !self.check(&TokenType::RBrace) {
                self.consume(TokenType::Comma, "Expected ',' between pipeline layers")?;
            }
        }
        self.consume(TokenType::RBrace, "Expected '}' after pipeline body")?;
        
        Ok(Stmt::PipelineDecl { name, layers })
    }

    fn layer_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected layer name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected layer name", name_token.span)),
        };
        self.consume(TokenType::Eq, "Expected '=' after layer name")?;
        
        let layer_type_tok = self.consume(TokenType::Identifier("".to_string()), "Expected layer type")?.clone();
        let layer_type = match layer_type_tok.token_type {
            TokenType::Identifier(s) => s,
            _ => "".to_string(),
        };
        self.consume(TokenType::LParen, "Expected '('")?;
        let dim = self.expression()?;
        self.consume(TokenType::Comma, "Expected ','")?;
        let act_tok = self.consume(TokenType::Identifier("".to_string()), "Expected activation")?.clone();
        let activation = match act_tok.token_type {
            TokenType::Identifier(s) => s,
            _ => "".to_string(),
        };
        self.consume(TokenType::RParen, "Expected ')'")?;

        self.consume(TokenType::Semicolon, "Expected ';' after layer definition")?;
        Ok(Stmt::LayerDecl { name, layer_type, dim, activation })
    }

    fn graph_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected graph name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected graph name", name_token.span)),
        };
        self.consume(TokenType::LBrace, "Expected '{' before graph body")?;
        let body = self.block()?;
        Ok(Stmt::GraphDecl { name, body })
    }

    fn rule_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected rule name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected rule name", name_token.span)),
        };
        self.consume(TokenType::Eq, "Expected '=' after rule name")?;
        let body = self.expression()?;
        self.consume(TokenType::Semicolon, "Expected ';' after rule definition")?;
        Ok(Stmt::RuleDecl { name, body })
    }

    fn knowledge_base_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected knowledge_base name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected knowledge_base name", name_token.span)),
        };
        self.consume(TokenType::LBrace, "Expected '{' before knowledge_base body")?;
        let body = self.block()?;
        Ok(Stmt::KnowledgeBaseDecl { name, body })
    }

    fn evolve_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected evolve block name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected evolve block name", name_token.span)),
        };
        self.consume(TokenType::LBrace, "Expected '{' before evolve body")?;
        let body = self.block()?;
        Ok(Stmt::EvolveBlock { name, body })
    }

    fn receive_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name = match self.consume(TokenType::Identifier("".to_string()), "Expected message name after 'receive'")?.token_type.clone() {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected identifier", self.previous().span)),
        };

        self.consume(TokenType::LParen, "Expected '(' after message name in 'receive'")?;
        
        let mut params = Vec::new();
        if !self.check(&TokenType::RParen) {
            loop {
                let param_name = match self.consume(TokenType::Identifier("".to_string()), "Expected parameter name")?.token_type.clone() {
                    TokenType::Identifier(s) => s,
                    _ => return Err(Diagnostic::error("Expected identifier", self.previous().span)),
                };
                
                self.consume(TokenType::Colon, "Expected ':' after parameter name")?;
                
                let param_type = match self.consume(TokenType::Identifier("".to_string()), "Expected parameter type")?.token_type.clone() {
                    TokenType::Identifier(s) => s,
                    _ => return Err(Diagnostic::error("Expected identifier", self.previous().span)),
                };
                
                params.push(Parameter {
                    name: param_name,
                    type_name: param_type,
                    shape: Vec::new(),
                    manifold: None,
                    is_borrow: false,
                    is_mutable: false,
                });
                
                if !self.match_token(&[TokenType::Comma]) {
                    break;
                }
            }
        }
        self.consume(TokenType::RParen, "Expected ')' after receive parameters")?;
        
        self.consume(TokenType::LBrace, "Expected '{' before receive body")?;
        let body = self.block()?;
        
        Ok(Stmt::ReceiveDecl { message_name: name, params, body })
    }

    fn impl_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let first_name = match self.consume(TokenType::Identifier("".to_string()), "Expected identifier after 'impl'")?.token_type.clone() {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected identifier", self.previous().span)),
        };

        let mut trait_name = None;
        let target_name;

        if self.match_token(&[TokenType::For]) {
            trait_name = Some(first_name);
            target_name = match self.consume(TokenType::Identifier("".to_string()), "Expected struct name after 'for'")?.token_type.clone() {
                TokenType::Identifier(s) => s,
                _ => return Err(Diagnostic::error("Expected identifier", self.previous().span)),
            };
        } else {
            target_name = first_name;
        }

        self.consume(TokenType::LBrace, "Expected '{' before impl body")?;
        
        let mut methods = Vec::new();
        while !self.check(&TokenType::RBrace) && !self.is_at_end() {
            if self.match_token(&[TokenType::Fn]) {
                methods.push(self.function_declaration(false)?);
            } else {
                return Err(Diagnostic::error("Expected 'fn' inside 'impl' block", self.peek().span));
            }
        }
        
        self.consume(TokenType::RBrace, "Expected '}' after impl body")?;
        Ok(Stmt::ImplDecl { trait_name, target_name, methods })
    }

    fn trait_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name = match self.consume(TokenType::Identifier("".to_string()), "Expected trait name")?.token_type.clone() {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected identifier", self.previous().span)),
        };

        self.consume(TokenType::LBrace, "Expected '{' before trait body")?;
        
        let mut methods = Vec::new();
        while !self.check(&TokenType::RBrace) && !self.is_at_end() {
            if self.match_token(&[TokenType::Fn]) {
                methods.push(self.function_declaration(false)?);
            } else {
                return Err(Diagnostic::error("Expected 'fn' inside 'trait' block", self.peek().span));
            }
        }
        
        self.consume(TokenType::RBrace, "Expected '}' after trait body")?;
        Ok(Stmt::TraitDecl { name, methods })
    }

    fn spawn_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected spawn target name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected spawn target name", name_token.span)),
        };
        self.consume(TokenType::LBrace, "Expected '{' before spawn body")?;
        let body = self.block()?;
        Ok(Stmt::Spawn { name, body })
    }

    fn dataframe_declaration(&mut self) -> Result<Stmt, Diagnostic> {
        let name_token = self.consume(TokenType::Identifier("".to_string()), "Expected dataframe name")?.clone();
        let name = match name_token.token_type {
            TokenType::Identifier(s) => s,
            _ => return Err(Diagnostic::error("Expected dataframe name", name_token.span)),
        };
        self.consume(TokenType::LBrace, "Expected '{' before dataframe body")?;
        let body = self.block()?;
        Ok(Stmt::DataframeDecl { name, body })
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
            let field_name_token = self.consume(TokenType::Identifier("".to_string()), "Expected field name")?.clone();
            let field_name = match field_name_token.token_type {
                TokenType::Identifier(s) => s,
                _ => return Err(Diagnostic::error("Expected field name", field_name_token.span)),
            };
            self.consume(TokenType::Colon, "Expected ':' after field name")?;
            let mut type_name = String::new();
            if self.match_token(&[TokenType::Tree]) {
                type_name.push_str("tree");
                if self.match_token(&[TokenType::Less]) {
                    type_name.push('<');
                    let inner = self.consume(TokenType::Identifier("".to_string()), "Expected inner type for tree")?.clone();
                    if let TokenType::Identifier(s) = inner.token_type { type_name.push_str(&s); }
                    self.consume(TokenType::Greater, "Expected '>' for tree type")?;
                    type_name.push('>');
                }
            } else {
                let type_token = self.consume(TokenType::Identifier("".to_string()), "Expected type name")?.clone();
                match type_token.token_type {
                    TokenType::Identifier(s) => type_name = s,
                    _ => return Err(Diagnostic::error("Expected type name", type_token.span)),
                }
            }
            self.consume(TokenType::Semicolon, "Expected ';' after field declaration")?;
            fields.push(Stmt::FieldDecl { name: field_name, type_name });
        }
        
        self.consume(TokenType::RBrace, "Expected '}' after struct body")?;
        
        Ok(Stmt::StructDecl { name, fields })
    }



    fn macro_declaration(&mut self) -> Result<Stmt, Diagnostic> {
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

    fn parse_type_string(&mut self) -> Result<String, Diagnostic> {
        if self.match_token(&[TokenType::Tensor]) {
            return Ok("tensor".to_string());
        }
        if self.match_token(&[TokenType::Sequence]) {
            return Ok("sequence".to_string());
        }
        if self.match_token(&[TokenType::Tree]) {
            let mut ty = "tree".to_string();
            if self.match_token(&[TokenType::Less]) {
                ty.push('<');
                let inner = match self.consume(TokenType::Identifier("".to_string()), "Expected inner type parameter")?.token_type.clone() {
                    TokenType::Identifier(s) => s,
                    _ => "".to_string(),
                };
                ty.push_str(&inner);
                self.consume(TokenType::Greater, "Expected '>' after type parameter")?;
                ty.push('>');
            }
            return Ok(ty);
        }
        
        let token = self.peek().clone();
        match &token.token_type {
            TokenType::Identifier(s) => {
                let ty = s.clone();
                self.advance();
                Ok(ty)
            },
            _ => {
                Err(Diagnostic::error("Expected parameter type", token.span))
            }
        }
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
                
                let p_type = self.parse_type_string()?;
                
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
                    shape: Vec::new(),
                    manifold: p_manifold,
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
            return_type = Some(self.parse_type_string()?);
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
                
                let p_type = self.parse_type_string()?;
                
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
                    shape: Vec::new(),
                    manifold: p_manifold,
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
            return_type = Some(self.parse_type_string()?);
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

        let mut type_annotation = None;
        if self.match_token(&[TokenType::Colon]) {
            let ty = self.consume(TokenType::Identifier("".to_string()), "Expected type annotation")?.clone();
            if let TokenType::Identifier(t) = ty.token_type {
                type_annotation = Some(t);
            }
        }

        let value = if self.match_token(&[TokenType::Eq]) {
            if self.match_token(&[TokenType::Tensor]) {
                return self.tensor_declaration_with_name(name, false, None, false, false, false);
            }
            if self.match_token(&[TokenType::Parameter]) {
                return self.tensor_declaration_with_name(name, true, None, false, false, false);
            }
            self.expression()?
        } else {
            Expr::Boolean(false)
        };

        self.consume(TokenType::Semicolon, "Expected ';' after variable declaration")?;
        Ok(Stmt::VarDecl { name, is_const, type_annotation, value })
    }

    fn statement(&mut self) -> Result<Stmt, Diagnostic> {
        if self.match_token(&[TokenType::LBrace]) {
            Ok(Stmt::Block(self.block()?))
        } else if self.match_token(&[TokenType::While]) {
            let has_paren = self.match_token(&[TokenType::LParen]);
            let condition = self.expression()?;
            if has_paren {
                self.consume(TokenType::RParen, "Expected ')' after while condition")?;
            }
            self.consume(TokenType::LBrace, "Expected '{' after while condition")?;
            let body = self.block()?;
            Ok(Stmt::While { condition, body })
        } else if self.match_token(&[TokenType::If]) {
            let has_paren = self.match_token(&[TokenType::LParen]);
            let condition = self.expression()?;
            if has_paren {
                self.consume(TokenType::RParen, "Expected ')' after if condition")?;
            }
            self.consume(TokenType::LBrace, "Expected '{' after if condition")?;
            let true_block = self.block()?;
            let mut false_block = None;
            if self.match_token(&[TokenType::Else]) {
                if self.check(&TokenType::If) {
                    let if_stmt = self.statement()?;
                    false_block = Some(BlockStmt { statements: vec![if_stmt] });
                } else {
                    self.consume(TokenType::LBrace, "Expected '{' after 'else'")?;
                    false_block = Some(self.block()?);
                }
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
        } else if self.match_token(&[TokenType::Backtrack]) {
            self.consume(TokenType::Semicolon, "Expected ';' after backtrack")?;
            Ok(Stmt::Backtrack)
        } else if self.match_token(&[TokenType::Satisfy]) {
            let condition = self.expression()?;
            self.consume(TokenType::LBrace, "Expected '{' after satisfy condition")?;
            let body = self.block()?;
            let mut otherwise = None;
            if self.match_token(&[TokenType::Otherwise]) {
                self.consume(TokenType::LBrace, "Expected '{' after otherwise")?;
                otherwise = Some(self.block()?);
            }
            Ok(Stmt::Satisfy { condition, body, otherwise })
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
        let expr = self.logical_or()?;
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

    fn logical_or(&mut self) -> Result<Expr, Diagnostic> {
        let mut expr = self.logical_and()?;
        while self.match_token(&[TokenType::Or]) {
            let op = "||".to_string();
            let right = self.logical_and()?;
            expr = Expr::BinaryOp { left: Box::new(expr), op, right: Box::new(right) };
        }
        Ok(expr)
    }

    fn logical_and(&mut self) -> Result<Expr, Diagnostic> {
        let mut expr = self.equality()?;
        while self.match_token(&[TokenType::And]) {
            let op = "&&".to_string();
            let right = self.equality()?;
            expr = Expr::BinaryOp { left: Box::new(expr), op, right: Box::new(right) };
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
        if self.match_token(&[TokenType::Ampersand]) {
            let right = self.unary()?;
            return Ok(Expr::AddressOf(Box::new(right)));
        }
        if self.match_token(&[TokenType::Star]) {
            let right = self.unary()?;
            return Ok(Expr::Dereference(Box::new(right)));
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
                    if let Expr::Identifier(ref obj_name) = expr {
                        if obj_name == "Cartan" && name == "parallel_transport" {
                            let vector_expr = self.expression()?;
                            self.consume(TokenType::Comma, "Expected ','")?;
                            self.consume(TokenType::From, "Expected 'from'")?;
                            self.consume(TokenType::Colon, "Expected ':'")?;
                            let from_expr = self.expression()?;
                            self.consume(TokenType::Comma, "Expected ','")?;
                            self.consume(TokenType::To, "Expected 'to'")?;
                            self.consume(TokenType::Colon, "Expected ':'")?;
                            let to_expr = self.expression()?;
                            self.consume(TokenType::RParen, "Expected ')' after parallel_transport")?;
                            
                            expr = Expr::ParallelTransport {
                                vector: Box::new(vector_expr),
                                from: Box::new(from_expr),
                                to: Box::new(to_expr),
                            };
                            continue;
                        }
                    }

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
        if self.match_token(&[TokenType::ImportOnnx]) {
            self.consume(TokenType::LParen, "Expected '(' after import_onnx!")?;
            let path = match self.consume(TokenType::StringLiteral("".to_string()), "Expected ONNX path")?.token_type.clone() {
                TokenType::StringLiteral(s) => s,
                _ => return Err(Diagnostic::error("Expected string literal", self.previous().span)),
            };
            self.consume(TokenType::RParen, "Expected ')'")?;
            // Conceptual stub for ONNX import. We parse it as a function call to a built-in macro handler.
            return Ok(Expr::FunctionCall {
                name: "cartan_internal_import_onnx".to_string(),
                args: vec![Expr::StringLiteral(path)]
            });
        }

        if self.match_token(&[TokenType::Quantize]) {
            self.consume(TokenType::LParen, "Expected '(' after quantize")?;
            let target = self.expression()?;
            self.consume(TokenType::Comma, "Expected ','")?;
            let dtype = match self.consume(TokenType::Identifier("".to_string()), "Expected dtype (e.g. INT8)")?.token_type.clone() {
                TokenType::Identifier(s) => s,
                _ => return Err(Diagnostic::error("Expected dtype identifier", self.previous().span)),
            };
            self.consume(TokenType::RParen, "Expected ')'")?;
            return Ok(Expr::Quantize { target: Box::new(target), dtype });
        }

        let mut is_riemannian = false;
        if self.match_token(&[TokenType::Riemannian]) {
            is_riemannian = true;
        }

        if self.match_token(&[TokenType::Grad, TokenType::Vmap]) {
            let op = self.previous().lexeme.clone();
            if self.check(&TokenType::LParen) {
                self.consume(TokenType::LParen, "Expected '('")?;
                let target = self.expression()?;
                self.consume(TokenType::RParen, "Expected ')'")?;
                return Ok(Expr::Transform { op, target: Box::new(target) }); // NOTE: riemannian should be in AST if it matters
            } else {
                return Ok(Expr::Identifier(op)); // Normal identifier fallback
            }
        } else if is_riemannian {
            return Err(Diagnostic::error("Expected 'grad' after 'riemannian'", self.peek().span));
        }

        if self.match_token(&[TokenType::ProjectVocab]) {
            self.consume(TokenType::LParen, "Expected '(' after 'project_vocab'")?;
            let source = self.expression()?;
            self.consume(TokenType::Comma, "Expected ',' between arguments")?;
            let target = self.expression()?;
            self.consume(TokenType::RParen, "Expected ')'")?;
            return Ok(Expr::ProjectVocab { source: Box::new(source), target: Box::new(target) });
        }

        if self.match_token(&[TokenType::WeightDecay]) {
            self.consume(TokenType::LParen, "Expected '(' after 'weight_decay'")?;
            let target = self.expression()?;
            self.consume(TokenType::Comma, "Expected ',' between arguments")?;
            let amount = match self.consume(TokenType::FloatLiteral(0.0), "Expected float literal for weight decay amount")?.token_type.clone() {
                TokenType::FloatLiteral(f) => f,
                TokenType::IntLiteral(i) => i as f64,
                _ => return Err(Diagnostic::error("Expected float literal", self.peek().span)),
            };
            self.consume(TokenType::RParen, "Expected ')'")?;
            return Ok(Expr::WeightDecay { target: Box::new(target), amount });
        }

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
            TokenType::Search => {
                self.consume(TokenType::LParen, "Expected '(' after 'search'")?;
                let algorithm = match self.consume(TokenType::Identifier("".to_string()), "Expected algorithm name (e.g., MCTS)")?.token_type.clone() {
                    TokenType::Identifier(s) => s,
                    _ => return Err(Diagnostic::error("Expected identifier for algorithm", self.previous().span)),
                };
                self.consume(TokenType::Comma, "Expected ',' after algorithm")?;
                let tree = self.expression()?;
                
                let mut state = None;
                if self.match_token(&[TokenType::Comma]) {
                    state = Some(Box::new(self.expression()?));
                }
                
                self.consume(TokenType::RParen, "Expected ')' after search arguments")?;
                Ok(Expr::TreeSearch {
                    tree: Box::new(tree),
                    algorithm,
                    state,
                })
            },
            TokenType::HotSwap => {
                self.consume(TokenType::LParen, "Expected '(' after hotswap")?;
                let target = self.expression()?;
                self.consume(TokenType::Comma, "Expected ',' between target and new_graph")?;
                let new_graph = self.expression()?;
                self.consume(TokenType::RParen, "Expected ')' after hotswap arguments")?;
                Ok(Expr::HotSwap(Box::new(target), Box::new(new_graph)))
            },
            TokenType::Lazy => {
                let expr = self.expression()?;
                Ok(Expr::Lazy { expr: Box::new(expr) })
            },
            TokenType::PagedAttention => {
                self.consume(TokenType::LParen, "Expected '(' after paged_attention")?;
                let query = self.expression()?;
                self.consume(TokenType::Comma, "Expected ','")?;
                let key = self.expression()?;
                self.consume(TokenType::Comma, "Expected ','")?;
                let value = self.expression()?;
                self.consume(TokenType::RParen, "Expected ')'")?;
                Ok(Expr::PagedAttention {
                    query: Box::new(query),
                    key: Box::new(key),
                    value: Box::new(value),
                })
            },
            TokenType::LParen => {
                let expr = self.expression()?;
                self.consume(TokenType::RParen, "Expected ')' after expression")?;
                Ok(expr)
            },
            TokenType::IntLiteral(n) => Ok(Expr::Integer(n)),
            TokenType::FloatLiteral(n) => Ok(Expr::Float(n)),
            TokenType::StringLiteral(s) => Ok(Expr::StringLiteral(s)),
            TokenType::PromptLiteral(s) => Ok(Expr::PromptLiteral(s)),
            TokenType::Identifier(s) => {
                if self.match_token(&[TokenType::LBrace]) {
                    let mut fields = Vec::new();
                    while !self.check(&TokenType::RBrace) && !self.is_at_end() {
                        let field_name = match self.consume(TokenType::Identifier("".to_string()), "Expected field name in struct init")?.token_type.clone() {
                            TokenType::Identifier(id) => id,
                            _ => return Err(Diagnostic::error("Expected identifier", self.previous().span)),
                        };
                        self.consume(TokenType::Colon, "Expected ':' after field name")?;
                        let val = self.expression()?;
                        fields.push((field_name, Box::new(val)));
                        if !self.match_token(&[TokenType::Comma]) {
                            break;
                        }
                    }
                    self.consume(TokenType::RBrace, "Expected '}' after struct init")?;
                    Ok(Expr::StructInit { name: s, fields })
                } else {
                    Ok(Expr::Identifier(s))
                }
            },
            TokenType::Placeholder(s) => Ok(Expr::Placeholder(s)),
            TokenType::Quote => {
                self.consume(TokenType::LBrace, "Expected '{' after 'quote'")?;
                let block = self.block()?;
                Ok(Expr::Quote(block))
            },
            TokenType::Fuse => {
                self.consume(TokenType::LBrace, "Expected '{' after 'fuse'")?;
                let block = self.block()?;
                Ok(Expr::FusedKernel(block))
            },
            _ => Err(Diagnostic::error("Expected expression", token.span)),
        }
    }
}
