# 3.1 Understanding CLI Applications in Zig

A CLI application allows users to interact with a program via the terminal. In Zig, CLI applications use:

- std.process.args() to read command-line arguments
- std.fs for file I/O operations
- std.io for printing to stdout/stderr