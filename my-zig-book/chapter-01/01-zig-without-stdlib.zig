// zig build-exe my-zig-book/chapter-01/01-zig-without-stdlib.zig

pub fn main() void {
    const SYS_WRITE: usize = 1; // Syscall number for `write`
    const STDOUT: usize = 1; // File descriptor for standard output
    const message = "Hello, Zig!\n";

    _ = linux_syscall3(SYS_WRITE, STDOUT, @intFromPtr(message), message.len);
}

fn linux_syscall3(n: usize, a1: usize, a2: usize, a3: usize) usize {
    return asm volatile (
        \\ syscall
        : [ret] "={rax}" (-> usize),
        : [n] "{rax}" (n),
          [a1] "{rdi}" (a1),
          [a2] "{rsi}" (a2),
          [a3] "{rdx}" (a3),
        : "rcx", "r11", "memory"
    );
}
