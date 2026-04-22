@echo off
set GODOT_EXE="C:\Users\ruley\CornersstoneGamingEngine\Godot\Godot_v4.3-stable_win64.exe"
set SCENE=res://level/scenes/TrainingGround.tscn

set PROJECT_PATH=%~dp0
set PROJECT_PATH=%PROJECT_PATH:~0,-1%

if not exist "%~dp0logs" mkdir "%~dp0logs"
set LOG=%~dp0logs\training_run.log

echo [Training] Starting %date% %time% > "%LOG%"
echo [Training] Project: %PROJECT_PATH% >> "%LOG%"

%GODOT_EXE% --headless --path "%PROJECT_PATH%" %SCENE% >> "%LOG%" 2>&1

echo [Training] Done %date% %time% >> "%LOG%"
echo Done. Check logs\training_run.log
pause
