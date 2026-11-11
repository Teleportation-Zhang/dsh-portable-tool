@echo off
chcp 936 >nul
start "" powershell -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0console\DSH-Portable-Console.ps1"
