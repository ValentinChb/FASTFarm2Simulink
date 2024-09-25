# FASTFarm and MATLAB/Simulink interface

This project aims at coupling NREL's FAST.Farm with The Mathworks' MATLAB/Simulink for wind turbine and farm control purposes, via MPI-based co-simulation on Windows 64-bit machines. 

The original MPI Client/Server interface with FAST.Farm has been developed at SINTEF; this project is an extension to MATLAB/Simulink developed by Coen-Jan Smits during his master thesis at TU Delft.

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

Templates of turbine-level and farm-level controllers are provided in the files 'SC_MATLAB.m' or 'SC_Simulink.m' in the 'SC_MPIServer' folder. NOTE: This repository only provides a template skeletton of turbine-level controller. Using SCClient_64.dll (without linking to DTUWEC or ROSCO) and 'SC_MATLAB.m' or 'SC_Simulink.m' as is will lead to unstable behaviour, unless the effect of controls has been switched off in ElastoDyn through the generator DOF (i.e. using fixed rotor speed).

Running a simulation: 
- Run 'RunTest_MATLAB.bat' or 'RunTest_Simulink.bat' in order to run a test with the interface. A command window running Matlab appears. 
- Wait for the message 'ready to connect' in the new window -this could last 1 minute at most-
- Press any key to continue in the original window. A powershell window running FAST.Farm appears.
- Wait for the simulation to finish, progress is shown in th FAST.Farm window. If the simulation is frozen at first timestep, there is likely a problem with MPI connection. See Debugging section for info.

The 'Test3turbines' folder contains the FAST.Farm input file (.fstf file) and the OpenFAST input files (.fst file and servodyn, elastodyn etc). These files can be modified accordingly, but the path tree architecture must be kept. Note that the connection to Matlab/Simulink occurs through the wind turbine controller dll and is therefore independent on the version of OpenFAST, which may be updated at wish.

# Debugging

Check first if the OpenFAST and FAST.Farm executables run correctly by using no turbine controller in ServoDyn and a constant rotor speed. Then check linking to DTUWEC or ROSCO turbine controllers using the above-introduced standalone versions of the client dll in ServoDyn.

Information about the MPI connection may be found in stdout_MPIServerSubs.txt for the server (Matlab) side in the SC_MPIServer folder, and in stdout_SCClientSubs.txt for the client (Wind turbine controller dlls) side in the OpenFAST/T\<Turbine Number\>/ControlData folder. Compare with the files provided in this repository to identify where the communication fails/halts. When the communication is deemed robust, outputting these files may be deactivated to save computational resources. This is done by switching the verbose flag to false in source code and recompiling (see below).

This is not an official NREL product and thorough testing has not been conducted. It is expected that users have some knowledge about coding and willingness to look into the various source codes and be able to recompile to find solutions themselves.

# Recompiling/Updating

The MPI-based co-simulation interface consists of a client dll on the OpenFAST side and a server dll and mex files on the Matlab side. This project uses MinGW64 with gcc/gfortran to build these files.
- See https://github.com/ValentinChb/SC_MPIClient for compiling instructions for the client dll and linking to popular wind turbine controllers (DTUWEC and ROSCO).
- The server dll SC_MPIServerSubs.dll and its static version libSCMPIServerSubs.a may be compiled using SC_MPIServer/Build_SC_MPIServer_DLL.bat from the source file SC_MPIServer/SC_MPIServer.f90.
- Mex files linking to libSC_MPIServerSubs.a and calling SC_MPIServerSubs.dll at runtime may be recompiled from source files in SC_MPIServer/Mex Function C++ Code by running SC_MPIServer/BuildMex.m in Matlab, optionally run directly from Build_SC_MPIServer_DLL.bat. See https://se.mathworks.com/help/matlab/cpp-mex-file-applications.html for support.
- OpenFAST/FAST.Farm binaries and source code (for custom builds using intel fortran compiler) can be downloaded online  (see https://openfast.readthedocs.io/en/dev/source/install/index.html).
- MPI libraries may be recompiled following instructions in https://github.com/ValentinChb/SC_MPIClient

# Citing

When using this work, credit may be given to the associated publication https://iopscience.iop.org/article/10.1088/1742-6596/2626/1/012069 (itself citing this repository)


