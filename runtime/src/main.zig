const std = @import("std");
const vm_module = @import("vm.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    std.debug.print("Cartan Runtime Engine (Tier 2) Initializing...\n", .{});

    var vm = try vm_module.VM.init(allocator);
    const filename = "geomind.aer";

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const reader = file.reader();

    std.debug.print("Executing .aer file stream from stdin...\n", .{});
    
    // We need to buffer or read it directly.
    // If the VM executeStream expects a reader, we can just pass it.
    vm.executeStream(reader) catch |err| {
        std.debug.print("Execution Error: {}\n", .{err});
    };
    
    std.debug.print("Execution complete.\n", .{});
}
