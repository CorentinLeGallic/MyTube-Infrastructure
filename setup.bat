@echo off
setlocal enableextensions enabledelayedexpansion

@REM Get the carriage return character and store it in a `CR` variable
call :FindCR

@REM Install the backend repository

cd ../backend

@REM Clone the backend repository if it doesn't already exist
if %errorlevel% neq 0 (
  echo Cloning backend repository...

  git clone https://github.com/CorentinLeGallic/MyTube-BackEnd.git

  if %errorlevel% neq 0 call :ShowError "failed cloning backend"

  cd ../backend
)

@REM Create 2 temp lock files (one will be deleted if the `npm install` command succeeds, the other if the `npm install` command fails)
call :CreateLockFiles mytube_backend_npm_install

@REM Run `npm install` in another terminal instance, and delete whether the lockfile or the errorfile depending on the operation's result
start /b cmd /c "call npm install --silent && (del %lockfile%) || (del %errorfile%)"

@REM Show a loader until `npm install` finishes
call :DependencyLoaderLoop "%lockfile%" "%errorfile%" "Installing backend dependencies..."

if %errorlevel% neq 0 call :ShowError "npm install failed in backend/"

echo Backend dependencies installed successfully

@REM Install the frontend repository

cd ../frontend

@REM Clone the backend repository if it doesn't already exist
if %errorlevel% neq 0 (
  echo Cloning frontend repository...

  git clone https://github.com/CorentinLeGallic/MyTube-FrontEnd.git

  if %errorlevel% neq 0 call :ShowError "failed cloning frontend"

  cd ../frontend
)

@REM Create 2 temp lock files (one will be deleted if the `npm install` command succeeds, the other if the `npm install` command fails)
call :CreateLockFiles mytube_frontend_npm_install

@REM Run `npm install` in another terminal instance, and delete whether the lockfile or the errorfile depending on the operation's result
start /b cmd /c "call npm install --silent && (del %lockfile%) || (del %errorfile%)"

@REM Show a loader until `npm install` finishes
call :DependencyLoaderLoop "%lockfile%" "%errorfile%" "Installing frontend dependencies..."

if %errorlevel% neq 0 call :ShowError "npm install failed in frontend/"

echo Frontend dependencies installed successfully

@REM Ask for the user to set the backend environement variables
echo Set the backend/.env environement variables, then press any key to continue
pause >nul

@REM Ask for the user to set the frontend environement variables
echo Set the frontend/.env environement variables, then press any key to continue
pause >nul

@REM Ask for the user to set the infrastructure environement variables
echo Set the infrastructure/.env environement variables, then press any key to continue
pause >nul

@REM Generate the Prisma Client database

cd ../backend

echo Generating Prisma Client...

call npx prisma generate 1> nul 2> nul

if %errorlevel% neq 0 call :ShowError "npx prisma generate failed"

@REM Launch Docker Desktop

cd ../infrastructure

@REM Checks whether docker-compose is already running or not
docker-compose ls 1>nul 2>nul

if %errorlevel% neq 0 (
  @REM If the default Docker Desktop.exe path doesn't exist, let the user install / run Docker Desktop
  if not exist "C:\Program Files\Docker\Docker\Docker Desktop.exe" (
    echo %errorlevel%
    echo Open Docker Desktop, then press any key to continue
    pause >nul
  ) else (
    @REM If the default Docker Desktop.exe path exists, run Docker Desktop
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"

    @REM Show a loader until Docker Desktop is ready
    call :DockerLoaderLoop "Launching Docker Desktop..."
  )
)

echo Launching Docker containers...

@REM Up the Docker containers in DEV mode
call docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --watch

if %errorlevel% neq 0 call :ShowError "failed starting the Docker containers"

exit 0

@REM Create 2 temp lock files (one will be deleted if the command succeeds, the other if the command fails)
:CreateLockFiles
set "lockfile=%temp%\%1.lock"
del "%lockfile%" 2>nul
type nul > "%lockfile%"

set "errorfile=%temp%\%1_error.lock"
del "%errorfile%" 2>nul
type nul > "%errorfile%"
exit /b 0

@REM Find the carriage return character and store it in a `CR` variable
:FindCR
for /f %%a in ('copy /Z "%~dpf0" nul') do set "CR=%%a"
exit /b 0

@REM Rewrite the previous line with a loader character and wait 1 second
:ShowLoaderLoopChar
<nul set /p "=%~1 %~2 !CR!"
timeout /t 1 > nul
exit /b 0

@REM Check whether Docker Desktop is ready and shows a loader until it is
:DockerLoaderLoop
docker-compose ls 1>nul 2>nul

if %errorlevel% == 0 exit /b 0
call :ShowLoaderLoopChar "|" %1

docker-compose ls 1>nul 2>nul

if %errorlevel% == 0 exit /b 0
call :ShowLoaderLoopChar "/" %1

docker-compose ls 1>nul 2>nul

if %errorlevel% == 0 exit /b 0
call :ShowLoaderLoopChar "-" %1

docker-compose ls 1>nul 2>nul

if %errorlevel% == 0 exit /b 0
call :ShowLoaderLoopChar "\" %1

goto :DockerLoaderLoop

@REM Check whether one of the lock files is deleted and shows a loader until one is
:DependencyLoaderLoop
if not exist %1 exit /b 0
if not exist %2 exit /b 1
call :ShowLoaderLoopChar "|" %3

if not exist %1 exit /b 0
if not exist %2 exit /b 1
call :ShowLoaderLoopChar "/" %3

if not exist %1 exit /b 0
if not exist %2 exit /b 1
call :ShowLoaderLoopChar "-" %3

if not exist %1 exit /b 0
if not exist %2 exit /b 1
call :ShowLoaderLoopChar "\" %3

goto :DependencyLoaderLoop

@REM Echo an error message and exit
:ShowError
echo Error : %1
exit 1