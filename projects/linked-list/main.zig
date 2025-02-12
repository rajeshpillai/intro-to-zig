const std = @import("std");
const stdout = std.io.getStdOut().writer();

const Node = struct {
    data: i32,
    next: ?*Node,

    pub fn init(data: i32) !*Node {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        const node = try allocator.create(Node);
        node.* = Node{ .data = data, .next = null };
        return node;
    }

    pub fn print(self: Node) !void {
        try stdout.print("{d}\n", .{self.data});
    }
};

const LinkedList = struct {
    head: ?*Node,

    fn init() LinkedList {
        return LinkedList{ .head = null };
    }

    fn append(self: *LinkedList, value: i32) !void {
        const new_node = try Node.init(value);
        if (self.head == null) {
            self.head = new_node;
            return;
        }

        var current = self.head;
        while (current.?.next != null) {
            current = current.?.next;
        }
        current.?.next = new_node;
    }

    fn print(self: *LinkedList) void {
        var current = self.head;
        std.debug.print("LinkedList: ", .{});
        while (current != null) {
            std.debug.print("{} -> ", .{current.?.data});
            current = current.?.next;
        }
        std.debug.print("null\n", .{});
    }
};

pub fn main() !void {
    var list = LinkedList.init();
    try list.append(10);
    try list.append(20);
    try list.append(30);
    list.print();
}
