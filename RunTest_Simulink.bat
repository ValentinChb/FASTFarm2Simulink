:: Example connecting plant/custom controller in Octave with FAST.farm via Fortran-based MPI wrapper dll
:: Run with administrator rights

:: Use SC_MPIServer.m as a basis to develop custom controller. 
:: Activating verbose output in SC_MPIServer.m gives information about the overall communication (start, count of turbine-level and farm-level timesteps, then terminate) in Output_Comm_SC_MPIServer.txt.
:: See SC_MPIServerSubs.cc for how to call the mpi Fortran dll from Octave. 
:: See SC_MPIServerSubs.f90 and stdout_MPIServerSubs.txt (activate first verbose output in SC_MPIServerSubs.f90 for debugging) for deeper insight about the mpi server connection (statically linked to Microsoft MPI dll). 
:: If recompiling is needed, run SC_MPIServer/Build_SC_MPIServer_DLL.bat

:: A similar/complementary connection takes place on the client side (turbine controller dll), see DTUWEC-SC-mpi\src\dtu_we_controller_bladed\SCClientSubs.f90. Verbose output may also be activated there to monitor the MPI communication.
:: The necessary farm-level information is read in by the turbine controller from SC_input.dat located in the OpenFAST folder, itself located in the farm simulation root folder and containing folders for each turbine (this architecture must be respected).
:: SC_input.dat contains 5 inputs: use farm control flag (0 or 1), number of turbines (should match value in .fstf file), farm-level timestep (should match value in .fstf file), path of shared communication file (should match value in SC_MPIServer.m), and ambient wind mode should match value in .fstf file).
:: If recompiling is needed, run Build_DTUWEC-SC-mpi.bat (see script for options)

:: See and run (after having installed an MPI distribution) MPI_libs/Build_lmsmpi.bat to link the MPI libraries used by SC_MPIServerSubs.f90 and SCClientSubs.f90.

:: Make any verbose is deactivated when debugging MPI is not needed to save computational time.



@echo off
cd SC_MPIServer
start cmd /k matlab -batch "SC_Simulink; exit" 
timeout -1

:: PRESS ENTER ONCE 'READY TO CONNECT' APPEARS!

:: Run FAST.farm or OpenFAST. Move first to test directory to produce output there. For FAST.farm, it must be consistent with the path (if relative) of MPI_shared.dat in SC_input.dat
:: FAST.farm
cd %~dp0Test3turbines
start /min powershell -NoExit "..\FAST.Farm_x64_OMP.exe FAST.Farm_N3.fstf | tee %~dp0FASTfarm_stdout.txt"

:: OpenFAST. Make sure that DTUWEC_for_OpenFAST_64.dll is used in ServoDyn input file, or that UseSC is set to 0 in SC_input.dat.
::REM cd %~dp0Test3turbines_DTUWEC\OpenFAST\T1
::REM start /min powershell -NoExit " ..\..\..\openfast_x64.exe DTU_10MW_RWT.fst | tee %~dp0OpenFAST_stdout.txt"

cd %~dp0	
