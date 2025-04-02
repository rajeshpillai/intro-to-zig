export fn fibonacci(n: u32) u64 {
    if (n == 0) return 0;
    if (n == 1) return 1;

    var a: u64 = 0;
    var b: u64 = 1;
    var i: u32 = 2;

    while (i <= n) : (i += 1) {
        const next = a + b;
        a = b;
        b = next;
    }

    return b;
}
