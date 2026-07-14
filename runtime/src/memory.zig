const std = @import("std");

pub const MemoryBus = struct {
    sram: []f32,
    hbm: []f32,
    dram: []f32,
    
    sram_alloc: usize = 0,
    hbm_alloc: usize = 0,
    dram_alloc: usize = 0,

    pub fn init(allocator: std.mem.Allocator) !MemoryBus {
        // 256 bytes = 64 floats
        const sram = try allocator.alloc(f32, 64);
        // 10MB = 2.5M floats
        const hbm = try allocator.alloc(f32, 2_500_000);
        // 100MB = 25M floats
        const dram = try allocator.alloc(f32, 25_000_000);

        return MemoryBus{
            .sram = sram,
            .hbm = hbm,
            .dram = dram,
        };
    }

    pub fn deinit(self: *MemoryBus, allocator: std.mem.Allocator) void {
        allocator.free(self.sram);
        allocator.free(self.hbm);
        allocator.free(self.dram);
    }

    pub fn alloc(self: *MemoryBus, num_elements: usize) ![]f32 {
        // Just allocate from DRAM for simplicity in the bootstrap
        if (self.dram_alloc + num_elements > self.dram.len) {
            return error.OutOfMemory;
        }
        const start = self.dram_alloc;
        self.dram_alloc += num_elements;
        return self.dram[start .. start + num_elements];
    }
};
