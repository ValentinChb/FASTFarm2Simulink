:: Written by Coen-Jan Smits on 12-05-2023 (GPL 3.0 licence)

:: Example connecting plant/custom controller in MATLAB with FAST.farm via Fortran-based MPI wrapper dll
:: Run with administrator rights

:: Use SC_MATLAB.m as a basis to develop custom controller. 
:: See C++ MEX functions for how to call the mpi Fortran dll from MATLAB. 
:: If recompiling of MPI is needed, run SC_MPIServer/Build_SC_MPIServer_DLL.bat

:: The necessary farm-level information is read in by the turbine controller from SC_input.dat located in the OpenFAST folder, itself located in the farm simulation root folder and containing folders for each turbine (this architecture must be respected).
:: SC_input.dat contains 5 inputs: use farm control flag (0 or 1), number of turbines (should match value in .fstf file), farm-level timestep (should match value in .fstf file), path of shared communication file (should match value in SC_MPIServer.m), and ambient wind mode should match value in .fstf file).
:: If recompiling is needed, run Build_DTUWEC-SC-mpi.bat (see script for options)

:: See and run (after having installed an MPI distribution) MPI_libs/Build_lmsmpi.bat to link the MPI libraries used by the MEX functions (SC_MPIServerSubs.f90).
:: Make any verbose is deactivated when debugging MPI is not needed to save computational time.

@echo off
cd SC_MPIServer
start cmd /k matlab -batch "SC_MATLAB; exit" 
timeout -1

:: PRESS ENTER ONCE 'READY TO CONNECT' APPEARS!

:: Run FAST.farm or OpenFAST. Move first to test directory to produce output there. For FAST.farm, it must be consistent with the path (if relative) of MPI_shared.dat in SC_input.dat

:: FAST.farm
cd %~dp0Test3turbines
start /min powershell -NoExit "..\FAST.Farm_x64_OMP.exe FAST.Farm_N3.fstf | tee %~dp0FASTfarm_stdout.txt"

::For connection OpenFAST directly to MATLAB: Make sure that SCClient_64.dll.dll is used in ServoDyn input file. 
::For connection OpenFAST to MATLAB, with DTUWEC as turbine controller: Make sure that SCClient_DTUWEC_64.dll.dll is used in ServoDyn input file. 
::Not using the MPI interface: Make sure that UseSC is set to 0 in SC_input.dat.

::REM cd %~dp0Test3turbines_DTUWEC\OpenFAST\T1
::REM start /min powershell -NoExit " ..\..\..\openfast_x64.exe DTU_10MW_RWT.fst | tee %~dp0OpenFAST_stdout.txt"

cd %~dp0	
