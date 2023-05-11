# FASTFarm and MATLAB/Simulink interface

This project aims at coupling NREL's FAST.Farm with The Mathworks' MATLAB/Simulink for wind turbine and farm control purposes, via MPI-based co-simulation on Windows 64-bit machines.

# Installation

The following needs to be installed in order to run the FAST.Farm and MATLAB/Simulink interface: 
- Microsoft MPI (Message passing interface for connecting FAST.Farm to MATLAB)
- MATLAB and Simulink 
- Python distribution (provides dependencies for FAST.Farm)

See the OpenFAST documentation for more information about the input files of FAST.Farm and OpenFAST. Be sure that OpenFAST and FAST.Farm work. The 'r-test' folder form the OpenFAST GitHub (https://github.com/OpenFAST) contains simulation tests, try to run 1 or 2 of these tests.  
The OpenFAST GitHub also contains a 'MATLAB_Toolbox', this toolbox contains functions that can be run in MATLAB in order to visualize the generated simulation results. 

It may be necessary to add the following libraries to your path (they should be found in the Python distribution's bin folder). These libraries are needed for running FAST.Farm (OpenFAST works without those). If a library has a sligthly different name (e.g. '.1' at the end), create a copy and rename. 
- libifportMD.dll
- libifcoremd.dll
- libiomp5md.dll
- libmmd.dll
- mkl_sequential.dll 
- mkl_core.dll
- svml_dispmd.dll

# Use

Running a simulation: In the command prompt, navigate to the folder containing the test file, Call the OpenFAST.exe file (or FAST.Farm.exe file) and then call the file you want to run, example: 
C:\OpenFAST\reg_tests\r-test\glue-codes\openfast\5MW_OC4Semi_Linear> C:\OpenFAST\executables\openfast_x64.exe 5MW_OC4Semi_Linear.fst

Once FAST.Farm works, run 'RunTest_MATLAB.bat' or 'RunTest_Simulink.bat' in order to run a test with the interface. A turbine-level and farm-level controller can be constructed in the files 'SC_MATLAB' or 'SC_Simulink' in the 'SC_MPIServer' folder. MATLAB needs some time to start the simulation, two screens appear once 'RunTest' is executed. Wait for the message 'ready to connect' before clicking continue (this could last 1 minute at most). Once ready, the FAST.Farm simulation starts and connects to MATLAB. A powershell screen should appear showing the progress of the simulation. 

The 'Test3turbines' folder contains the FAST.Farm input file (.fstf file) and the OpenFAST input files (.fst file and servodyn, elastodyn etc). These files can be modified accordingly. 

# Recompiling/Updating

The MPI-based co-simulation interface consists of a client dll on the OpenFAST side and a server dll and mex files on the Matlab side. This project uses MinGW64 with gcc/gfortran to build these files.
- The client dll is used in lieu of the turbine controller dll in ServoDyn. See https://github.com/ValentinChb/SC_MPIClient for compiling instructions and linking to popular wind turbine controllers (DTUWEC and ROSCO).
- The server dll SC_MPIServerSubs.dll may be compiled using SC_MPIServer/Build_SC_MPIServer_DLL.bat from the source file SC_MPIServer/SC_MPIServer.f90.
- Mex files may be recompiled from source files in SC_MPIServer/Mex Function C++ Code.  see https://se.mathworks.com/help/matlab/cpp-mex-file-applications.html for support.
- OpenFAST/FAST.Farm binaries and source code (for custom builds using intel fortran compiler) can be downloaded online  (see https://openfast.readthedocs.io/en/dev/source/install/index.html).
- MPI libraries may be recompiled following instructions in https://github.com/ValentinChb/SC_MPIClient




