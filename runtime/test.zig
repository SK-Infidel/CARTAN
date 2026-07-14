const std = @import("std"); pub fn main() !void { var list = std.ArrayList(u32).init(std.heap.page_allocator); _ = list; }
