const std = @import("std");

// private
const SLRData = struct {
    data: []const [2]f32,
    m: f32,
    c: f32,
    const Self = @This();
    pub fn predict(self: *Self, x: f32) f32 {
        const y = self.m * x + self.c;
        return y;
    }

    pub fn train(self: *Self, data: []const [2]f32) void {
        const m_and_c = get_m_and_c(data);
        self.m = m_and_c[0];
        self.c = m_and_c[1];
        // return SLRData{ .data = data, .m = m, .c = c };
        self.data = data;
    }
};

pub fn init(data: []const [2]f32) SLRData {
    // const m_and_c = get_m_and_c(data);
    // const m = m_and_c[0];
    // const c = m_and_c[1];
    // return SLRData{ .data = data, .m = m, .c = c };
    return SLRData{ .data = data, .m = 0.0, .c = 0.0 };
}

fn get_m_and_c(data: []const [2]f32) [2]f32 {
    var sum_x: f32 = 0;
    var sum_y: f32 = 0;
    for (data) |set| {
        const X = set[0];
        sum_x += X;
        const Y = set[1];
        sum_y += Y;
    }
    const data_len = @as(f32, @floatFromInt(data.len));
    const avg_x = sum_x / data_len;
    const avg_y = sum_y / data_len;

    var numerator_sum: f32 = 0;
    for (data) |set| {
        const X_i = set[0];
        const Y_i = set[1];
        numerator_sum += (X_i - avg_x) * (Y_i - avg_y);
    }
    var denominator_sum: f32 = 0;
    for (data) |set| {
        const X_i = set[0];
        denominator_sum += std.math.pow(f32, (X_i - avg_x), 2.0);
    }
    const m = numerator_sum / denominator_sum;
    const c = avg_y - (m * avg_x);

    const result = [2]f32{ m, c };
    return result;
}
