const std = @import("std");

pub const TensorMeta = struct {
    id: u32,
    rank: u8,
    dimensions: [4]u32, // Support up to 4D tensors for now
    data_ptr: []f32,
};

pub const TensorRegistry = struct {
    map: std.AutoHashMap(u32, TensorMeta),

    pub fn init(allocator: std.mem.Allocator) TensorRegistry {
        return TensorRegistry{
            .map = std.AutoHashMap(u32, TensorMeta).init(allocator),
        };
    }

    pub fn deinit(self: *TensorRegistry) void {
        self.map.deinit();
    }

    pub fn register(self: *TensorRegistry, tensor: TensorMeta) !void {
        try self.map.put(tensor.id, tensor);
    }

    pub fn get(self: *const TensorRegistry, id: u32) ?TensorMeta {
        return self.map.get(id);
    }
};
