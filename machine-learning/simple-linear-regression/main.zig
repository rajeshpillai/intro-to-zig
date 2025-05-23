// Original Reference: https://www.youtube.com/watch?v=CX6IC37grSs

const std = @import("std");
const SimpleLinearRegression = @import("slr.zig");

pub fn main() u8 {
    const data = &.{
        // x , y
        .{ 1.2, 39344.0 },
        .{ 1.4, 46206.0 },
        .{ 1.6, 37732.0 },
        .{ 2.1, 43526.0 },
        .{ 2.3, 39892.0 },
        .{ 3.0, 56643.0 },
        .{ 3.1, 60151.0 },
        .{ 3.3, 54446.0 },
        .{ 3.3, 64446.0 },
        .{ 3.8, 57190.0 },
        .{ 4.0, 63219.0 },
        .{ 4.1, 55795.0 },
        .{ 4.1, 56958.0 },
        .{ 4.2, 57082.0 },
        .{ 4.6, 61112.0 },
        .{ 5.0, 67939.0 },
        .{ 5.2, 66030.0 },
        .{ 5.4, 83089.0 },
        .{ 6.0, 81364.0 },
        .{ 6.1, 93941.0 },
        .{ 6.9, 91739.0 },
        .{ 7.2, 98274.0 },
        .{ 8.0, 101303.0 },
        .{ 8.3, 113813.0 },
        .{ 8.8, 109432.0 },
        .{ 9.1, 105583.0 },
        .{ 9.6, 116970.0 },
        .{ 9.7, 112636.0 },
        .{ 10.4, 122392.0 },
        .{ 10.6, 121873.0 },
    };
    var SLR = SimpleLinearRegression.init(data);
    SLR.train(data);
    const y = SLR.predict(11.0);
    std.debug.print("Y: {d}\n", .{y});
    std.debug.print("M: {d}\n", .{SLR.m});
    std.debug.print("C: {d}\n", .{SLR.c});
    return 0;
}
