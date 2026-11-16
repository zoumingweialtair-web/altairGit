@echo off
setlocal
set "GODOT=C:\Users\zoumingwei\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT%" (
  echo Godot was not found. Import project.godot in Godot 4.
  pause
  exit /b 1
)
start "" "%GODOT%" --editor --path "%~dp0." res://main.tscn
