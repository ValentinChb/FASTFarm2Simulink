# FASTFarm and MATLAB/Simulink interface

Run 'RunTest_MATLAB.bat' or 'RunTest_Simulink.bat' in order to run a test with the interface. A turbine-level and farm-level controller can be constructed in the files 'SC_MATLAB' or 'SC_Simulink' in the 'SC_MPIServer' folder. 

The following programs need to be installed beforehand:
- MinGW (add \bin to system variables)
- Microsoft MPI

Add the following libraries to the path: (mkl libraries can be added by downloading Miniconda)
- libifportMD.dll
- libifcoremd.dll
- libiomp5md.dll
- libmmd.dll
- mkl_sequential.dll (anaconda library in \pachages\bin)
- mkl_core.dll (anaconda library in \pachages\bin)
- svml_dispmd.dll
