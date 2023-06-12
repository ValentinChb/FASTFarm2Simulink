:: Written by Valentin Chabaud on 12-05-2022 (GPL 3.0 licence)

:: Adapted from https://abhilashreddy.com/writing/3/mpi_instructions.html
:: TODO: Install MPI and MPI SDK, run "set MSMPI" to check install and see the relevant directories %MSMPI_LIB64% and %MSMPI_INC% that should be added to PATH 
copy "%MSMPI_LIB64%\msmpi.lib" %~dp0
copy "%SYSTEMROOT%\System32\msmpi.dll" %~dp0
gendef %~dp0msmpi.dll
move .\msmpi.def %~dp0
dlltool -d %~dp0msmpi.def -l %~dp0libmsmpi.a -D %~dp0msmpi.dll
:: TODO: Change include "mpifptr.h" to "x64/mpifptr.h" in %MSMPI_INC%\mpi.90
gfortran -fallow-invalid-boz "%MSMPI_INC%\mpi.f90"
move .\mpi*.mod %~dp0
