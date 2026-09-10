@echo off
REM ============================================================
REM  Assistive YOLOv8 eSpeak - One-Click Runner (Windows)
REM  Edit the variables below to change model or image size.
REM ============================================================

REM --- Configurable arguments (edit these) ---
set MODEL=yolov8s.pt
set IMGSZ=480

REM --- Resolved script directory (three-level nesting) ---
set SCRIPT_DIR=%~dp0ultralytics-main\ultralytics-main

echo.
echo  [Assistive Vision] Starting with model=%MODEL%  imgsz=%IMGSZ%
echo  Working directory: %SCRIPT_DIR%
echo.

cd /d "%SCRIPT_DIR%"
python assistive_yolov8_espeak.py --model %MODEL% --imgsz %IMGSZ%

if %ERRORLEVEL% neq 0 (
    echo.
    echo  [ERROR] Script exited with code %ERRORLEVEL%.
    pause
)
