@echo off

echo ========================================
echo Creation structure complete ATP International
echo ========================================
echo.

REM Verification droits administrateur
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERREUR: Execute en tant qu'administrateur
    pause
    exit /b 1
)

echo Etape 1: Creation structure mondiale de base...
PowerShell.exe -ExecutionPolicy Bypass -File "Create-BaseOUStructure.ps1"
if %errorLevel% NEQ 0 (
    echo Erreur etape 1
    pause
    exit /b 1
)

echo.
echo Etape 2: Creation des utilisateurs...
PowerShell.exe -ExecutionPolicy Bypass -File "Create-UserStructure.ps1"

echo.
echo Etape 3: Creation des ordinateurs...
PowerShell.exe -ExecutionPolicy Bypass -File "Create-ComputersStructure.ps1"

echo.
echo Etape 4: Creation des serveurs...
PowerShell.exe -ExecutionPolicy Bypass -File "Create-ServersStructure.ps1"

echo.
echo Etape 5: Creation des groupes...
PowerShell.exe -ExecutionPolicy Bypass -File "Create-GroupsStructure.ps1"

echo.
echo Structure complete creee avec succes!
echo Appuyez sur une touche...
pause >nul
