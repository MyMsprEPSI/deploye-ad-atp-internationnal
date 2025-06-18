@echo off

echo ========================================
echo Creation complete structure OU ATP
echo ========================================
echo.

REM Verification droits administrateur
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERREUR: Execute en tant qu'administrateur
    pause
    exit /b 1
)

echo Etape 1: Creation structure de base...
PowerShell.exe -ExecutionPolicy Bypass -File "Create-BaseOUStructure.ps1"

if %errorLevel% NEQ 0 (
    echo Erreur lors de la creation de la structure de base
    pause
    exit /b 1
)

echo.
echo Etape 2: Creation des utilisateurs...
PowerShell.exe -ExecutionPolicy Bypass -File "Create-InternationalUsers.ps1"

echo.
echo Processus termine. Appuyez sur une touche...
pause >nul
