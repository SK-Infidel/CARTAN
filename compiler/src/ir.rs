#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum Opcode {
    AllocTensor = 0x10,
    PushTensor = 0x11,
    StoreElement = 0x12,
    LoadDMA = 0x14,
    MatMul = 0x20,
    Backward = 0x30,
    OpenStream = 0x50,
    PollStream = 0x51,
    Add = 0x40,
    Sub = 0x41,
    Mul = 0x42,
    Div = 0x43,
    Jump = 0x60,
    JumpIfFalse = 0x61,
    CmpLt = 0x62,
    CmpEq = 0x63,
}
