enum Dimension {
    Fixed(float),
    Symbolic(string)
}

enum CartanType {
    Integer,
    Float,
    Boolean,
    String,
    Stream,
    Spike,
    Neuron,
    Vector(string, Dimension, ptr),
    Tensor(ptr, float, ptr, string),
    Parameter(ptr, float, ptr, ptr, string),
    Sequence(Dimension),
    Block(Dimension),
    Lattice(string, Dimension),
    Tree(CartanType),
    Struct(string),
    Enum(string),
    StringView,
    Dataframe,
    Pointer(CartanType),
    Borrow(CartanType),
    MutBorrow(CartanType),
    Tool(string),
    Fuzzy,
    Complex,
    Unknown
}




