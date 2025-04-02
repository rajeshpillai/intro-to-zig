@echo off
echo off

@REM zig build-lib .\hello\greetings.zig -dynamic -O ReleaseSafe -fPIC -target native-windows-gnu 
zig build-exe .\fib_cli.zig -O ReleaseFast -femit-bin=output/fib.exe
