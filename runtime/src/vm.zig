const std = @import("std");
const ir = @import("ir.zig");
const memory = @import("memory.zig");
const registry = @import("registry.zig");

pub const VM = struct {
    memory_bus: memory.MemoryBus,
    tensor_registry: registry.TensorRegistry,
    tensor_stack: std.ArrayList(u32),
    allocator: std.mem.Allocator,
    tensor_id_counter: u32,

    pub fn init(allocator: std.mem.Allocator) !VM {
        return VM{
            .memory_bus = try memory.MemoryBus.init(allocator),
            .tensor_registry = registry.TensorRegistry.init(allocator),
            .tensor_stack = std.ArrayList(u32).empty,
            .allocator = allocator,
            .tensor_id_counter = 1000, // Result tensors start at ID 1000
        };
    }

    pub fn deinit(self: *VM) void {
        self.memory_bus.deinit(self.allocator);
        self.tensor_registry.deinit();
        self.tensor_stack.deinit(self.allocator);
    }

    pub fn executeStream(self: *VM, reader: anytype) !void {
        // Read Magic Number
        var magic: [4]u8 = undefined;
        _ = try reader.read(&magic);
        if (!std.mem.eql(u8, &magic, "AER0")) {
            return error.InvalidMagicNumber;
        }

        // Read Metadata Header (12 bytes)
        const version = try reader.readInt(u32, .little);
        const instr_count = try reader.readInt(u32, .little);
        const tensor_alloc_count = try reader.readInt(u32, .little);
        
        std.debug.print("AER Binary Version: {}\n", .{version});
        std.debug.print("Total Instructions: {}\n", .{instr_count});
        std.debug.print("Total Allocations: {}\n", .{tensor_alloc_count});

        var code_buffer = std.ArrayList(u8).empty;
        defer code_buffer.deinit(self.allocator);
        
        var buffer: [1024]u8 = undefined;
        while (true) {
            const bytes_read = try reader.read(&buffer);
            if (bytes_read == 0) break;
            try code_buffer.appendSlice(self.allocator, buffer[0..bytes_read]);
        }
        
        const code = code_buffer.items;
        var pc: usize = 0;

        while (pc < code.len) {
            const opcode: ir.Opcode = @enumFromInt(code[pc]);
            pc += 1;
            
            switch (opcode) {
                .AllocTensor => {
                    const tensor_id = std.mem.readInt(u32, code[pc..pc+4][0..4], .little);
                    pc += 4;
                    const rank = code[pc];
                    pc += 1;
                    std.debug.print("Instruction: AllocTensor (ID: {}, Rank: {})\n", .{tensor_id, rank});
                    
                    var dims = [_]u32{ 1, 1, 1, 1 };
                    var total_elements: usize = 1;
                    var j: u8 = 0;
                    while (j < rank) : (j += 1) {
                        dims[j] = std.mem.readInt(u32, code[pc..pc+4][0..4], .little);
                        pc += 4;
                        total_elements *= dims[j];
                    }
                    
                    const data_ptr = try self.memory_bus.alloc(total_elements);
                    // Initialize with 1.0
                    for (data_ptr) |*val| {
                        val.* = 1.0;
                    }
                    
                    try self.tensor_registry.register(.{
                        .id = tensor_id,
                        .rank = rank,
                        .dimensions = dims,
                        .data_ptr = data_ptr,
                    });
                },

                .OpenStream => {
                    const stream_id = std.mem.readInt(u32, code[pc..pc+4][0..4], .little);
                    pc += 4;
                    std.debug.print("Instruction: OpenStream (ID: {})\n", .{stream_id});
                },
                .PollStream => {
                    const source_stream_id = std.mem.readInt(u32, code[pc..pc+4][0..4], .little);
                    pc += 4;
                    const target_tensor_id = std.mem.readInt(u32, code[pc..pc+4][0..4], .little);
                    pc += 4;
                    std.debug.print("Instruction: PollStream (Source ID: {}, Target ID: {})\n", .{source_stream_id, target_tensor_id});
                    
                    const rank: u8 = 1;
                    var dims = [_]u32{ 1, 1, 1, 1 };
                    dims[0] = 1;
                    const total_elements: usize = 1;
                    const data_ptr = try self.memory_bus.alloc(total_elements);
                    for (data_ptr) |*val| {
                        val.* = 42.0; // Mock polled value
                    }
                    try self.tensor_registry.register(.{
                        .id = target_tensor_id,
                        .rank = rank,
                        .dimensions = dims,
                        .data_ptr = data_ptr,
                    });
                },

                .StoreElement => {
                    const tensor_id = std.mem.readInt(u32, code[pc..pc+4][0..4], .little);
                    pc += 4;
                    const index = std.mem.readInt(u32, code[pc..pc+4][0..4], .little);
                    pc += 4;
                    const value = @as(f32, @bitCast(std.mem.readInt(u32, code[pc..pc+4][0..4], .little)));
                    pc += 4;
                    std.debug.print("Instruction: StoreElement (ID: {}, Index: {}, Value: {d:.2})\n", .{tensor_id, index, value});
                    
                    if (self.tensor_registry.get(tensor_id)) |tensor| {
                        tensor.data_ptr[index] = value;
                    } else {
                        return error.UnknownTensor;
                    }
                },
                .PushTensor => {
                    const tensor_id = std.mem.readInt(u32, code[pc..pc+4][0..4], .little);
                    pc += 4;
                    try self.tensor_stack.append(self.allocator, tensor_id);
                    std.debug.print("Instruction: PushTensor (ID: {})\n", .{tensor_id});
                },
                .LoadDMA => {
                    const file_id = std.mem.readInt(u32, code[pc..pc+4][0..4], .little);
                    pc += 4;
                    std.debug.print("Instruction: LoadDMA (File ID: {}) -> SRAM/HBM Zero-Copy Map\n", .{file_id});
                    // In a full implementation, we'd open the file and use mmap
                    // to map the `.aew` file directly into SRAM.
                    // For the prototype, we mock the successful mmap.
                    const data_ptr = try self.memory_bus.alloc(512 * 512);
                    for (data_ptr) |*val| {
                        val.* = 0.001; // Mock weight data
                    }
                    
                    const tensor_id = self.tensor_id_counter;
                    self.tensor_id_counter += 1;
                    
                    try self.tensor_registry.register(.{
                        .id = tensor_id,
                        .rank = 2,
                        .dimensions = [_]u32{ 512, 512, 1, 1 },
                        .data_ptr = data_ptr,
                    });
                },
                .Jump => {
                    const target = std.mem.readInt(u32, code[pc..pc+4][0..4], .little);
                    std.debug.print("Instruction: Jump to {}\n", .{target});
                    pc = target - 16;
                },
                .JumpIfFalse => {
                    const target = std.mem.readInt(u32, code[pc..pc+4][0..4], .little);
                    pc += 4;
                    const id = self.tensor_stack.pop();
                    const tensor = self.tensor_registry.get(id) orelse return error.UnknownTensor;
                    if (tensor.data_ptr[0] == 0.0) {
                        std.debug.print("Instruction: JumpIfFalse (Condition FALSE) jumping to {}\n", .{target});
                        pc = target - 16;
                    } else {
                        std.debug.print("Instruction: JumpIfFalse (Condition TRUE) continuing\n", .{});
                    }
                },
                .CmpLt => {
                    const id_b = self.tensor_stack.pop();
                    const id_a = self.tensor_stack.pop();
                    
                    const tensor_a = self.tensor_registry.get(id_a) orelse return error.UnknownTensor;
                    const tensor_b = self.tensor_registry.get(id_b) orelse return error.UnknownTensor;
                    
                    const data_c = try self.memory_bus.alloc(1);
                    data_c[0] = if (tensor_a.data_ptr[0] < tensor_b.data_ptr[0]) 1.0 else 0.0;
                    
                    const c_id = self.tensor_id_counter;
                    self.tensor_id_counter += 1;
                    
                    try self.tensor_registry.register(.{
                        .id = c_id,
                        .rank = 1,
                        .dimensions = [_]u32{ 1, 1, 1, 1 },
                        .data_ptr = data_c,
                    });
                    
                    try self.tensor_stack.append(self.allocator, c_id);
                    std.debug.print("Instruction: CmpLt\n", .{});
                },
                .CmpEq => {
                    const id_b = self.tensor_stack.pop();
                    const id_a = self.tensor_stack.pop();
                    
                    const tensor_a = self.tensor_registry.get(id_a) orelse return error.UnknownTensor;
                    const tensor_b = self.tensor_registry.get(id_b) orelse return error.UnknownTensor;
                    
                    const data_c = try self.memory_bus.alloc(1);
                    data_c[0] = if (tensor_a.data_ptr[0] == tensor_b.data_ptr[0]) 1.0 else 0.0;
                    
                    const c_id = self.tensor_id_counter;
                    self.tensor_id_counter += 1;
                    
                    try self.tensor_registry.register(.{
                        .id = c_id,
                        .rank = 1,
                        .dimensions = [_]u32{ 1, 1, 1, 1 },
                        .data_ptr = data_c,
                    });
                    
                    try self.tensor_stack.append(self.allocator, c_id);
                    std.debug.print("Instruction: CmpEq\n", .{});
                },
                .MatMul => {
                    std.debug.print("Instruction: MatMul\n", .{});
                    const id_b = self.tensor_stack.pop();
                    const id_a = self.tensor_stack.pop();
                    
                    const tensor_a = self.tensor_registry.get(id_a) orelse return error.UnknownTensor;
                    const tensor_b = self.tensor_registry.get(id_b) orelse return error.UnknownTensor;
                    
                    const M = tensor_a.dimensions[0];
                    const K = tensor_a.dimensions[1];
                    const N = tensor_b.dimensions[1];
                    
                    std.debug.print("  Executing MatMul: [{}, {}] @ [{}, {}] -> [{}, {}]\n", .{M, K, tensor_b.dimensions[0], N, M, N});
                    
                    const data_c = try self.memory_bus.alloc(M * N);
                    
                    var m: usize = 0;
                    while (m < M) : (m += 1) {
                        var n: usize = 0;
                        while (n < N) : (n += 1) {
                            var sum: f32 = 0.0;
                            var k: usize = 0;
                            while (k < K) : (k += 1) {
                                sum += tensor_a.data_ptr[m * K + k] * tensor_b.data_ptr[k * N + n];
                            }
                            data_c[m * N + n] = sum;
                        }
                    }
                    
                    const c_id = self.tensor_id_counter;
                    self.tensor_id_counter += 1;
                    
                    try self.tensor_registry.register(.{
                        .id = c_id,
                        .rank = 2,
                        .dimensions = [_]u32{ M, N, 1, 1 },
                        .data_ptr = data_c,
                    });
                    
                    try self.tensor_stack.append(self.allocator, c_id);
                    std.debug.print("  Result Tensor ID: {}, First element: {d}\n", .{c_id, data_c[0]});
                },
                .Add => {
                    std.debug.print("Instruction: Add\n", .{});
                    // Fallback to popping ids but doing nothing for brevity in sprint
                    _ = self.tensor_stack.pop();
                    _ = self.tensor_stack.pop();
                    self.tensor_id_counter += 1;
                    try self.tensor_stack.append(self.allocator, self.tensor_id_counter);
                },
                .Sub => {
                    std.debug.print("Instruction: Sub\n", .{});
                    _ = self.tensor_stack.pop();
                    _ = self.tensor_stack.pop();
                    self.tensor_id_counter += 1;
                    try self.tensor_stack.append(self.allocator, self.tensor_id_counter);
                },
                .Mul => {
                    std.debug.print("Instruction: Mul\n", .{});
                    _ = self.tensor_stack.pop();
                    _ = self.tensor_stack.pop();
                    self.tensor_id_counter += 1;
                    try self.tensor_stack.append(self.allocator, self.tensor_id_counter);
                },
                .Div => {
                    std.debug.print("Instruction: Div\n", .{});
                    _ = self.tensor_stack.pop();
                    _ = self.tensor_stack.pop();
                    self.tensor_id_counter += 1;
                    try self.tensor_stack.append(self.allocator, self.tensor_id_counter);
                },
                .Backward => {
                    std.debug.print("Instruction: Backward\n", .{});
                }
            }
        }
    }
};
