@echo off
chcp 65001 > nul
cd /d "%~dp0"

echo Запуск AI-агента для Godot проекта
echo Сервер должен быть запущен на 192.168.1.106:11434
echo.

:loop
python agent_cli.py
if %errorlevel% neq 0 (
    echo.
    echo Перезапуск агента...
    timeout /t 2
    goto loop
)