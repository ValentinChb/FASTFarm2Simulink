:: Written by Valentin Chabaud on 12-05-2022 (GPL 3.0 licence)

@echo off
set "DependencyDIR=..\MPI_libs"
gfortran -c -fdefault-real-8 -ffree-line-length-0 %~dp0\MPIServerSubs.f90 -I%DependencyDIR%
move /Y MPIServerSubs.* %~dp0
gfortran  -shared -static -fpic -o %~dp0\SC_MPIServerSubs.dll -Wl,--out-implib,%~dp0libSC_MPIServerSubs.a %~dp0MPIServerSubs.o -L%DependencyDIR% -lmsmpi
