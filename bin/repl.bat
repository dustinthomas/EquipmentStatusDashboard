@echo off
REM Start Genie REPL for QCI Equipment Status Dashboard
REM Usage: bin\repl.bat

cd /d "%~dp0.."
julia --project=. -e "using Genie; Genie.loadapp(); println(\"App loaded. Use App.load_app() then up() to start server.\")" -i
