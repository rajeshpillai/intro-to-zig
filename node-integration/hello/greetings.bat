@echo off
echo off

@REM zig build-lib .\hello\greetings.zig -dynamic -O ReleaseSafe -fPIC -target native-windows-gnu 
zig build-lib .\greetings.zig -dynamic -target native-windows-gnu -O ReleaseSafe -femit-bin=output/greetings.dll
