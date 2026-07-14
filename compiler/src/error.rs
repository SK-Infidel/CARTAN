use crate::token::Span;

#[derive(Debug, Clone)]
pub struct Diagnostic {
    pub message: String,
    pub span: Span,
}

impl Diagnostic {
    pub fn error(msg: &str, span: Span) -> Self {
        Self {
            message: msg.to_string(),
            span,
        }
    }
}
