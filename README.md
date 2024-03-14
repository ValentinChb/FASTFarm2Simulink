# FASTFarm and MATLAB/Simulink interface

This project aims at coupling NREL's FAST.Farm with The Mathworks' MATLAB/Simulink for wind turbine and farm control purposes, via MPI-based co-simulation on Windows 64-bit machines. 

The orginal MPI Client/Server interface with FAST.Farm has been developed at SINTEF; this project is an extension to MATLAB/Simulink developed by Coen-Jan Smits during his master thesis at TU Delft.

# Installation

The following needs to be installed in order to run the FAST.Farm and MATLAB/Simulink interface: 
- Microsoft MPI (Message passing interface for connecting FAST.Farm to MATLAB)
- MATLAB and Simulink 
- Python distribution (provides dependencies for FAST.Farm)

Binaries for FAST.Farm, the wind turbine controller and libraries for the MPI bridge are provided.

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

Matlab/Simulink acts as an MPI server communicating with MPI client dlls for each turbine, used in lieu of the turbine controller dll in ServoDyn. Information about the client may be found in https://github.com/ValentinChb/SC_MPIClient. This repository provides three versions of client dlls in the OpenFAST/T\<Turbine Number\>/ControlData folder:
- SCClient_64.dll: Uses MPI communication to connect to the turbine-level and farm-level controllers implemented on the server side (i.e. all control commands come from the server)
- SCClient_DTUWEC_64.dll: Uses the DTUWEC controller for turbine-level control. Uses MPI communication to connect to farm-level controller on the server side, and optionally to override turbine-level controls. A similar link may be made to ROSCO. 
- SCClient_Standalone_64.dll: Does not use MPI communication, for debug only. Standalone versions may also be linked to DTUWEC or ROSCO for debug, which should be identical to using the DTUWEC or ROSCO dll directly.

Skelettons of turbine-level and farm-level controllers are provided in the files 'SC_MATLAB.m' or 'SC_Simulink.m' in the 'SC_MPIServer' folder. NOTE: This repository only provides a skeletton of controller. Using SCClient_64.dll as is without linking to DTUWEC or ROSCO will lead to unstable behaviour, unless the effect of controls has been switched off in ElastoDyn through the generator DOF (i.e. using fixed rotor speed).

Running a simulation: 
- In the command prompt, navigate to the folder containing the test file, Call the OpenFAST.exe file (or FAST.Farm.exe file) and then call the file you want to run, example: 
C:\OpenFAST\reg_tests\r-test\glue-codes\openfast\5MW_OC4Semi_Linear> C:\OpenFAST\executables\openfast_x64.exe 5MW_OC4Semi_Linear.fst
- Once FAST.Farm is running, run 'RunTest_MATLAB.bat' or 'RunTest_Simulink.bat' in order to run a test with the interface.  MATLAB needs some time to start the simulation, two screens appear once 'RunTest' is executed. Wait for the message 'ready to connect' before clicking continue (this could last 1 minute at most).
- Once ready, the FAST.Farm simulation starts and connects to MATLAB. A powershell screen should appear showing the progress of the simulation. 

The 'Test3turbines' folder contains the FAST.Farm input file (.fstf file) and the OpenFAST input files (.fst file and servodyn, elastodyn etc). These files can be modified accordingly, but the path tree architecture must be kept. 

# Debugging

FAST.Farm and linking to DTUWEC or ROSCO may be checked separately by using Standalone versions of the client dll.

Information about the MPI connection may be found in stdout_MPIServerSubs.txt for the server (Matlab) side in the Matlab folder, and in stdout_SCClientSubs.txt for the client (Wind turbine controller dlls) side in the OpenFAST/T\<Turbine Number\>/ControlData folder. Compare with the files provided in this repository to identify where the communcation fails/halts. When the communication is deemed robust, outputting these files may be deactivated to save computational time. This is done by switching the verbose flag to false in source code and recompiling (see below).

This is not an official NREL product and thorough testing has not bee conducted. It is expected that users have some knowledge about coding and willingness to look into the various source codes and be able to recompile to find solutions themselves.

# Recompiling/Updating

The MPI-based co-simulation interface consists of a client dll on the OpenFAST side and a server dll and mex files on the Matlab side. This project uses MinGW64 with gcc/gfortran to build these files.
- See https://github.com/ValentinChb/SC_MPIClient for compiling instructions and linking to popular wind turbine controllers (DTUWEC and ROSCO).
- The server dll SC_MPIServerSubs.dll may be compiled using SC_MPIServer/Build_SC_MPIServer_DLL.bat from the source file SC_MPIServer/SC_MPIServer.f90.
- Mex files may be recompiled from source files in SC_MPIServer/Mex Function C++ Code.  see https://se.mathworks.com/help/matlab/cpp-mex-file-applications.html for support.
- OpenFAST/FAST.Farm binaries and source code (for custom builds using intel fortran compiler) can be downloaded online  (see https://openfast.readthedocs.io/en/dev/source/install/index.html).
- MPI libraries may be recompiled following instructions in https://github.com/ValentinChb/SC_MPIClient




