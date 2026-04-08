@echo off
setlocal EnableExtensions
chcp 65001 >nul

set "PROJECT_ROOT=D:\Study\deep-learning_study"
set "ENV_NAME=tf-311"

call :find_conda
if errorlevel 1 goto :fail

if not exist "%PROJECT_ROOT%" (
    echo [ERROR] Project folder not found:
    echo %PROJECT_ROOT%
    goto :fail
)

echo Opening work session for %ENV_NAME% ...
echo.

start "JupyterLab (%ENV_NAME%)" cmd /k ""%CONDA_BAT%" activate "%ENV_NAME%" && cd /d "%PROJECT_ROOT%" && echo [Jupyter window ready] && jupyter lab"

start "Package Console (%ENV_NAME%)" cmd /k ""%CONDA_BAT%" activate "%ENV_NAME%" && cd /d "%PROJECT_ROOT%" && echo [Package console ready] && echo Use: conda install ^<pkg^>  or  pip install ^<pkg^>"

echo [DONE] Opened:
echo   1) JupyterLab (%ENV_NAME%)
echo   2) Package Console (%ENV_NAME%)
echo.
goto :eof

:find_conda
set "CONDA_BAT="

for /f "delims=" %%I in ('where conda.bat 2^>nul') do (
    set "CONDA_BAT=%%I"
    goto :conda_found
)

if exist "%USERPROFILE%\miniconda3\condabin\conda.bat" set "CONDA_BAT=%USERPROFILE%\miniconda3\condabin\conda.bat"
if exist "%USERPROFILE%\anaconda3\condabin\conda.bat" set "CONDA_BAT=%USERPROFILE%\anaconda3\condabin\conda.bat"
if exist "C:\ProgramData\miniconda3\condabin\conda.bat" set "CONDA_BAT=C:\ProgramData\miniconda3\condabin\conda.bat"
if exist "C:\ProgramData\anaconda3\condabin\conda.bat" set "CONDA_BAT=C:\ProgramData\anaconda3\condabin\conda.bat"

:conda_found
if defined CONDA_BAT (
    exit /b 0
) else (
    echo [ERROR] conda.bat not found.
    exit /b 1
)

:fail
echo.
echo [FAILED]
exit /b 1