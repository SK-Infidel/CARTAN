#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ManifoldSpace {
    Euclidean,
    Minkowski,
    PoincareDisk,
    Custom(String),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum VectorSpace {
    AmbientEuclidean,
    TangentSpace { anchor: String },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MemoryLayout {
    Default,
    SoA,
    Tiled(u32, u32),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StorageBackend {
    Memory,
    NVMe,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum OptimizerState {
    Adam,
    SGD,
}

#[derive(Debug, Clone, PartialEq)]
pub struct GenericBound {
    pub name: String,
    pub bound: String,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Parameter {
    pub name: String,
    pub type_name: String,
    pub shape: Vec<Expr>,
    pub manifold: Option<ManifoldSpace>,
    pub is_borrow: bool,
    pub is_mutable: bool,
}

#[derive(Debug, Clone, PartialEq)]
pub struct BlockStmt {
    pub statements: Vec<Stmt>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct FunctionDecl {
    pub name: String,
    pub generic_bounds: Vec<GenericBound>,
    pub parameters: Vec<Parameter>,
    pub return_type: Option<String>,
    pub is_agent_accessible: bool,
    pub body: BlockStmt,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ExternFunctionDecl {
    pub name: String,
    pub parameters: Vec<Parameter>,
    pub return_type: Option<String>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct MacroRule {
    pub name: String,
    pub pattern: BlockStmt,
    pub replace: BlockStmt,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Expr {
    Integer(i64),
    Float(f64),
    Boolean(bool),
    StringLiteral(String),
    PromptLiteral(String),
    Identifier(String),
    Placeholder(String),
    Quote(BlockStmt),
    StructInit {
        name: String,
        fields: Vec<(String, Box<Expr>)>
    },
    UnaryOp {
        op: String,
        right: Box<Expr>,
    },
    BinaryOp {
        left: Box<Expr>,
        op: String,
        right: Box<Expr>,
    },
    FunctionCall {
        name: String,
        args: Vec<Expr>,
    },
    MethodCall {
        object: Box<Expr>,
        method_name: String,
        args: Vec<Expr>,
    },
    StreamInit {
        modalities: Vec<String>,
        uri: String,
    },
    PropertyAccess {
        object: Box<Expr>,
        property_name: String,
    },
    IndexAccess {
        object: Box<Expr>,
        index: Box<Expr>,
    },
    Assignment {
        target: Box<Expr>,
        value: Box<Expr>,
    },
    ArrayDecl {
        elements: Vec<Expr>,
    },
    DictionaryDecl {
        pairs: Vec<(Expr, Expr)>,
    },
    FusedKernel(BlockStmt),
    Attention {
        target: Box<Expr>,
        routing: String,
    },
    Range {
        start: Box<Expr>,
        end: Box<Expr>,
    },
    Graft {
        source: Box<Expr>,
        topology: Option<String>,
    },
    TranslationBarrier {
        from: Box<Expr>,
        to: Box<Expr>,
    },
    TokenizeBPE {
        text: Box<Expr>,
        tokenizer_path: String,
    },
    AlignSpans {
        vocab_a: String,
        vocab_b: String,
        projection_matrix: Box<Expr>,
    },
    TreeSearch {
        tree: Box<Expr>,
        algorithm: String,
        state: Option<Box<Expr>>,
    },
    SievingCacheInit,
    FractalAttentionInit,
    ElasticVocabularyInit,
    LexAndEmbed(Box<Expr>),
    AlignGeodesics(Box<Expr>, Box<Expr>),
    GeometricBridge(Box<Expr>, Box<Expr>),
    TransposeWeights(Box<Expr>, Box<Expr>),
    Transpose(Box<Expr>),
    ReflectRepo,
    HotSwap(Box<Expr>, Box<Expr>),
    SpikePrimitive,
    NeuronPrimitive,
    Transform {
        op: String,
        target: Box<Expr>,
    },
    Quantize {
        target: Box<Expr>,
        dtype: String,
    },
    AddressOf(Box<Expr>),
    Dereference(Box<Expr>),
    MSELoss(Box<Expr>, Box<Expr>),
    ParallelTransport {
        vector: Box<Expr>,
        from: Box<Expr>,
        to: Box<Expr>,
    },
    Lazy {
        expr: Box<Expr>,
    },
    PagedAttention {
        query: Box<Expr>,
        key: Box<Expr>,
        value: Box<Expr>,
    },
    ProjectVocab {
        source: Box<Expr>,
        target: Box<Expr>,
    },
    WeightDecay {
        target: Box<Expr>,
        amount: f64,
    },
}

#[derive(Debug, Clone, PartialEq)]
pub enum Stmt {
    Placeholder(String),
    Expr(Expr),
    VarDecl {
        name: String,
        is_const: bool,
        value: Expr,
    },
    FieldDecl {
        name: String,
        type_name: String,
    },
    StructDecl {
        name: String,
        fields: Vec<Stmt>,
    },
    TensorDecl {
        name: String,
        shape: Vec<Expr>,
        manifold: ManifoldSpace,
        layout: Option<MemoryLayout>,
        location: Option<String>,
        backend: StorageBackend,
        is_lazy: bool,
        is_unified: bool,
        is_latent: bool,
    },
    ParameterDecl {
        name: String,
        shape: Vec<Expr>,
        manifold: ManifoldSpace,
        layout: Option<MemoryLayout>,
        location: Option<String>,
        backend: StorageBackend,
        optimizer: Option<OptimizerState>,
    },
    VectorDecl {
        name: String,
        data_type: Option<String>,
        dim: Expr,
        space: VectorSpace,
    },
    SequenceDecl {
        name: String,
        max_len: Expr,
    },
    BlockDecl {
        name: String,
        size: Expr,
    },
    LatticeDecl {
        name: String,
        lattice_type: String,
        dim: Expr,
    },
    TreeDecl {
        name: String,
        element_type: String,
    },
    StructDef {
        name: String,
        body: BlockStmt,
    },
    FunctionDecl(FunctionDecl),
    ExternFunctionDecl(ExternFunctionDecl),
    MacroDecl(MacroRule),
    If {
        condition: Expr,
        true_block: BlockStmt,
        false_block: Option<BlockStmt>,
    },
    While {
        condition: Expr,
        body: BlockStmt,
    },
    For {
        init: Option<Box<Stmt>>,
        condition: Option<Expr>,
        increment: Option<Box<Stmt>>,
        body: BlockStmt,
    },
    TryCatch {
        try_block: BlockStmt,
        catch_var: String,
        catch_block: BlockStmt,
    },
    Throw {
        value: Expr,
    },
    AbsorbWeights {
        donor_path: String,
        local_tensor: String,
    },
    ProjectVocab {
        source_tensor: String,
        target_vocab: String,
    },
    Return {
        value: Option<Expr>,
    },
    Break,
    Continue,
    PipelineDecl {
        name: String,
        layers: Vec<Expr>,
    },
    ImportModel {
        uri: String,
        alias: String,
    },
    JitBlock(BlockStmt),
    Block(BlockStmt),
    Match {
        condition: Expr,
        arms: Vec<(Option<Expr>, Box<Stmt>)>,
    },
    Import {
        filepath: String,
    },
    AsyncCompute(BlockStmt),
    Backward(Expr),
    StreamDecl {
        id: Expr,
        manifold_name: String,
    },
    ManifoldDecl {
        name: String,
        body: BlockStmt,
    },
    MeshBlock {
        name: String,
        strategy: String,
        body: BlockStmt,
    },
    MultimodalBlock {
        body: BlockStmt,
    },
    VmapBlock {
        body: BlockStmt,
    },
    DoubtBlock {
        body: BlockStmt,
    },
    ChainBlock {
        body: BlockStmt,
    },
    RouteBlock {
        body: BlockStmt,
    },
    GrokBlock {
        body: BlockStmt,
    },
    OverrideBlock {
        body: BlockStmt,
    },
    ToolDecl(FunctionDecl),
    Satisfy {
        condition: Expr,
        body: BlockStmt,
        otherwise: Option<BlockStmt>,
    },
    Backtrack,
    TopologyDecl {
        name: String,
        body: BlockStmt,
    },
    FluidPrecisionBlock {
        primary_type: String,
        fallback_type: String,
        block: BlockStmt,
    },
    SparsityBlock {
        block_size: Expr,
        density: Expr,
        block: BlockStmt,
    },
    PruneGraph(Expr),
    EmitSpike {
        intensity: Expr,
    },
}
