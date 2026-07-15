#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Span {
    pub line: usize,
    pub col_start: usize,
    pub col_end: usize,
}

impl Span {
    pub fn new(line: usize, col_start: usize, col_end: usize) -> Self {
        Self { line, col_start, col_end }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub enum TokenType {
    // Keywords
    Fn, Let, Const, Var, Struct, Stream,
    Tensor, Parameter, Sequence, Block, Layout, Manifold, Topology, Mut, Extern,
    If, Else, While, For,
    Match, // match
    FatArrow, // =>
    Return, Break, Continue, Try, Catch, Throw, Import, In,
    AsyncCompute, Backward, Macro, Pattern, Replace,
    BackedBy, // backed_by
    Attention, // @attention
    SievingCache, // SievingCache
    FractalAttentionBlock, // FractalAttentionBlock
    ElasticVocabulary, // ElasticVocabulary
    Under, // under
    Fluid, // fluid
    With, // with
    Sparsity, // sparsity
    Emit, // emit
    Spike, // spike
    Neuron, // neuron
    AgentAccessible, // @agent_accessible
    AbsorbLayerWeights, // absorb_layer_weights
    ProjectVocab, // project_vocab
            // tokenize_bpe
             // align_spans
    Print,              // print
    Graft, // graft
    TranslationBarrier, // translation_barrier
    From, // from
    To, // to
    // Literals & Identifiers
    Identifier(String),
    IntLiteral(i64),
    FloatLiteral(f64),
    StringLiteral(String),
    BoolLiteral(bool),
    
    // Operators
    Plus, Minus, Star, Slash,
    PlusEq, MinusEq, StarEq, SlashEq,
    Eq, EqEq, NotEq, Less, LessEq, Greater, GreaterEq,
    And, Or, Not,
    Ampersand, Pipe, Caret, ShiftLeft, ShiftRight,
    AmpersandEq, PipeEq, CaretEq, ShiftLeftEq, ShiftRightEq,
    MatMul, // @
    Arrow, // ->

    // Punctuation
    LParen, RParen, LBrace, RBrace, LBracket, RBracket,
    Comma, Colon, Dot, DotDot, Semicolon,
    
    // Special Cartan Primitives
    AtLocation, // @location
    AtBackend, // @backend
    Hash, // #
    
    EOF,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Token {
    pub token_type: TokenType,
    pub lexeme: String,
    pub span: Span,
}
