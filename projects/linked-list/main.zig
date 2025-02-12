const std = @import("std");
const stdout = std.io.getStdOut().writer();

const Node = struct {
    data: i32,
    next: ?*Node,

    pub fn init(allocator: std.mem.Allocator, data: i32) !*Node {
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

    fn append(self: *LinkedList, allocator: std.mem.Allocator, value: i32) !void {
        const new_node = try Node.init(allocator, value);
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

    fn delete(self: *LinkedList, allocator: std.mem.Allocator, data: i32) !void {
        if (self.head == null) return;

        if (self.head.?.data == data) {
            const temp = self.head;
            self.head = self.head.?.next;
            allocator.destroy(temp.?);
            return;
        }

        var current = self.head;
        while (current.?.next != null and current.?.next.?.data != data) {
            current = current.?.next;
        }

        if (current.?.next != null) {
            const temp = current.?.next;
            current.?.next = current.?.next.?.next;
            allocator.destroy(temp.?);
        }
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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var list = LinkedList.init();
    try list.append(allocator, 10);
    try list.append(allocator, 20);
    try list.append(allocator, 30);
    std.debug.print("After appending:\n", .{});
    list.print();

    try list.delete(allocator, 20);
    std.debug.print("After deleting 20:\n", .{});
    list.print();
}
