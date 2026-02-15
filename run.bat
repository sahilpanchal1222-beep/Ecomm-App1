@echo off
setlocal EnableDelayedExpansion

:: Change to script directory
cd /d "%~dp0"

:: Get database type from .env
for /f "tokens=2 delims=" %%a in ('findstr /B "DATABASE_TYPE=" .env') do (
    set "DB_TYPE=%%a"
)
set "DB_TYPE=%DB_TYPE:"=%"
if not defined DB_TYPE set "DB_TYPE=postgresql"

:: Show help
if "%~1"=="help" goto :help
if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help
if "%~1"=="" goto :help

:: Parse command
goto :%1 2>nul || (
    echo Unknown command: %1
    call :help
    exit /b 1
)

:help
echo 🛒 E-commerce App - Run Script
echo.
echo Current Database: %DB_TYPE%
echo.
echo Usage: run.bat ^<command^> [db-type]
echo.
echo Database Commands:
echo   setup [pg^|sqlite]  - Setup database (generates client, migrates, seeds)
echo   dev [pg^|sqlite]    - Start both frontend ^& backend development servers
echo   backend [pg^|sqlite]- Start only the backend server
echo   seed [pg^|sqlite]   - Seed database with sample products
echo   migrate [pg^|sqlite]- Run database migrations
echo   studio [pg^|sqlite] - Open Prisma Studio
echo.
echo Other Commands:
echo   frontend           - Start only the frontend server
echo   build              - Build for production
echo   start [pg^|sqlite]  - Start production server
echo   switch ^<pg^|sqlite^> - Switch database type
echo   status             - Show current configuration
echo   help               - Show this help message
echo.
echo Current Database Type: %DB_TYPE%
echo.
exit /b 0

:status
echo 📊 Current Configuration
echo =======================
echo Database Type: %DB_TYPE%
echo.
for /f "tokens=2 delims=" %%a in ('findstr /B "DATABASE_URL=" .env') do (
    echo DATABASE_URL: %%a
)
echo.
exit /b 0

:switch
set "NEW_TYPE=%~2"
if not defined NEW_TYPE (
    echo ❌ Please specify database type: pg or sqlite
    exit /b 1
)

if /i "%NEW_TYPE%"=="pg" (
    set "FULL_TYPE=postgresql"
) else if /i "%NEW_TYPE%"=="sqlite" (
    set "FULL_TYPE=sqlite"
) else (
    echo ❌ Invalid database type. Use 'pg' or 'sqlite'
    exit /b 1
)

:: Update .env file
powershell -Command "(Get-Content .env) -replace '^DATABASE_TYPE=.*', 'DATABASE_TYPE=\"%FULL_TYPE%\"' | Set-Content .env"

echo ✅ Switched to %FULL_TYPE%
echo.
echo ⚠️  Important: If switching databases, you need to:
echo    1. Run migrations: run.bat migrate %NEW_TYPE%
echo    2. Re-seed data: run.bat seed %NEW_TYPE%
echo.
exit /b 0

:setup
set "DB_ARG=%~2"
if not defined DB_ARG set "DB_ARG=%DB_TYPE%"
call :get_full_type "!DB_ARG!" FULL_TYPE
call :get_db_name "!DB_ARG!" DB_NAME

echo 🔧 Setting up !DB_NAME! database...
cd backend
set "DATABASE_TYPE=!FULL_TYPE!"
npm run setup
cd ..
echo.
echo ✅ Database setup complete!
exit /b 0

:dev
set "DB_ARG=%~2"
if not defined DB_ARG set "DB_ARG=%DB_TYPE%"
call :get_full_type "!DB_ARG!" FULL_TYPE
call :get_db_name "!DB_ARG!" DB_NAME

echo 🚀 Starting development servers with !DB_NAME!...
echo.
echo Frontend: http://localhost:5173
echo Backend:  http://localhost:3000
echo Database: !DB_NAME!
echo.
start cmd /k "cd backend && set DATABASE_TYPE=!FULL_TYPE! && npm run dev"
start cmd /k "cd frontend && npm run dev"
exit /b 0

:backend
set "DB_ARG=%~2"
if not defined DB_ARG set "DB_ARG=%DB_TYPE%"
call :get_full_type "!DB_ARG!" FULL_TYPE
call :get_db_name "!DB_ARG!" DB_NAME

echo 🚀 Starting backend server with !DB_NAME!...
cd backend
set "DATABASE_TYPE=!FULL_TYPE!"
npm run dev
cd ..
exit /b 0

:frontend
echo 🚀 Starting frontend server...
cd frontend
npm run dev
cd ..
exit /b 0

:build
echo 🔨 Building application...
echo Building backend...
cd backend
npm run build
cd ..
echo Building frontend...
cd frontend
npm run build
cd ..
echo ✅ Build complete!
exit /b 0

:start
set "DB_ARG=%~2"
if not defined DB_ARG set "DB_ARG=%DB_TYPE%"
call :get_full_type "!DB_ARG!" FULL_TYPE
call :get_db_name "!DB_ARG!" DB_NAME

echo 🚀 Starting production server with !DB_NAME!...
cd backend
set "DATABASE_TYPE=!FULL_TYPE!"
npm run start
cd ..
exit /b 0

:seed
set "DB_ARG=%~2"
if not defined DB_ARG set "DB_ARG=%DB_TYPE%"
call :get_full_type "!DB_ARG!" FULL_TYPE
call :get_db_name "!DB_ARG!" DB_NAME

echo 🌱 Seeding !DB_NAME! database...
cd backend
set "DATABASE_TYPE=!FULL_TYPE!"
npm run prisma:seed
cd ..
exit /b 0

:migrate
set "DB_ARG=%~2"
if not defined DB_ARG set "DB_ARG=%DB_TYPE%"
call :get_full_type "!DB_ARG!" FULL_TYPE
call :get_db_name "!DB_ARG!" DB_NAME

echo 📦 Running migrations for !DB_NAME!...
cd backend
set "DATABASE_TYPE=!FULL_TYPE!"
npm run prisma:migrate
cd ..
exit /b 0

:studio
set "DB_ARG=%~2"
if not defined DB_ARG set "DB_ARG=%DB_TYPE%"
call :get_full_type "!DB_ARG!" FULL_TYPE
call :get_db_name "!DB_ARG!" DB_NAME

echo 🎨 Opening Prisma Studio for !DB_NAME!...
cd backend
set "DATABASE_TYPE=!FULL_TYPE!"
npm run prisma:studio
cd ..
exit /b 0

:install
echo 📦 Running install script...
call install.bat
exit /b 0

:: Helper functions
:get_full_type
if /i "%~1"=="pg" (
    set "%2=postgresql"
) else (
    set "%2=sqlite"
)
exit /b 0

:get_db_name
if /i "%~1"=="pg" (
    set "%2=PostgreSQL"
) else (
    set "%2=SQLite"
)
exit /b 0
