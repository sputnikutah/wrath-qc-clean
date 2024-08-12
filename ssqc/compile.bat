@echo ---------------------------------------------------------------------------------------------------
del ..\..\progs.dat
del ..\..\csprogs.dat
.\win64-fteqcc.exe
copy ..\..\progs.dat E:\Steam\steamapps\common\WRATH\kp1
copy ..\..\csprogs.dat E:\Steam\steamapps\common\WRATH\kp1
pause
