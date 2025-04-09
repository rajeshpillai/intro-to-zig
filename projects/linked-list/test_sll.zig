const std = @import("std");
const LinkedList = @import("singly-linked-list.zig").LinkedList;
const Node = @import("singly-linked-list.zig").Node;

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "Node initialization" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const node = try Node.init(allocator, 42);
    try expectEqual(@as(i32, 42), node.value);
    try expect(node.next == null);
}

test "LinkedList initialization" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const list = LinkedList.init(allocator);
    try expect(list.head == null);
}

test "LinkedList append" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = LinkedList.init(allocator);
    defer list.deinit();

    // Test appending to empty list
    try list.append(10);
    try expectEqual(@as(i32, 10), list.head.?.value);
    try expect(list.head.?.next == null);

    // Test appending to non-empty list
    try list.append(20);
    try expectEqual(@as(i32, 10), list.head.?.value);
    try expectEqual(@as(i32, 20), list.head.?.next.?.value);
    try expect(list.head.?.next.?.next == null);

    // Test appending multiple values
    try list.append(30);
    try expectEqual(@as(i32, 10), list.head.?.value);
    try expectEqual(@as(i32, 20), list.head.?.next.?.value);
    try expectEqual(@as(i32, 30), list.head.?.next.?.next.?.value);
    try expect(list.head.?.next.?.next.?.next == null);
}

test "LinkedList prepend" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = LinkedList.init(allocator);
    defer list.deinit();

    // Test prepending to empty list
    try list.prepend(10);
    try expectEqual(@as(i32, 10), list.head.?.value);
    try expect(list.head.?.next == null);

    // Test prepending to non-empty list
    try list.prepend(20);
    try expectEqual(@as(i32, 20), list.head.?.value);
    try expectEqual(@as(i32, 10), list.head.?.next.?.value);
    try expect(list.head.?.next.?.next == null);

    // Test prepending multiple values
    try list.prepend(30);
    try expectEqual(@as(i32, 30), list.head.?.value);
    try expectEqual(@as(i32, 20), list.head.?.next.?.value);
    try expectEqual(@as(i32, 10), list.head.?.next.?.next.?.value);
    try expect(list.head.?.next.?.next.?.next == null);
}

test "LinkedList insertAt" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = LinkedList.init(allocator);
    defer list.deinit();

    // Test inserting at index 0 in empty list (should prepend)
    try list.insertAt(0, 10);
    try expectEqual(@as(i32, 10), list.head.?.value);
    try expect(list.head.?.next == null);

    // Test inserting at index > 0 in list with one element (should append)
    try list.insertAt(1, 20);
    try expectEqual(@as(i32, 10), list.head.?.value);
    try expectEqual(@as(i32, 20), list.head.?.next.?.value);
    try expect(list.head.?.next.?.next == null);

    // Test inserting at index 0 in non-empty list (should prepend)
    try list.insertAt(0, 5);
    try expectEqual(@as(i32, 5), list.head.?.value);
    try expectEqual(@as(i32, 10), list.head.?.next.?.value);
    try expectEqual(@as(i32, 20), list.head.?.next.?.next.?.value);
    try expect(list.head.?.next.?.next.?.next == null);

    // Test inserting in the middle
    try list.insertAt(2, 15);
    try expectEqual(@as(i32, 5), list.head.?.value);
    try expectEqual(@as(i32, 10), list.head.?.next.?.value);
    try expectEqual(@as(i32, 15), list.head.?.next.?.next.?.value);
    try expectEqual(@as(i32, 20), list.head.?.next.?.next.?.next.?.value);
    try expect(list.head.?.next.?.next.?.next.?.next == null);

    // Test inserting at out-of-bounds index (should append)
    try list.insertAt(10, 25);
    try expectEqual(@as(i32, 25), list.head.?.next.?.next.?.next.?.next.?.value);
    try expect(list.head.?.next.?.next.?.next.?.next.?.next == null);
}

test "LinkedList delete" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = LinkedList.init(allocator);
    defer list.deinit();

    // Setup list with values
    try list.append(10);
    try list.append(20);
    try list.append(30);
    try list.append(40);

    // Test deleting from empty list (should do nothing)
    var empty_list = LinkedList.init(allocator);
    defer empty_list.deinit();
    try empty_list.delete(10); // Should not crash

    // Test deleting head
    try list.delete(10);
    try expectEqual(@as(i32, 20), list.head.?.value);
    try expectEqual(@as(i32, 30), list.head.?.next.?.value);
    try expectEqual(@as(i32, 40), list.head.?.next.?.next.?.value);
    try expect(list.head.?.next.?.next.?.next == null);

    // Test deleting middle element
    try list.delete(30);
    try expectEqual(@as(i32, 20), list.head.?.value);
    try expectEqual(@as(i32, 40), list.head.?.next.?.value);
    try expect(list.head.?.next.?.next == null);

    // Test deleting tail
    try list.delete(40);
    try expectEqual(@as(i32, 20), list.head.?.value);
    try expect(list.head.?.next == null);

    // Test deleting the only element
    try list.delete(20);
    try expect(list.head == null);

    // Test deleting non-existent element
    try list.delete(50); // Should not crash or change the list
    try expect(list.head == null);
}

test "LinkedList length" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = LinkedList.init(allocator);
    defer list.deinit();

    // Test empty list
    try expectEqual(@as(usize, 0), list.length());

    // Test list with one element
    try list.append(10);
    try expectEqual(@as(usize, 1), list.length());

    // Test list with multiple elements
    try list.append(20);
    try list.append(30);
    try expectEqual(@as(usize, 3), list.length());

    // Test after deletion
    try list.delete(20);
    try expectEqual(@as(usize, 2), list.length());

    // Test after clearing the list
    try list.delete(10);
    try list.delete(30);
    try expectEqual(@as(usize, 0), list.length());
}

test "LinkedList find" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = LinkedList.init(allocator);
    defer list.deinit();

    // Test finding in empty list
    try expect(list.find(10) == null);

    // Setup list with values
    try list.append(10);
    try list.append(20);
    try list.append(30);

    // Test finding existing values
    const found_head = list.find(10);
    try expect(found_head != null);
    try expectEqual(@as(i32, 10), found_head.?.value);

    const found_middle = list.find(20);
    try expect(found_middle != null);
    try expectEqual(@as(i32, 20), found_middle.?.value);

    const found_tail = list.find(30);
    try expect(found_tail != null);
    try expectEqual(@as(i32, 30), found_tail.?.value);

    // Test finding non-existent value
    try expect(list.find(40) == null);
}

test "LinkedList deinit" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = LinkedList.init(allocator);

    // Add some nodes
    try list.append(10);
    try list.append(20);
    try list.append(30);

    // Deinit should free all nodes
    list.deinit();
    try expect(list.head == null);

    // Test deinit on empty list
    var empty_list = LinkedList.init(allocator);
    empty_list.deinit(); // Should not crash
}
