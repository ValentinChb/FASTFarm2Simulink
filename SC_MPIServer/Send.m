% Written by Coen-Jan Smits on 12-05-2023 (GPL 3.0 licence)

function Send(block)

% calls the setup function
setup(block);

%endfunction

% Create level 2 S-Function by typding 'edit: msfuntmpl_basic'

%% Function: setup ===================================================
%% Abstract:
%%   Set up the basic characteristics of the S-function block such as:
%%   - Input ports
%%   - Output ports
%%   - Dialog parameters
%%   - Options
%%
%%   Required         : Yes
%%   C MEX counterpart: mdlInitializeSizes

function setup(block)

% Register number of ports
block.NumInputPorts  = 1;
block.NumOutputPorts = 1;

% Setup port properties to be inherited or dynamic
block.SetPreCompInpPortInfoToDynamic;
block.SetPreCompOutPortInfoToDynamic;

% Override input port properties
block.InputPort(1).Dimensions  = [3 84];
block.InputPort(1).DatatypeID  = 1;  %'single' matrix
block.InputPort(1).Complexity  = 'Real';
block.InputPort(1).DirectFeedthrough = false;

% block.InputPort(2).Dimensions  = 1;
% block.InputPort(2).DatatypeID  = 6;  %int32
% block.InputPort(2).Complexity  = 'Real';
% block.InputPort(2).DirectFeedthrough = false;

% Override output port properties
block.OutputPort(1).Dimensions  = [3 84];
block.OutputPort(1).DatatypeID  = 1; %'single' matrix
block.OutputPort(1).Complexity  = 'Real';

% block.OutputPort(1).Dimensions  = 1;
% block.OutputPort(1).DatatypeID  = 0;
% block.OutputPort(1).Complexity  = 'Real';

% Register parameters
block.NumDialogPrms     = 0;

% Register sample times
%  [0 offset]            : Continuous sample time
%  [positive_num offset] : Discrete sample time
%
%  [-1, 0]               : Inherited sample time
%  [-2, 0]               : Variable sample time
block.SampleTimes = [-1 0];

% Specify the block simStateCompliance. The allowed values are:
%    'UnknownSimState', < The default setting; warn and assume DefaultSimState
%    'DefaultSimState', < Same sim state as a built-in block
%    'HasNoSimState',   < No sim state
%    'CustomSimState',  < Has GetSimState and SetSimState methods
%    'DisallowSimState' < Error out when saving or restoring the model sim state
block.SimStateCompliance = 'DefaultSimState';

%% -----------------------------------------------------------------
%% The MATLAB S-function uses an internal registry for all
%% block methods. You should register all relevant methods
%% (optional and required) as illustrated below. You may choose
%% any suitable name for the methods and implement these methods
%% as local functions within the same file. See comments
%% provided for each function for more information.
%% -----------------------------------------------------------------

%block.RegBlockMethod('PostPropagationSetup',    @DoPostPropSetup);
%block.RegBlockMethod('InitializeConditions', @InitializeConditions);
%block.RegBlockMethod('Start', @Start);
block.RegBlockMethod('Outputs', @Outputs);     % Required
%block.RegBlockMethod('Update', @Update);
%block.RegBlockMethod('Derivatives', @Derivatives);

%added:
block.RegBlockMethod('SetInputPortSamplingMode', @SetInpPortFrameData);

block.RegBlockMethod('Terminate', @Terminate); % Required

%end setup

%%
%% PostPropagationSetup:
%%   Functionality    : Setup work areas and state variables. Can
%%                      also register run-time methods here
%%   Required         : No
%%   C MEX counterpart: mdlSetWorkWidths
%%

%function DoPostPropSetup(block)
%block.NumDworks = 1;
  
%  block.Dwork(1).Name            = 'x1';
%  block.Dwork(1).Dimensions      = 1;
%  block.Dwork(1).DatatypeID      = 0;      % double
%  block.Dwork(1).Complexity      = 'Real'; % real
%  block.Dwork(1).UsedAsDiscState = true;


%%
%% InitializeConditions:
%%   Functionality    : Called at the start of simulation and if it is 
%%                      present in an enabled subsystem configured to reset 
%%                      states, it will be called when the enabled subsystem
%%                      restarts execution to reset the states.
%%   Required         : No
%%   C MEX counterpart: mdlInitializeConditions
%%

%function InitializeConditions(block)

%end InitializeConditions


%%
%% Start:
%%   Functionality    : Called once at start of model execution. If you
%%                      have states that should be initialized once, this 
%%                      is the place to do it.
%%   Required         : No
%%   C MEX counterpart: mdlStart
%%

%function Start(block)

%block.Dwork(1).Data = 0;

%end Start

%%
%% Outputs:
%%   Functionality    : Called to generate block outputs in
%%                      simulation step
%%   Required         : Yes
%%   C MEX counterpart: mdlOutputs
%%
function Outputs(block)

%iT = block.InputPort(1).Data;
avrSWAP = block.InputPort(1).Data;

for iT=1:3
    MPIServer_OneSend(iT,avrSWAP); 
end

block.OutputPort(1).Data = avrSWAP;

%block.OutputPort(1).Data = avrSWAP;
%end Outputs

%%
%% Update:
%%   Functionality    : Called to update discrete states
%%                      during simulation step
%%   Required         : No
%%   C MEX counterpart: mdlUpdate
%%

%function Update(block)

%block.Dwork(1).Data = block.InputPort(1).Data;

%end Update

%% Set the sampling of the input ports

function SetInpPortFrameData(block, idx, fd)

block.InputPort(idx).SamplingMode = fd;
for i = 1:block.NumOutputPorts
    block.OutputPort(i).SamplingMode = fd;
end

%end SetInpPortFrameData

%%
%% Derivatives:
%%   Functionality    : Called to update derivatives of
%%                      continuous states during simulation step
%%   Required         : No
%%   C MEX counterpart: mdlDerivatives
%%

%function Derivatives(block)

%end Derivatives

%%
%% Terminate:
%%   Functionality    : Called at the end of simulation for cleanup
%%   Required         : Yes
%%   C MEX counterpart: mdlTerminate
%%
function Terminate(block)

%end Terminate

