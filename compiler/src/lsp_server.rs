use tower_lsp::jsonrpc::Result;
use tower_lsp::lsp_types::*;
use tower_lsp::{Client, LanguageServer};

use crate::lexer::Lexer;
use crate::parser::Parser;
use crate::type_checker::TypeChecker;

pub struct Backend {
    pub client: Client,
}

#[tower_lsp::async_trait]
impl LanguageServer for Backend {
    async fn initialize(&self, _: InitializeParams) -> Result<InitializeResult> {
        Ok(InitializeResult {
            capabilities: ServerCapabilities {
                text_document_sync: Some(TextDocumentSyncCapability::Kind(TextDocumentSyncKind::FULL)),
                ..Default::default()
            },
            ..Default::default()
        })
    }

    async fn initialized(&self, _: InitializedParams) {
        self.client
            .log_message(MessageType::INFO, "Cartan Language Server initialized!")
            .await;
    }

    async fn shutdown(&self) -> Result<()> {
        Ok(())
    }

    async fn did_open(&self, params: DidOpenTextDocumentParams) {
        self.on_change(params.text_document.uri, params.text_document.text).await;
    }

    async fn did_change(&self, mut params: DidChangeTextDocumentParams) {
        if let Some(change) = params.content_changes.pop() {
            self.on_change(params.text_document.uri, change.text).await;
        }
    }
}

impl Backend {
    async fn on_change(&self, uri: Url, text: String) {
        let mut diagnostics = Vec::new();

        // Run Lexer
        let mut lexer = Lexer::new(&text);
        let tokens = match lexer.tokenize() {
            Ok(t) => t,
            Err(e) => {
                let range = Range::new(
                    Position::new(e.span.line as u32 - 1, e.span.col_start as u32 - 1),
                    Position::new(e.span.line as u32 - 1, e.span.col_end as u32),
                );
                diagnostics.push(Diagnostic::new(
                    range,
                    Some(DiagnosticSeverity::ERROR),
                    None,
                    Some("Cartan Lexer".to_string()),
                    e.message,
                    None,
                    None,
                ));
                self.client.publish_diagnostics(uri, diagnostics, None).await;
                return;
            }
        };

        // Run Parser
        let mut parser = Parser::new(tokens);
        let ast = match parser.parse() {
            Ok(a) => a,
            Err(e) => {
                let range = Range::new(
                    Position::new(e.span.line as u32 - 1, e.span.col_start as u32 - 1),
                    Position::new(e.span.line as u32 - 1, e.span.col_end as u32),
                );
                diagnostics.push(Diagnostic::new(
                    range,
                    Some(DiagnosticSeverity::ERROR),
                    None,
                    Some("Cartan Parser".to_string()),
                    e.message,
                    None,
                    None,
                ));
                self.client.publish_diagnostics(uri, diagnostics, None).await;
                return;
            }
        };

        // Run TypeChecker
        let mut checker = TypeChecker::new();
        match checker.check(&ast) {
            Ok(_) => {}
            Err(e) => {
                let range = Range::new(
                    Position::new(e.span.line as u32 - 1, e.span.col_start as u32 - 1),
                    Position::new(e.span.line as u32 - 1, e.span.col_end as u32),
                );
                diagnostics.push(Diagnostic::new(
                    range,
                    Some(DiagnosticSeverity::ERROR),
                    None,
                    Some("Cartan TypeChecker".to_string()),
                    e.message,
                    None,
                    None,
                ));
            }
        };

        self.client.publish_diagnostics(uri, diagnostics, None).await;
    }
}
