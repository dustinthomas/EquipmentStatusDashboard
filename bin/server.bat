@echo off
REM Start QCI Equipment Status Dashboard server
REM Usage: bin\server.bat

cd /d "%~dp0.."
julia --project=. -e "using Genie; Genie.loadapp(); App.load_app(); up(async=false)"
