@echo off
echo off

@REM zig build-lib .\hello\greetings.zig -dynamic -O ReleaseSafe -fPIC -target native-windows-gnu 
zig build-lib .\main.zig -dynamic -target native-windows-gnu -O ReleaseSafe -femit-bin=output/fib.dll
