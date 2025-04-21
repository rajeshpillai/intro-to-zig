const std = @import("std");
const stdout = std.io.getStdOut().writer();

const AVLNode = struct {
    value: i32,
    left: ?*AVLNode,
    right: ?*AVLNode,
    height: i32,

    pub fn init(value: i32, allocator: std.mem.Allocator) !*AVLNode {
        const node = try allocator.create(AVLNode);
        node.* = AVLNode{ .value = value, .left = null, .right = null, .height = 1 };
        return node;
    }

    // Optional: Keep print for debugging if needed, but not essential for tests
    // pub fn print(self: AVLNode) !void {
    //     try stdout.print("{d}\n", .{self.value});
    // }
};

const AVLTree = struct {
    root: ?*AVLNode,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) AVLTree {
        return AVLTree{ .root = null, .allocator = allocator };
    }

    pub fn deinit(self: *AVLTree) void {
        // Use self.allocator directly
        freeNodes(self.allocator, self.root);
        self.root = null;
    }

    // Make freeNodes take self: *AVLTree for consistency? Or keep as is.
    // Keeping as is for now, matches original code.
    fn freeNodes(allocator: std.mem.Allocator, node: ?*AVLNode) void {
        if (node == null) return;

        // Recursively free left and right subtrees
        freeNodes(allocator, node.?.left);
        freeNodes(allocator, node.?.right);

        // Free the current node
        allocator.destroy(node.?);
    }

    fn getHeight(node: ?*AVLNode) i32 {
        return if (node == null) 0 else node.?.height;
    }

    fn getBalanceFactor(node: ?*AVLNode) i32 {
        return if (node == null) 0 else getHeight(node.?.left) - getHeight(node.?.right);
    }

    // Used when right-heavy (balance < -1).
    fn leftRotate(y: *AVLNode) *AVLNode {
        const x = y.right orelse unreachable; // Add orelse for safety if needed, though logic implies it exists
        const T2 = x.left;

        x.left = y;
        y.right = T2;

        y.height = 1 + @max(getHeight(y.left), getHeight(y.right));
        x.height = 1 + @max(getHeight(x.left), getHeight(x.right));

        return x;
    }

    // Used when left-heavy (balance > 1).
    fn rightRotate(x: *AVLNode) *AVLNode {
        const y = x.left orelse unreachable; // Add orelse for safety
        const T2 = y.right;

        y.right = x;
        x.left = T2;

        x.height = 1 + @max(getHeight(x.left), getHeight(x.right));
        y.height = 1 + @max(getHeight(y.left), getHeight(y.right));
        return y;
    }

    pub fn insert(self: *AVLTree, value: i32) !void {
        self.root = try insertNode(self.allocator, self.root, value);
    }

    fn insertNode(allocator: std.mem.Allocator, node: ?*AVLNode, value: i32) !*AVLNode {
        var current_node: *AVLNode = undefined;
        if (node) |n| {
            current_node = n;
        } else {
            // Base case: Found insertion point or tree is empty
            return try AVLNode.init(value, allocator);
        }

        if (value < current_node.value) {
            current_node.left = try insertNode(allocator, current_node.left, value);
        } else if (value > current_node.value) {
            current_node.right = try insertNode(allocator, current_node.right, value);
        } else {
            // Value already exists, do nothing (or handle as needed, e.g., return error)
            return current_node;
        }

        // Update height of the current node
        current_node.height = 1 + @max(getHeight(current_node.left), getHeight(current_node.right));

        // Get balance factor to check for imbalance
        const balance = getBalanceFactor(current_node);

        // Perform rotations if unbalanced

        // Left Left Case (node is left-heavy, and left child is left-heavy or balanced)
        if (balance > 1 and value < current_node.left.?.value) {
            return rightRotate(current_node);
        }

        // Right Right Case (node is right-heavy, and right child is right-heavy or balanced)
        if (balance < -1 and value > current_node.right.?.value) {
            return leftRotate(current_node);
        }

        // Left Right Case (node is left-heavy, but left child is right-heavy)
        if (balance > 1 and value > current_node.left.?.value) {
            current_node.left = leftRotate(current_node.left.?);
            return rightRotate(current_node);
        }

        // Right Left Case (node is right-heavy, but right child is left-heavy)
        if (balance < -1 and value < current_node.right.?.value) {
            current_node.right = rightRotate(current_node.right.?);
            return leftRotate(current_node);
        }

        // Return the (possibly updated) node pointer
        return current_node;
    }

    pub fn delete(self: *AVLTree, value: i32) void {
        self.root = deleteNode(self.allocator, self.root, value);
    }

    fn findMin(node: ?*AVLNode) ?*AVLNode {
        var current = node;
        // Keep looping as long as 'current' is not null
        while (current) |c| {
            // If there's a left child, go left
            if (c.left) |l| {
                current = l;
            } else {
                // No left child? This is the minimum node. Stop the loop.
                break;
            }
        }
        // The loop terminates either because 'current' became null (shouldn't happen with this logic if started non-null)
        // or because we hit the 'break' when the leftmost node was found.
        // 'current' now holds the minimum node (or null if the input was null).
        return current;
    }

    fn deleteNode(allocator: std.mem.Allocator, node: ?*AVLNode, value: i32) ?*AVLNode {
        var current_node: *AVLNode = undefined;
        if (node) |n| {
            current_node = n;
        } else {
            // Base case: Value not found or tree empty
            return null;
        }

        // Find the node to delete
        if (value < current_node.value) {
            current_node.left = deleteNode(allocator, current_node.left, value);
        } else if (value > current_node.value) {
            current_node.right = deleteNode(allocator, current_node.right, value);
        } else {
            // Node with the value found, perform deletion

            // Case 1 & 2: Node with zero or one child
            if (current_node.left == null or current_node.right == null) {
                const temp = if (current_node.left != null) current_node.left else current_node.right;

                // No child case
                if (temp == null) {
                    allocator.destroy(current_node);
                    return null; // The node is gone
                } else {
                    // One child case
                    const node_to_return = temp.?; // Store pointer before destroying original
                    allocator.destroy(current_node);
                    return node_to_return; // Return the child node
                }
            } else {
                // Case 3: Node with two children
                // Find the inorder successor (smallest in the right subtree)
                const minNode = findMin(current_node.right).?; // Should always exist if right child exists

                // Copy the inorder successor's value to this node
                current_node.value = minNode.value;

                // Delete the inorder successor from the right subtree
                current_node.right = deleteNode(allocator, current_node.right, minNode.value);
            }
        }

        // If the tree had only one node which was just deleted, node is now null
        if (node == null) return null; // This check might be redundant now due to the return null above

        // Update height of the current node (after potential deletion in subtree)
        // Need to re-fetch node pointer as it might have changed due to deletion returns
        // This part is tricky. The 'node' parameter might point to freed memory if the root was deleted.
        // Let's assume the recursive calls return the *new* node for that position.
        // The logic needs careful review. Let's assume `current_node` holds the correct pointer *after* the recursive calls.
        // If the node itself was deleted (Case 1/2), we already returned. If Case 3, current_node still points to the original struct location but with updated value.

        // Re-assign node based on the potential return value from recursive calls
        // This is complex because the original `node` parameter might be invalid if it was the one deleted.
        // The return value of deleteNode IS the new node for this position.
        // Let's rethink: the function returns the node that *should* be at this position after deletion/balancing.

        // If we reach here, the node itself wasn't deleted (or it was case 3, value replaced).
        // We need to update height and balance *this* node.
        current_node.height = 1 + @max(getHeight(current_node.left), getHeight(current_node.right));

        // Get balance factor to check for imbalance
        const balance = getBalanceFactor(current_node);

        // Perform rotations if unbalanced

        // Left Left Case
        if (balance > 1 and getBalanceFactor(current_node.left) >= 0) {
            return rightRotate(current_node);
        }

        // Left Right Case
        if (balance > 1 and getBalanceFactor(current_node.left) < 0) {
            current_node.left = leftRotate(current_node.left.?);
            return rightRotate(current_node);
        }

        // Right Right Case
        if (balance < -1 and getBalanceFactor(current_node.right) <= 0) {
            return leftRotate(current_node);
        }

        // Right Left Case
        if (balance < -1 and getBalanceFactor(current_node.right) > 0) {
            current_node.right = rightRotate(current_node.right.?);
            return leftRotate(current_node);
        }

        // Return the (possibly updated) node pointer
        return current_node;
    }

    // Helper for tests: Get inorder traversal as a slice
    fn getInorder(self: *AVLTree, allocator: std.mem.Allocator) ![]i32 {
        var list = std.ArrayList(i32).init(allocator);
        errdefer list.deinit();
        try inorderRecursiveAppend(self.root, &list);
        return list.toOwnedSlice();
    }

    fn inorderRecursiveAppend(node: ?*AVLNode, list: *std.ArrayList(i32)) !void {
        if (node) |n| {
            try inorderRecursiveAppend(n.left, list);
            try list.append(n.value);
            try inorderRecursiveAppend(n.right, list);
        }
    }

    // Original inorder for debugging/main remains
    fn inorder(self: *AVLTree) void {
        inorderRecursivePrint(self.root);
        std.debug.print("\n", .{});
    }

    fn inorderRecursivePrint(node: ?*AVLNode) void {
        if (node != null) {
            inorderRecursivePrint(node.?.left);
            std.debug.print("{} ", .{node.?.value});
            inorderRecursivePrint(node.?.right);
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit(); // Ensure deinit even on error
    const allocator = gpa.allocator();

    var avl = AVLTree.init(allocator);
    defer avl.deinit(); // Ensure tree is deinitialized

    const values = [_]i32{ 10, 20, 30, 40, 50, 25 };
    for (values) |val| {
        try avl.insert(val);
    }

    std.debug.print("Inorder Traversal (Balanced AVL): ", .{});
    avl.inorder(); // Uses inorderRecursivePrint

    std.debug.print("Deleting 30...\n", .{});
    avl.delete(30);
    std.debug.print("Inorder After Deletion: ", .{});
    avl.inorder(); // Uses inorderRecursivePrint

    // No need to call avl.deinit() explicitly here due to defer
}

// ================== TESTS ==================
test "init and deinit" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    // Ensure root is null initially
    try std.testing.expect(tree.root == null);
    tree.deinit();
    // std.testing.allocator checks for leaks automatically at end of test scope
}

test "single insert and deinit" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    try tree.insert(10);
    try std.testing.expect(tree.root != null);
    try std.testing.expectEqual(@as(i32, 10), tree.root.?.value);
    try std.testing.expectEqual(@as(i32, 1), tree.root.?.height);
    try std.testing.expect(tree.root.?.left == null);
    try std.testing.expect(tree.root.?.right == null);
}

test "multiple inserts - no rotation" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    try tree.insert(10);
    try tree.insert(5);
    try tree.insert(15);

    const inorderResult = try tree.getInorder(allocator);
    defer allocator.free(inorderResult);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 5, 10, 15 }, inorderResult);

    // Check structure
    try std.testing.expectEqual(@as(i32, 10), tree.root.?.value);
    try std.testing.expectEqual(@as(i32, 5), tree.root.?.left.?.value);
    try std.testing.expectEqual(@as(i32, 15), tree.root.?.right.?.value);
    try std.testing.expectEqual(@as(i32, 2), tree.root.?.height);
}

test "insert - right rotation (LL case)" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    try tree.insert(30);
    try tree.insert(20);
    try tree.insert(10); // This should trigger right rotation at root (30)

    const inorderResult = try tree.getInorder(allocator);
    defer allocator.free(inorderResult);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 10, 20, 30 }, inorderResult);

    // Check structure after rotation
    try std.testing.expectEqual(@as(i32, 20), tree.root.?.value); // New root
    try std.testing.expectEqual(@as(i32, 10), tree.root.?.left.?.value);
    try std.testing.expectEqual(@as(i32, 30), tree.root.?.right.?.value);
    try std.testing.expectEqual(@as(i32, 2), tree.root.?.height);
    try std.testing.expectEqual(@as(i32, 1), tree.root.?.left.?.height);
    try std.testing.expectEqual(@as(i32, 1), tree.root.?.right.?.height);
}

test "insert - left rotation (RR case)" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    try tree.insert(10);
    try tree.insert(20);
    try tree.insert(30); // This should trigger left rotation at root (10)

    const inorderResult = try tree.getInorder(allocator);
    defer allocator.free(inorderResult);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 10, 20, 30 }, inorderResult);

    // Check structure after rotation
    try std.testing.expectEqual(@as(i32, 20), tree.root.?.value); // New root
    try std.testing.expectEqual(@as(i32, 10), tree.root.?.left.?.value);
    try std.testing.expectEqual(@as(i32, 30), tree.root.?.right.?.value);
    try std.testing.expectEqual(@as(i32, 2), tree.root.?.height);
    try std.testing.expectEqual(@as(i32, 1), tree.root.?.left.?.height);
    try std.testing.expectEqual(@as(i32, 1), tree.root.?.right.?.height);
}

test "insert - left-right rotation (LR case)" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    try tree.insert(30);
    try tree.insert(10);
    try tree.insert(20); // This should trigger left rotation at 10, then right rotation at 30

    const inorderResult = try tree.getInorder(allocator);
    defer allocator.free(inorderResult);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 10, 20, 30 }, inorderResult);

    // Check structure after rotation
    try std.testing.expectEqual(@as(i32, 20), tree.root.?.value); // New root
    try std.testing.expectEqual(@as(i32, 10), tree.root.?.left.?.value);
    try std.testing.expectEqual(@as(i32, 30), tree.root.?.right.?.value);
    try std.testing.expectEqual(@as(i32, 2), tree.root.?.height);
    try std.testing.expectEqual(@as(i32, 1), tree.root.?.left.?.height);
    try std.testing.expectEqual(@as(i32, 1), tree.root.?.right.?.height);
}

test "insert - right-left rotation (RL case)" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    try tree.insert(10);
    try tree.insert(30);
    try tree.insert(20); // This should trigger right rotation at 30, then left rotation at 10

    const inorderResult = try tree.getInorder(allocator);
    defer allocator.free(inorderResult);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 10, 20, 30 }, inorderResult);

    // Check structure after rotation
    try std.testing.expectEqual(@as(i32, 20), tree.root.?.value); // New root
    try std.testing.expectEqual(@as(i32, 10), tree.root.?.left.?.value);
    try std.testing.expectEqual(@as(i32, 30), tree.root.?.right.?.value);
    try std.testing.expectEqual(@as(i32, 2), tree.root.?.height);
    try std.testing.expectEqual(@as(i32, 1), tree.root.?.left.?.height);
    try std.testing.expectEqual(@as(i32, 1), tree.root.?.right.?.height);
}

test "insert duplicate" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    try tree.insert(10);
    try tree.insert(5);
    try tree.insert(10); // Insert duplicate

    const inorderResult = try tree.getInorder(allocator);
    defer allocator.free(inorderResult);
    // Expect duplicate to be ignored
    try std.testing.expectEqualSlices(i32, &[_]i32{ 5, 10 }, inorderResult);
}

test "complex insertion sequence (from main)" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    const values = [_]i32{ 10, 20, 30, 40, 50, 25 };
    for (values) |val| {
        try tree.insert(val);
    }

    // Expected structure after insertions and rotations:
    //       30
    //      /  \
    //    20    40
    //   /  \     \
    // 10   25    50
    // Expected inorder: 10, 20, 25, 30, 40, 50

    const inorderResult = try tree.getInorder(allocator);
    defer allocator.free(inorderResult);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 10, 20, 25, 30, 40, 50 }, inorderResult);

    // Verify root and height
    try std.testing.expectEqual(@as(i32, 30), tree.root.?.value);
    try std.testing.expectEqual(@as(i32, 3), tree.root.?.height); // Height of root should be 3
}

test "delete leaf node" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    try tree.insert(10);
    try tree.insert(5);
    try tree.insert(15);

    tree.delete(5); // Delete leaf

    const inorderResult = try tree.getInorder(allocator);
    defer allocator.free(inorderResult);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 10, 15 }, inorderResult);
    try std.testing.expectEqual(@as(i32, 2), tree.root.?.height); // Height should update
}

test "delete node with one child" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    try tree.insert(10);
    try tree.insert(5);
    try tree.insert(15);
    try tree.insert(12); // Child of 15

    tree.delete(15); // Delete node with one left child (12)

    const inorderResult = try tree.getInorder(allocator);
    defer allocator.free(inorderResult);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 5, 10, 12 }, inorderResult);
    try std.testing.expectEqual(@as(i32, 10), tree.root.?.value);
    try std.testing.expectEqual(@as(i32, 12), tree.root.?.right.?.value); // 12 should replace 15
    try std.testing.expectEqual(@as(i32, 2), tree.root.?.height);
}

test "delete node with two children" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    try tree.insert(10);
    try tree.insert(5);
    try tree.insert(15);
    try tree.insert(12);
    try tree.insert(17);

    tree.delete(10); // Delete root with two children (successor is 12)

    const inorderResult = try tree.getInorder(allocator);
    defer allocator.free(inorderResult);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 5, 12, 15, 17 }, inorderResult);
    try std.testing.expectEqual(@as(i32, 12), tree.root.?.value); // 12 is new root
    try std.testing.expectEqual(@as(i32, 5), tree.root.?.left.?.value);
    try std.testing.expectEqual(@as(i32, 15), tree.root.?.right.?.value);
    try std.testing.expectEqual(@as(i32, 3), tree.root.?.height);
}

test "delete causing rotation" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    // Build a tree that will become unbalanced upon deletion
    // Example: Deleting 1 causes RR imbalance at 3, requiring left rotation
    //      4
    //     / \
    //    2   5
    //   / \
    //  1   3
    try tree.insert(4);
    try tree.insert(2);
    try tree.insert(5);
    try tree.insert(1);
    try tree.insert(3);

    tree.delete(1); // Deleting 1 makes node 2 height 2, node 5 height 1. Balance at 4 is 2-1=1. OK.
    // Node 2 has left height 0, right height 1 (node 3). Balance is -1. OK.
    // Let's try deleting 5 instead.
    // Reset tree
    tree.deinit();
    tree = AVLTree.init(allocator);
    //      2
    //     / \
    //    1   4
    //       / \
    //      3   5
    try tree.insert(2);
    try tree.insert(1);
    try tree.insert(4);
    try tree.insert(3);
    try tree.insert(5);

    tree.delete(1); // Deleting 1 causes imbalance at root (2). Left height 0, Right height 3 (node 4). Balance -3.
    // Node 4: left height 1 (node 3), right height 1 (node 5). Balance 0.
    // This triggers RR case at root (2). Left rotate at 2.
    // New tree:
    //      4
    //     / \
    //    2   5
    //     \
    //      3

    const inorderResult = try tree.getInorder(allocator);
    defer allocator.free(inorderResult);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 2, 3, 4, 5 }, inorderResult);
    try std.testing.expectEqual(@as(i32, 4), tree.root.?.value); // New root is 4
    try std.testing.expectEqual(@as(i32, 3), tree.root.?.height);
    try std.testing.expectEqual(@as(i32, 2), tree.root.?.left.?.value);
    try std.testing.expectEqual(@as(i32, 5), tree.root.?.right.?.value);
    try std.testing.expectEqual(@as(i32, 3), tree.root.?.left.?.right.?.value); // Check node 3 position
}

test "delete non-existent value" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    try tree.insert(10);
    try tree.insert(5);
    try tree.insert(15);

    tree.delete(100); // Delete value not in tree

    const inorderResult = try tree.getInorder(allocator);
    defer allocator.free(inorderResult);
    // Tree should remain unchanged
    try std.testing.expectEqualSlices(i32, &[_]i32{ 5, 10, 15 }, inorderResult);
}

test "delete from empty tree" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    tree.delete(10); // Should not crash
    try std.testing.expect(tree.root == null);
}

test "delete root of tree with only root" {
    const allocator = std.testing.allocator;
    var tree = AVLTree.init(allocator);
    defer tree.deinit();

    try tree.insert(10);
    tree.delete(10);
    try std.testing.expect(tree.root == null); // Tree should be empty
}
