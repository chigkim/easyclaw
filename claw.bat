@echo off
setlocal enabledelayedexpansion

where docker >nul 2>nul
if errorlevel 1 (
  echo Docker is not installed or not on PATH.
  exit /b 1
)

docker compose version >nul 2>nul
if errorlevel 1 (
  echo Docker Compose is unavailable.
  exit /b 1
)

where python >nul 2>nul
if errorlevel 1 (
  echo Python is not installed or not on PATH.
  exit /b 1
)

set "COMPOSE_FILES=-f docker-compose.yml -f docker-compose.windows.yml"
set "EXEC_ENV="

if /I "%~1"=="init" goto :init
if /I "%~1"=="config" goto :config
if /I "%~1"=="log" goto :log
if /I "%~1"=="start" goto :start
if /I "%~1"=="stop" goto :stop
if /I "%~1"=="restart" goto :restart
if /I "%~1"=="build" goto :build
if /I "%~1"=="update" goto :update
if /I "%~1"=="run" goto :run
if /I "%~1"=="dashboard" goto :dashboard

goto :usage

:usage
echo Usage: claw [init^|config^|log^|start^|stop^|restart^|build^|update^|run^|dashboard]
exit /b 1

:init
if exist claw\ (
    set "CONFIRM_INIT="
    set /p "CONFIRM_INIT=Directory 'claw' already exists. Do you want to delete it and start over? (y/N): "
    if /I not "!CONFIRM_INIT!"=="y" (
        echo Initialization cancelled.
        goto :success
    )
)
echo Initializing...
python scripts/config.py
if errorlevel 1 goto :fail
docker compose %COMPOSE_FILES% down claw
if errorlevel 1 goto :fail
if exist claw\ rmdir /s /q claw
if errorlevel 1 goto :fail
mkdir claw
if errorlevel 1 goto :fail
copy /Y openclaw.json claw\
if errorlevel 1 goto :fail
docker compose %COMPOSE_FILES% up -d --build claw
if errorlevel 1 goto :fail
goto :success

:config
echo Generating config...
python scripts/config.py
if errorlevel 1 goto :fail
if exist claw\openclaw.json (
    set "CONFIRM_CONFIG="
    set /p "CONFIRM_CONFIG=File 'claw\openclaw.json' already exists. Do you want to replace it? (y/N): "
    if /I "!CONFIRM_CONFIG!"=="y" (
        copy /Y openclaw.json claw\
    ) else (
        echo Config replacement cancelled.
    )
) else if exist claw\ (
    copy /Y openclaw.json claw\
)
if errorlevel 1 goto :fail
goto :success

:log
echo Showing logs...
docker compose %COMPOSE_FILES% logs -f claw
if errorlevel 1 goto :fail
goto :success

:start
echo Starting...
docker compose %COMPOSE_FILES% up -d claw
if errorlevel 1 goto :fail
goto :success

:stop
echo Stopping...
docker compose %COMPOSE_FILES% down claw
if errorlevel 1 goto :fail
goto :success

:restart
echo Restarting...
docker compose %COMPOSE_FILES% restart claw
if errorlevel 1 goto :fail
goto :success

:build
echo Building...
python scripts/config.py
if errorlevel 1 goto :fail
docker compose %COMPOSE_FILES% down claw
if errorlevel 1 goto :fail
docker compose %COMPOSE_FILES% up -d --build claw
if errorlevel 1 goto :fail
goto :success

:update
echo Updating...
docker compose %COMPOSE_FILES% down claw
if errorlevel 1 goto :fail
docker compose %COMPOSE_FILES% up -d --build --pull always claw
if errorlevel 1 goto :fail
goto :success

:run
shift
if "%~1"=="" goto :run_usage
set "RUN1=%~1"
set "RUN2=%~2"
set "RUN3=%~3"
set "RUN4=%~4"
set "ARGS="

:run_loop
if "%~1"=="" goto :run_exec
call set ARGS=%%ARGS%% ^"%%~1^"
shift
goto :run_loop

:run_exec
if "%RUN2%"=="" (
  if /I "%RUN1%"=="sh" call set ARGS=%%ARGS%% ^"-i^"
  if /I "%RUN1%"=="bash" call set ARGS=%%ARGS%% ^"-i^"
  if /I "%RUN1%"=="ash" call set ARGS=%%ARGS%% ^"-i^"
  if /I "%RUN1%"=="zsh" call set ARGS=%%ARGS%% ^"-i^"
)
call :set_exec_tz
echo Running in container:%ARGS%
if /I "%RUN1%"=="openclaw" if /I "%RUN2%"=="dashboard" if /I "%RUN3%"=="--no-open" if "%RUN4%"=="" goto :run_dashboard_no_open
docker compose %COMPOSE_FILES% exec %EXEC_ENV% -u node claw%ARGS%
if errorlevel 1 goto :fail
goto :success

:dashboard
echo Showing dashboard...
call :set_exec_tz
set "TMPFILE=%TEMP%\claw-dashboard-%RANDOM%%RANDOM%.txt"
docker compose %COMPOSE_FILES% exec %EXEC_ENV% -u node claw openclaw dashboard --no-open > "%TMPFILE%"
set "CMD_EXIT=%ERRORLEVEL%"
powershell -NoProfile -Command "(Get-Content -LiteralPath '%TMPFILE%') -replace 'http://0\.0\.0\.0:', 'http://127.0.0.1:'"
del "%TMPFILE%" >nul 2>nul
if not "%CMD_EXIT%"=="0" goto :fail
goto :success

:run_dashboard_no_open
set "TMPFILE=%TEMP%\claw-dashboard-%RANDOM%%RANDOM%.txt"
docker compose %COMPOSE_FILES% exec %EXEC_ENV% -u node claw%ARGS% > "%TMPFILE%"
set "CMD_EXIT=%ERRORLEVEL%"
powershell -NoProfile -Command "(Get-Content -LiteralPath '%TMPFILE%') -replace 'http://0\.0\.0\.0:', 'http://127.0.0.1:'"
del "%TMPFILE%" >nul 2>nul
if not "%CMD_EXIT%"=="0" goto :fail
goto :success

:set_exec_tz
set "EXEC_ENV="
if exist claw\timezone (
  set /p TZ_OVERRIDE=<claw\timezone
  if defined TZ_OVERRIDE set "EXEC_ENV=-e TZ=!TZ_OVERRIDE!"
)
exit /b 0

:run_usage
echo Usage: claw run ^<command^> [args...]
goto :fail

:fail
set "EXITCODE=1"
goto :end

:success
set "EXITCODE=0"
goto :end

:end
endlocal
exit /b %EXITCODE%
