@echo off
rem ============================================================================
rem  Friendly launcher. Double-click this to open the PS3 Controller Setup window.
rem  The window runs the PROVEN Setup-PS3-Controller.cmd underneath - this file
rem  only opens the nice window.
rem
rem  PLACEMENT: put this file AND the "gui" folder in the SAME folder as
rem  Setup-PS3-Controller.cmd.
rem
rem  If the window ever fails to open, you can still run Setup-PS3-Controller.cmd
rem  directly - that is the proven path and always works.
rem ============================================================================
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0gui\PS3SetupGui.ps1"
