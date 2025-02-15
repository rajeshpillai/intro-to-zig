const std = @import("std");

const Node = struct {
    value: i32,
    prev: ?*Node, // Pointer to the prev node
    next: ?*Node, // Pointer to the next node

    fn init(value: i32) !*Node {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        const node = try allocator.create(Node);
        node.* = Node{ .value = value, .prev = null, .next = null };
        return node;
    }
};

const DoublyLinkedList = struct {
    head: ?*Node,
    tail: ?*Node,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) DoublyLinkedList {
        return DoublyLinkedList{ .head = null, .tail = null, .allocator = allocator };
    }

    fn append(self: *DoublyLinkedList, value: i32) !void {
        const new_node = try self.allocator.create(Node);
        new_node.* = Node{ .value = value, .prev = self.tail, .next = null };

        if (self.tail != null) {
            self.tail.?.next = new_node;
        } else {
            self.head = new_node; // First node in the list
        }
        self.tail = new_node; // Update the tail to the new node
    }

    fn prepend(self: *DoublyLinkedList, value: i32) !void {
        const new_node = try self.allocator.create(Node);
        new_node.* = Node{ .value = value, .prev = null, .next = self.head };

        if (self.head != null) {
            self.head.?.prev = new_node;
        } else {
            self.tail = new_node; // First node in the list
        }

        self.head = new_node; // Update head to the new node
    }

    fn delete(self: *DoublyLinkedList, value: i32) void {
        var current = self.head;

        while (current != null) {
            if (current.?.value == value) {
                if (current.?.prev != null) {
                    current.?.prev.?.next = current.?.next;
                } else {
                    self.head = current.?.next; // Update head if first node is deleted
                }
                if (current.?.next != null) {
                    current.?.next.?.prev = current.?.prev;
                } else {
                    self.tail = current.?.prev; // Update tail if last node is deleted
                }
                self.allocator.destroy(current.?);
                return;
            }
            current = current.?.next;
        }
    }

    fn printForward(self: *DoublyLinkedList) void {
        var current = self.head;
        std.debug.print("Doubly Linked List (Forward): ", .{});
        while (current != null) {
            std.debug.print("{} -> ", .{current.?.value});
            current = current.?.next;
        }
        std.debug.print("null\n", .{});
    }

    fn printBackward(self: *DoublyLinkedList) void {
        var current = self.tail;
        std.debug.print("Doubly Linked List (Backward): ", .{});
        while (current != null) {
            std.debug.print("{} -> ", .{current.?.value});
            current = current.?.prev;
        }
        std.debug.print("null\n", .{});
    }

    fn deinit(self: *DoublyLinkedList) void {
        var current = self.head;
        while (current != null) {
            const temp = current;
            current = current.?.next;
            self.allocator.destroy(temp.?);
        }
        self.head = null;
        self.tail = null;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var list = DoublyLinkedList.init(allocator);

    try list.append(10);
    try list.append(20);
    try list.append(30);

    std.debug.print("After appending: \n", .{});
    list.printForward();
    list.printBackward();

    try list.prepend(5);
    std.debug.print("After prepending 5:\n", .{});
    list.printForward();
    list.printBackward();

    list.delete(20);
    std.debug.print("After deletting 20:\n", .{});
    list.printForward();
    list.printBackward();

    list.deinit();
}
