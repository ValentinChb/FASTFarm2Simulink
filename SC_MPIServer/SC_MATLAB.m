% Written by Coen-Jan Smits on 12-05-2023 (GPL 3.0 licence)

%% SC_MPIServer matlab file

function SC_MATLAB(instance) %same name as file

instance=0;
if instance==0
  MPI_sharedfile="../MPI_shared.dat";
else
  mkdir("../MPI_shared_instances");
  MPI_sharedfile=sprintf("../MPI_shared_instances/MPI_shared_%d.dat",instance);
end
MPI_sharedfile = convertStringsToChars(MPI_sharedfile);

% MPIServer_Test();

%Initialize
disp("Ready to connect");
[nT,nc]=MPIServer_Init(MPI_sharedfile);
disp("Connected");
avrSWAP=zeros(nT,nc, 'single');
disp(['Size avrSWAP: ', num2str(nT), 'x', num2str(nc)]);

%Run and terminate
while true % Farm-level loop
    incomplete=true;
    new=true;

    while incomplete % Turbine-level loop, wait for all turbines to complete farm-level timestep. .
        [iT,avrSWAP,incomplete]=MPIServer_AnyReceive(avrSWAP);   % Receive message from any turbine iT

        if new
            %# < update farm-level control here >
            new=false;
        end

        %# < update turbine-level control here >
        
        MPIServer_OneSend(iT,avrSWAP); % Send back message to turbine iT

    end

    if (all(avrSWAP(:,1)<0))
        break
    end
end

disp("Stopping server..");
MPIServer_Stop();
disp("Server stopped.");

end


%% Plotting of results
% Download Matlab toolbox for OpenFAST: https://github.com/OpenFAST/matlab-toolbox and add to path

% Folder with output files of OpenFAST
% T1out = '..\Test3turbines\FAST.Farm_N3.T1.out';
% T2out = '..\Test3turbines\FAST.Farm_N3.T2.out';
% T3out = '..\Test3turbines\FAST.Farm_N3.T3.out';

% PlotFASToutput({T1out, T2out, T3out},{'Turbine 1', 'Turbine 2', 'Turbine 3'},[],{'GenPwr','YawBrTAxp'});
% PlotFASToutput({T1out, T2out, T3out},{'Turbine 1', 'Turbine 2', 'Turbine 3'});
