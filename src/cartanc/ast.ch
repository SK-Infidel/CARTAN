// src/cartanc/ast.car
// AST definitions for the Cartan compiler (Self-hosted)

// ---------------------------------------------------------
// Token Kinds
// ---------------------------------------------------------
enum TokenType {
    Fn, Let, Const, Var, Struct, Stream,
    Tensor, Vector, Tree, Lattice, Parameter, Sequence, Block, Layout, Manifold, Topology, Mut, Extern,
    If, Else, While, For,
    Enum, Match, FatArrow,
    Return, Break, Continue, Try, Catch, Throw, Import, In,
    AsyncCompute, Backward, Yield, YieldTo,
    Vmap, Grad, As, Pipeline, Jit, WeightDecay, Macro, Mesh, HotSwap,
    Multimodal, Lazy, Unified, Doubt, Chain, PagedAttention, Latent, Route, Grok, Tool, Override,
    Search, Satisfy, Otherwise, Backtrack, Supervisor, Pattern, Replace, Quote, Fuse,
    BackedBy, Attention, SievingCacheKw, FractalAttentionBlockKw, ElasticVocabularyKw, Under, Fluid, With,
    Sparsity, Emit, Spike, Neuron, AgentAccessible, AbsorbLayerWeights, ProjectVocab, Filter, Print,
    Graft, TranslationBarrier, From, To, At, Ptr, ImportOnnx, Quantize, Layer, Graph, Riemannian,
    Rule, KnowledgeBase, Fuzzy, Complex32Kw, Evolve, Spawn, Dataframe, Trait, Impl, Receive,
    StringView, SimdFindFirst, SimdMaskAlpha,
    Identifier(string), IntLiteral(float), FloatLiteral(float), StringLiteral(string), PromptLiteral(string), BoolLiteral(float),
    Plus, Minus, Star, Slash, Percent, PlusEq, MinusEq, StarEq, SlashEq, PercentEq,
    DotPlusEq, DotMinusEq, DotStarEq, DotSlashEq, DotAtEq,
    Eq, EqEq, NotEq, Less, LessEq, Greater, GreaterEq, And, Or, Not,
    Ampersand, Pipe, Caret, ShiftLeft, ShiftRight, AmpersandEq, PipeEq, CaretEq, ShiftLeftEq, ShiftRightEq,
    MatMul, Arrow,
    LParen, RParen, LBrace, RBrace, LBracket, RBracket,
    Comma, Colon, DoubleColon, Dot, DotDot, Semicolon,
    AtLocation, AtBackend, AtSimd, AtInbounds, Hash, Placeholder(string), EOF,
    Include
}

struct Span {
    line: float;
    col_start: float;
    col_end: float;
    line_end: float;
}

struct Token {
    token_type: ptr;
    span: Span;
}

extern fn malloc(size: float) -> ptr;

struct AstArena {
    memory: ptr;
    capacity: float;
    offset: float;
}

fn create_ast_arena(size_bytes: float) -> ptr {
    let arena: ptr = malloc(24.0);
    return arena; 
}

fn allocate_node(arena: ptr, size: float) -> ptr {
    return malloc(size);
}

enum Expr {
    Integer(float),
    Float(float),
    Boolean(float),
    StringLiteral(string),
    PromptLiteral(string),
    ImportOnnx(string),
    Identifier(string),
    Placeholder(string),
    EnumInit(string, string, tree<ptr>),
    Match(ptr, tree<ptr>),
    Quote(ptr),
    StringView(ptr, ptr, ptr),
    SimdFindFirst(ptr, ptr),
    SimdMaskAlpha(ptr),
    StructInit(string, tree<ptr>),
    UnaryOp(string, ptr),
    BinaryOp(ptr, string, ptr),
    FunctionCall(string, tree<ptr>),
    MethodCall(ptr, string, tree<ptr>),
    StreamInit(string, tree<ptr>),
    PropertyAccess(ptr, string),
    IndexAccess(ptr, ptr),
    Assignment(ptr, ptr),
    BroadcastOp(ptr, string, ptr),
    ArrayDecl(tree<ptr>),
    DictionaryDecl(tree<ptr>),
    FusedKernel(ptr),
    Attention(ptr, ptr, ptr, ptr),
    Range(ptr, ptr),
    Graft(ptr, ptr),
    TranslationBarrier(ptr),
    TokenizeBPE(ptr, ptr),
    AlignSpans(ptr, ptr),
    TreeSearch(ptr, ptr),
    LexAndEmbed(ptr, ptr),
    AlignGeodesics(ptr, ptr),
    GeometricBridge(ptr, ptr),
    TransposeWeights(ptr),
    Transpose(ptr),
    HotSwap(ptr, ptr),
    Transform(ptr, ptr),
    Quantize(ptr, ptr),
    AddressOf(ptr),
    Dereference(ptr),
    MSELoss(ptr, ptr),
    ParallelTransport(ptr, ptr, ptr),
    Lazy(ptr),
    PagedAttention(ptr, ptr, ptr, ptr),
    ProjectVocab(ptr, ptr),
    WeightDecay(ptr, float)
}

enum Stmt {
    Placeholder(string),
    ExprStmt(ptr),
    EnumDecl(string, tree<ptr>),
    VarDecl(string, float, ptr, string),
    FieldDecl(string, string),
    StructDecl(string, tree<ptr>),
    TensorDecl(string, tree<ptr>, ptr, ptr, ptr, ptr, float, float, float, string),
    ParameterDecl(string, tree<ptr>, ptr, ptr, ptr, ptr, ptr, string),
    VectorDecl(string, string, ptr, ptr),
    SequenceDecl(string, tree<ptr>),
    BlockDecl(string, ptr),
    LatticeDecl(string, string, ptr),
    TreeDecl(string, string, tree<ptr>),
    StructDef(string, ptr),
    FunctionDecl(string, ptr, tree<ptr>, string, float, ptr),
    ExternFunctionDecl(string, tree<ptr>, string),
    MacroDecl(string, tree<ptr>, ptr),
    IfStmt(ptr, ptr, ptr),
    WhileStmt(ptr, ptr),
    ForStmt(string, ptr, ptr),
    TryCatch(ptr, string, ptr),
    Throw(ptr),
    AbsorbWeights(ptr, ptr),
    ProjectVocabStmt(ptr, ptr),
    ReturnStmt(ptr),
    BreakStmt,
    ContinueStmt,
    PipelineDecl(string, tree<ptr>),
    LayerDecl(string, string, tree<ptr>, ptr),
    GraphDecl(string, tree<ptr>),
    RuleDecl(string, ptr),
    KnowledgeBaseDecl(string, tree<ptr>),
    EvolveBlock(ptr),
    TraitDecl(string, tree<ptr>),
    ImplDecl(string, string, tree<ptr>),
    ReceiveDecl(string, ptr),
    Spawn(ptr),
    DataframeDecl(string, ptr),
    ImportModel(string, string),
    JitBlock(ptr),
    Block(ptr),
    MatchStmt(ptr, tree<ptr>),
    Import(string),
    AsyncCompute(ptr),
    Backward(ptr),
    StreamDecl(string, tree<ptr>),
    ManifoldDecl(string, ptr),
    MeshBlock(string, tree<ptr>),
    MultimodalBlock(ptr),
    VmapBlock(ptr),
    DoubtBlock(ptr),
    ChainBlock(ptr),
    RouteBlock(ptr),
    GrokBlock(ptr),
    OverrideBlock(ptr),
    ToolDecl(ptr),
    Satisfy(ptr),
    Backtrack,
    TopologyDecl(string, tree<ptr>),
    FluidPrecisionBlock(ptr),
    SparsityBlock(ptr),
    PruneGraph(ptr),
    EmitSpike(ptr),
    Include(string)
}

struct MatchArm {
    pat: ptr;
    body: ptr;
}

enum MatchPattern {
    Wildcard,
    Variant(string, string, tree<string>)
}

struct EnumVariant {
    name: string;
    fields: tree<string>;
}

struct Param {
    name: string;
    type_name: string;
}

struct GenericBound {
    name: string;
    bound: string;
}

struct BlockStmt {
    statements: tree<ptr>;
}

extern fn cartan_tree_create() -> ptr;
extern fn cartan_tree_push(t: ptr, val: ptr) -> void;
extern fn cartan_tree_push_f32(t: ptr, val: float) -> float;
extern fn cartan_tree_len(t: ptr) -> float;
extern fn cartan_tree_len_f(t: ptr) -> float;
extern fn cartan_tree_len_f32(t: ptr) -> float;
extern fn cartan_tree_get_f32(t: ptr, idx: float) -> ptr;
extern fn cartan_tree_set(t: ptr, idx: float, val: ptr) -> void;
extern fn cartan_tree_remove(t: ptr, idx: float) -> void;
extern fn cartan_string_concat(s1: string, s2: string) -> string;
extern fn cartan_string_replace(s: string, old_s: string, new_s: string) -> string;
extern fn c_cartan_string_char_at(s: string, idx: float) -> float;

fn is_uppercase(s: string) -> float {
    if (cartan_string_length(s) <= 0.0) { return 0.0; }
    let ch = c_cartan_string_char_at(s, 0.0);
    if (ch >= 65.0 && ch <= 90.0) {
        return 1.0;
    }
    return 0.0;
}


