@echo off
setlocal
rem Read Supabase config from the root .env (gitignored) and pass it to Flutter
rem as compile-time constants, matching how Vercel builds the web app.
for /f "usebackq tokens=1,* delims==" %%A in ("%~dp0.env") do (
  if "%%A"=="VITE_SUPABASE_URL" set "SUPABASE_URL=%%B"
  if "%%A"=="VITE_SUPABASE_ANON_KEY" set "SUPABASE_ANON_KEY=%%B"
)
cd /d "%~dp0mobile_app"
"C:\src\flutter\bin\flutter.bat" run -d web-server --web-port 5173 ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
