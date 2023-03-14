# FASTFarm2Simulink

Run 'RunTest_MATLAB.bat' in order to run the interface. A turbine-level and farm-level controller can be constructed in the file 'SC_MATLAB' in the 'SC_MPIServer' folder. 

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
