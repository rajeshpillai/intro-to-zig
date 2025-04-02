const std = @import("std");

export fn greet() void {
  std.debug.print("Hello from Zig!\n", .{});
}
