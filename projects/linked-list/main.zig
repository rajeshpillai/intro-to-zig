const std = @import("std");
const stdout = std.io.getStdOut().writer();

const Node = struct {
    value: i32,
    next: ?*Node,

    pub fn init(allocator: std.mem.Allocator, value: i32) !*Node {
        const node = try allocator.create(Node);
        node.* = Node{ .value = value, .next = null };
        return node;
    }

    pub fn print(self: Node) !void {
        try stdout.print("{d}\n", .{self.value});
    }
};

const LinkedList = struct {
    head: ?*Node,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) LinkedList {
        return LinkedList{ .head = null, .allocator = allocator };
    }

    fn append(self: *LinkedList, value: i32) !void {
        const new_node = try self.allocator.create(Node);
        new_node.* = Node{ .value = value, .next = null };
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

    fn prepend(self: *LinkedList, value: i32) !void {
        const new_node = try self.allocator.create(Node);
        new_node.* = Node{ .value = value, .next = self.head };
        self.head = new_node;
    }

    fn insertAt(self: *LinkedList, index: usize, value: i32) !void {
        if (index == 0) {
            try self.prepend(value);
            return;
        }

        if (self.head == null) {
            std.debug.print("⚠️ List is empty, inserting as the first element.\n", .{});
            try self.append(value);
            return;
        }

        var current = self.head;
        var pos: usize = 0;

        while (current != null and pos < index - 1) {
            current = current.?.next;
            pos += 1;
        }

        if (current == null or current.?.next == null) {
            std.debug.print("⚠️ Index out of bounds, inserting at the end.\n", .{});
            try self.append(value);
            return;
        }

        const new_node = try self.allocator.create(Node);
        new_node.* = Node{ .value = value, .next = current.?.next };
        current.?.next = new_node;
    }

    fn delete(self: *LinkedList, value: i32) !void {
        if (self.head == null) return;

        if (self.head.?.value == value) {
            const temp = self.head;
            self.head = self.head.?.next;
            self.allocator.destroy(temp.?);
            return;
        }

        var current = self.head;
        while (current.?.next != null and current.?.next.?.value != value) {
            current = current.?.next;
        }

        if (current.?.next != null) {
            const temp = current.?.next;
            current.?.next = current.?.next.?.next;
            self.allocator.destroy(temp.?);
        }
    }

    fn print(self: *LinkedList) void {
        var current = self.head;
        std.debug.print("LinkedList: ", .{});
        while (current != null) {
            std.debug.print("{} -> ", .{current.?.value});
            current = current.?.next;
        }
        std.debug.print("null\n", .{});
    }

    fn deinit(self: *LinkedList) void {
        var current = self.head;
        while (current != null) {
            const temp = current;
            current = current.?.next;
            self.allocator.destroy(temp.?);
        }
        self.head = null; // Make sure the list is empty
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var list = LinkedList.init(allocator);
    try list.append(10);
    try list.append(20);
    try list.append(30);
    std.debug.print("After appending:\n", .{});
    list.print();

    try list.delete(20);
    std.debug.print("After deleting 20:\n", .{});
    list.print();

    try list.prepend(5);
    std.debug.print("After prepending 5:\n", .{});
    list.print();

    try list.insertAt(0, 15);
    std.debug.print("After inserting 15 at index 0:\n", .{});
    list.print();

    try list.insertAt(2, 16);
    std.debug.print("After inserting 16 at index 2:\n", .{});
    list.print();

    // Cleanup
    list.deinit();
}
