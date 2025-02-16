# Capter 4 - Zig’s Memory Model and Manual Memory Management
We will cover:

- Stack vs heap memory in Zig
- Using allocators for manual memory management
- Avoiding memory leaks

# Understanding Stack vs Heap Memory
Zig gives developers full control over memory, unlike garbage-collected languages like Python or Go.

Stack Memory (Automatic)
- ✅ Fast memory allocation
- ✅ Used for local variables
- ✅ Automatically cleaned up when a function exits
- ❌ Limited in size

# Heap Memory (Manual)
- ✅ Large memory space
- ✅ Used for dynamic memory allocation
- ✅ Memory must be freed manually
- ❌ Slower than stack memory