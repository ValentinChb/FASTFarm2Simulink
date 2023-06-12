% Written by Coen-Jan Smits on 12-05-2023 (GPL 3.0 licence)

%% SC_MPIServer matlab file

function SC_Simulink(instance) %same name as file

instance=0;
if instance==0
  MPI_sharedfile="../MPI_shared.dat";
else
  mkdir("../MPI_shared_instances");
  MPI_sharedfile=sprintf("../MPI_shared_instances/MPI_shared_%d.dat",instance);
end
MPI_sharedfile = convertStringsToChars(MPI_sharedfile);

%Initialize
disp("Ready to connect");
[nT,nc]=MPIServer_Init(MPI_sharedfile);
disp("Connected");
disp(['Size avrSWAP: ', num2str(nT), 'x', num2str(nc)]);
avrSWAP=zeros(nT,nc, 'single');

%Import runtime form fstf file (check!)
FastFarmInfoFile = "../Test3turbines/FAST.Farm_N3.fstf";
FastFarmInfo = readlines(FastFarmInfoFile);
time = split(FastFarmInfo(6)," ");
Tmax = str2num(time(1)); 

%Import timestep form fst file (check!)
OpenFASTInfoFile = "../Test3turbines/OpenFAST/T1/DTU_10MW_RWT.fst";
OpenFASTInfo = readlines(OpenFASTInfoFile);
step = split(OpenFASTInfo(7)," ");
Tstep = str2num(step(1)); 

%Start simulink model, this model contains the loop with the controller and the send and receive functions
sim('Mex_Simulink_Blocks','StopTime',num2str(Tmax),'FixedStep',num2str(Tstep));

disp("Server stopping...");
MPIServer_Stop();
disp("Server terminated");

end % function


%% Plotting of results 
% Download Matlab toolbox for OpenFAST: https://github.com/OpenFAST/matlab-toolbox and add to path

% Folder with output files of OpenFAST
% T1out = '..\Test3turbines\FAST.Farm_N3.T1.out';
% T2out = '..\Test3turbines\FAST.Farm_N3.T2.out';
% T3out = '..\Test3turbines\FAST.Farm_N3.T3.out';

% PlotFASToutput({T1out, T2out, T3out},{'Turbine 1', 'Turbine 2', 'Turbine 3'},[],{'GenPwr','YawBrTAxp'});
% PlotFASToutput({T1out, T2out, T3out},{'Turbine 1', 'Turbine 2', 'Turbine 3'});
