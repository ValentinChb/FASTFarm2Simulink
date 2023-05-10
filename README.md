# FASTFarm and MATLAB/Simulink interface

The following programs need to be installed in order to run the FAST.Farm and MATLAB/Simulink interface: 
- MinGW (add \bin to system variables)
- Microsoft MPI (Message passing interface for connecting FAST.Farm to MATLAB)
- MATLAB and Simulink 
    - Add MinGW-w64 package for running and compiling MEX functions 
- Anaconda or Miniconda (contains libraries thar are needed for running FAST.Farm)

- Microsof Visual Studio could be downloaded for writing Fortran DLLs for FAST.Farm (not needed for this interface)

Add the following libraries to your path (mkl libraries can be added by downloading Miniconda, the others should be in the MinGW folder). These libraries are needed for running FAST.Farm (OpenFAST works without those). Some libraries have '.1' at the end, if so, change the name of those libraries. 
- libifportMD.dll
- libifcoremd.dll
- libiomp5md.dll
- libmmd.dll
- mkl_sequential.dll (anaconda library in \pachages\bin)
- mkl_core.dll (anaconda library in \pachages\bin)
- svml_dispmd.dll

FAST.Farm can be downloaded Online (https://openfast.readthedocs.io/en/dev/source/install/index.html), or from this reposistory. See the OpenFAST documentation for more information about the input files of FAST.Farm and OpenFAST. Be sure that OpenFAST and FAST.Farm work. The 'r-test' folder form the OpenFAST GitHub (https://github.com/OpenFAST) contains simulation tests, try to run 1 or 2 of these tests.  
The OpenFAST GitHub also contains a 'MATLAB_Toolbox', this toolbox contains functions that can be run in MATLAB in order to visualize the generated simulation results. 

Running a simulation: In the command prompt, navigate to the folder containing the test file, Call the OpenFAST.exe file (or FAST.Farm.exe file) and then call the file you want to run, example: 
C:\OpenFAST\reg_tests\r-test\glue-codes\openfast\5MW_OC4Semi_Linear> C:\OpenFAST\executables\openfast_x64.exe 5MW_OC4Semi_Linear.fst

Once FAST.Farm works, run 'RunTest_MATLAB.bat' or 'RunTest_Simulink.bat' in order to run a test with the interface. A turbine-level and farm-level controller can be constructed in the files 'SC_MATLAB' or 'SC_Simulink' in the 'SC_MPIServer' folder. MATLAB needs some time to start the simulation, two screens appear once 'RunTest' is executed. Wait for the message 'ready to connect' before clicking continue (this could last 1 minute at most). Once ready, the FAST.Farm simulation starts and connects to MATLAB. A powershell screen should appear showing the progress of the simulation. 

The 'Test3turbines' folder contains the FAST.Farm input file (.fstf file) and the OpenFAST input files (.fst file and servodyn, elastodyn etc). This files can be modified accordingly. 
