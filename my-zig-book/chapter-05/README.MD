# Chapter 5: Concurrency and Multithreading in Zig
In this chapter, we will explore how Zig handles concurrency and multithreading, covering:

- ✅ Understanding concurrency vs parallelism
- ✅ Creating and managing threads in Zig
- ✅ Using atomic operations for safe concurrency
- ✅ Building a multi-threaded program in Zig

5.1 Understanding Concurrency vs Parallelism
- 🔹 Concurrency = Running multiple tasks at the same time, but not necessarily in parallel.
- 🔹 Parallelism = Running tasks simultaneously on multiple CPU cores.

How Zig Handles Concurrency
Unlike Go (which has Goroutines) or Rust (which uses async/await), Zig provides low-level threading APIs similar to C.

- 💡 Zig uses threads explicitly, meaning you have to manage them manually.

# Atomic (notes)

## 📌 Key Concepts in This Program

- 1️⃣ What is std.atomic?
std.atomic.Value(T) is a thread-safe wrapper for shared variables.
It ensures operations on the variable are atomic, meaning:
No other thread can modify it between a read and write.
Prevents race conditions (when multiple threads modify shared data at the same time).

- 2️⃣ What is .seq_cst?
.seq_cst (Sequential Consistency) is a memory ordering mode.

It ensures all threads see atomic operations in the same order.

Guarantees that:
Operations are executed in program order.
No reordering of instructions by the CPU.

## 🛠 Memory Order Modes in Zig

Mode	Meaning
- .seq_cst	Strongest guarantee: All threads see updates in the same order.
- .acquire	Ensures reads happen before dependent writes.
- .release	Ensures writes are visible before dependent reads.
- .relaxed	No ordering guarantees (only atomicity).
