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

    pub fn print(self: AVLNode) !void {
        try stdout.print("{d}\n", .{self.value});
    }
};

const AVLTree = struct {
    root: ?*AVLNode,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) AVLTree {
        return AVLTree{ .root = null, .allocator = allocator };
    }

    fn deinit(self: *AVLTree) void {
        if (self.root != null) {
            freeNodes(self.allocator, self.root);
            self.root = null;
        }
    }

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
        const x = y.right.?;
        const T2 = x.left;

        x.left = y;
        y.right = T2;

        y.height = 1 + @max(getHeight(y.left), getHeight(y.right));
        x.height = 1 + @max(getHeight(x.left), getHeight(x.right));

        return x;
    }

    // Used when left-heavy (balance > 1).
    fn rightRotate(x: *AVLNode) *AVLNode {
        const y = x.left.?;
        const T2 = y.right;

        y.right = x;
        x.left = T2;

        x.height = 1 + @max(getHeight(x.left), getHeight(x.right));
        y.height = 1 + @max(getHeight(y.left), getHeight(y.right));
        return y;
    }

    fn insert(self: *AVLTree, value: i32) !void {
        self.root = try insertNode(self.allocator, self.root, value);
    }

    fn insertNode(allocator: std.mem.Allocator, node: ?*AVLNode, value: i32) !*AVLNode {
        if (node == null) return try AVLNode.init(value, allocator);
        if (value < node.?.value) {
            node.?.left = try insertNode(allocator, node.?.left, value);
        } else if (value > node.?.value) {
            node.?.right = try insertNode(allocator, node.?.right, value);
        }

        // Update height
        node.?.height = 1 + @max(getHeight(node.?.left), getHeight(node.?.right));

        // Get balance factor
        const balance = getBalanceFactor(node);

        // Perform rotations if unbalanced
        if (balance > 1 and value < node.?.left.?.value) return rightRotate(node.?);
        if (balance < -1 and value > node.?.right.?.value) return leftRotate(node.?);
        if (balance > 1 and value > node.?.left.?.value) {
            node.?.left = leftRotate(node.?.left.?);
            return rightRotate(node.?);
        }
        if (balance < -1 and value < node.?.right.?.value) {
            node.?.right = rightRotate(node.?.right.?);
            return leftRotate(node.?);
        }
        return node.?;
    }

    fn delete(self: *AVLTree, value: i32) void {
        self.root = deleteNode(self.allocator, self.root, value);
    }

    fn findMin(node: ?*AVLNode) ?*AVLNode {
        var current = node;
        while (current != null and current.?.left != null) {
            current = current.?.left;
        }
        return current;
    }

    fn deleteNode(allocator: std.mem.Allocator, node: ?*AVLNode, value: i32) ?*AVLNode {
        if (node == null) return null;

        if (value < node.?.value) {
            node.?.left = deleteNode(allocator, node.?.left, value);
        } else if (value > node.?.value) {
            node.?.right = deleteNode(allocator, node.?.right, value);
        } else {
            if (node.?.left == null or node.?.right == null) {
                const temp = if (node.?.left != null) node.?.left else node.?.right;
                allocator.destroy(node.?);
                return temp;
            }

            const minNode = findMin(node.?.right);
            node.?.value = minNode.?.value;
            node.?.right = deleteNode(allocator, node.?.right, minNode.?.value);
        }

        // Update height
        node.?.height = 1 + @max(getHeight(node.?.left), getHeight(node.?.right));

        // Balance factor check
        const balance = getBalanceFactor(node);

        if (balance > 1 and getBalanceFactor(node.?.left) >= 0) return rightRotate(node.?);
        if (balance > 1 and getBalanceFactor(node.?.left) < 0) {
            node.?.left = leftRotate(node.?.left.?);
            return rightRotate(node.?);
        }
        if (balance < -1 and getBalanceFactor(node.?.right) <= 0) return leftRotate(node.?);
        if (balance < -1 and getBalanceFactor(node.?.right) > 0) {
            node.?.right = rightRotate(node.?.right.?);
            return leftRotate(node.?);
        }

        return node;
    }

    fn inorder(self: *AVLTree) void {
        inorderRecursive(self.root);
        std.debug.print("\n", .{});
    }

    fn inorderRecursive(node: ?*AVLNode) void {
        if (node != null) {
            inorderRecursive(node.?.left);
            std.debug.print("{} ", .{node.?.value});
            inorderRecursive(node.?.right);
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var avl = AVLTree.init(allocator);
    const values = [_]i32{ 10, 20, 30, 40, 50, 25 };
    for (values) |val| {
        try avl.insert(val);
    }

    std.debug.print("Inorder Traversal (Balanced AVL): ", .{});
    avl.inorder();

    std.debug.print("Deleting 30...\n", .{});
    avl.delete(30);
    std.debug.print("Inorder After Deletion: ", .{});
    avl.inorder();

    avl.deinit();
}
