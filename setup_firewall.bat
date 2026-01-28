@echo off
echo ========================================
echo SLTB Survey - Firewall Setup
echo Run this as Administrator!
echo ========================================
echo.

echo Adding firewall rule for Apache (port 80)...
netsh advfirewall firewall add rule name="Apache HTTP 80" dir=in action=allow protocol=TCP localport=80

echo.
echo Firewall rules added successfully!
echo.
echo Your phone should now be able to connect to:
echo http://172.20.10.3/sltb/save_asset.php
echo.
pause
