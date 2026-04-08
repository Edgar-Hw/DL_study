@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

set "PROJECT_ROOT=D:\Study\deep-learning_study"
set "ENV_NAME=tf-311"
set "PYTHON_VER=3.11"
set "KERNEL_NAME=dl-study"
set "KERNEL_DISPLAY=Python (DL Study)"
set "README_TITLE=DL Study"

echo.
echo ========================================================
echo   One-time setup: TensorFlow + JupyterLab
echo ========================================================
echo.

call :find_conda
if errorlevel 1 goto :fail

if not exist "%PROJECT_ROOT%" (
    echo [ERROR] Project folder not found:
    echo %PROJECT_ROOT%
    echo.
    echo First, clone the GitHub repo to this exact path.
    goto :fail
)

cd /d "%PROJECT_ROOT%" || goto :fail

echo [1/6] Checking conda environment...
call "%CONDA_BAT%" env list | findstr /R /C:"^[ ]*%ENV_NAME%[ ]" >nul
if %errorlevel%==0 (
    echo [OK] Environment "%ENV_NAME%" already exists.
) else (
    echo [INFO] Creating environment "%ENV_NAME%" with Python %PYTHON_VER% ...
    call "%CONDA_BAT%" create -y -n "%ENV_NAME%" python=%PYTHON_VER%
    if errorlevel 1 goto :fail
)

echo [2/6] Installing JupyterLab and ipykernel...
call "%CONDA_BAT%" run -n "%ENV_NAME%" conda install -y -c conda-forge jupyterlab ipykernel
if errorlevel 1 goto :fail

echo [3/6] Upgrading pip tools...
call "%CONDA_BAT%" run -n "%ENV_NAME%" python -m pip install --upgrade pip setuptools wheel
if errorlevel 1 goto :fail

echo [4/6] Installing TensorFlow...
call "%CONDA_BAT%" run -n "%ENV_NAME%" python -m pip install --upgrade tensorflow
if errorlevel 1 goto :fail

echo [5/6] Registering Jupyter kernel...
call "%CONDA_BAT%" run -n "%ENV_NAME%" python -m ipykernel install --user --name "%KERNEL_NAME%" --display-name "%KERNEL_DISPLAY%"
if errorlevel 1 goto :fail

echo [6/6] Writing helper files...
if not exist ".gitignore" (
    > ".gitignore" (
        echo __pycache__/
        echo *.py[cod]
        echo .pytest_cache/
        echo .mypy_cache/
        echo .ruff_cache/
        echo .ipynb_checkpoints/
        echo .vscode/
        echo .idea/
        echo .venv/
        echo env/
        echo ENV/
        echo *.log
        echo Thumbs.db
        echo .DS_Store
    )
)

if not exist "README.md" (
    > "README.md" (
        echo # %README_TITLE%
        echo.
        echo Environment: `%ENV_NAME%`
        echo.
        echo - Python %PYTHON_VER%
        echo - TensorFlow
        echo - JupyterLab
        echo - ipykernel
    )
)

call "%CONDA_BAT%" run -n "%ENV_NAME%" python -m pip freeze > requirements.txt
call "%CONDA_BAT%" env export -n "%ENV_NAME%" > environment.yml

echo.
echo [DONE] Setup finished.
echo Now open GitHub Desktop, review changes, commit, and Push origin.
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
    echo Please install Miniconda or Anaconda first.
    exit /b 1
)

:fail
echo.
echo [FAILED]
exit /b 1