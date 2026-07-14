use crate::ast::ManifoldSpace;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Dimension {
    Fixed(u32),
    Symbolic(String),
}

impl std::fmt::Display for Dimension {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Dimension::Fixed(val) => write!(f, "{}", val),
            Dimension::Symbolic(name) => write!(f, "{}", name),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CartanType {
    Integer,
    Float,
    Boolean,
    String,
    Stream,
    Spike,
    Neuron,
    Tensor(Vec<Dimension>, ManifoldSpace, Option<crate::ast::MemoryLayout>),
    Parameter(Vec<Dimension>, ManifoldSpace, Option<crate::ast::MemoryLayout>, Option<crate::ast::OptimizerState>),
    Sequence(Dimension),
    Block(Dimension),
    Unknown, // Fallback for unsupported/raw expressions
}

impl std::fmt::Display for CartanType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CartanType::Integer => write!(f, "int"),
            CartanType::Float => write!(f, "float"),
            CartanType::Boolean => write!(f, "bool"),
            CartanType::String => write!(f, "string"),
            CartanType::Stream => write!(f, "stream"),
            CartanType::Spike => write!(f, "spike"),
            CartanType::Neuron => write!(f, "neuron"),
            CartanType::Tensor(dims, _, _) => {
                let d_str: Vec<String> = dims.iter().map(|d| d.to_string()).collect();
                write!(f, "tensor[{}]", d_str.join(", "))
            },
            CartanType::Parameter(dims, _, _, _) => {
                let d_str: Vec<String> = dims.iter().map(|d| d.to_string()).collect();
                write!(f, "parameter[{}]", d_str.join(", "))
            },
            CartanType::Sequence(max_len) => write!(f, "sequence[{}]", max_len),
            CartanType::Block(size) => write!(f, "block[{}]", size),
            CartanType::Unknown => write!(f, "unknown"),
        }
    }
}
