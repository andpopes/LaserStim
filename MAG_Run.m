function MAG_Run (varargin)

% Main function used for controlling the two-laser stimulation protocol as
% described in Levitz, et al., Frontiers in Molecular Neuroscience. It
% requires a National Instruments DAQ-PCI board with corresponding drivers,
% and the Data Acquisition Toolbox in Matlab (32-bit). The board is
% controled through the accompanying NI.m function.
%
%   MAG_Run takes the following (optional) parameters as strings, followed
%   by the desired value ('Param', 'value'):
%       'File'  - name of the file for saving the experimental protocol, as
%                   well as the times for laser stimulation.
%       'Len375'- duration of the UV laser pulse, specified in seconds
%       'Len532'- duration of the green laser pulse, specified in seconds
%       'Pause375'  - pause between the end of the UV pulse, and the
%                       beginning of the next event
%       'Pause532'  - pause between the end of the green pulse, and the
%                       beginning of the next event
%       'Power375'  - power of the UV laser, as a value between 0 and 5
%       'Sequence'  - sequence of laser stimulations, as the pattern to be
%                       repeated. Value should be a list containing 1 for
%                       UV laser, and 2 for green laser activation. The
%                       simplest patterns are [1, 2] or [2, 1].
%       'N'         - the number of times that the sequence is repeated.
%
%  Examples:
%   * Run an experiment with default values, and save the data in a Matlab
%     file, in the current directory.
%
%           MAG_Run('File', 'M05_01_Jan_2016.mat');
%
%   * Same, but lower the power of the UV laser stimulation.
%
%           MAG_Run('File', 'M05_01_Jan_2016.mat', 'Power375', 3.5);
%
%   * Test a different stimulation pattern with brief, repetitive UV
%       pulses. Please note that very fast sequences (<10 ms) may not be
%       accurate, due to the extra times required for running the code. A
%       different NI control system needs to be implemented in that case.
%       
%           MAG_Run('Len375', 0.05, 'Pause375', 0.05,...
%               'Sequence', [2 1 1 1 1 1 2], 'N', 20);
%
%   * Quick alternating UV-Green stimulation pattern.
%
%           MAG_Run('Len375', 0.05, 'Pause375', 0.05,...
%               'Len532', 0.05, 'Pause532', 0.05,'Sequence',...
%               [2 1 2 1 2 1 2 1 2 1 2], 'N', 20, 'PauseS', 10);


%% Initialize parameters and NI board
% default values:
N = 50;
Len375 = 1;
Len532 = 2;
Pause375 = 2;
Pause532 = 10;
PauseS = 1;
Power375 = 5;
Sequence = [2 1]; % 1 for 375, 2 for 532 stimulation
fsave = [];

% replace defaults with parameters provided:
if ~isempty(varargin)
    for i = 1:2:length(varargin)-1
        op = varargin{i};
        vl = varargin{i+1};
        switch lower(op)
            case 'n'
                N = vl;
            case 'len375'
                Len375 = vl;
            case 'len532'
                Len532 = vl;
            case 'pause375'
                Pause375 = vl;
            case 'pause532'
                Pause532 = vl;
            case 'power375'
                Power375 = vl;
            case 'sequence'
                Sequence = vl;
            case 'file'
                fsave = vl;
            case 'pauses'
                PauseS = vl;
        end
    end
end

dur = (Len375 + Pause375) * sum(Sequence == 1) + ...
    (Len532  + Pause532) * sum(Sequence == 2) + PauseS;
Sequence = [repmat([Sequence, 0], 1, N), 2];

global EVENTS
% initialize the NI board
NI('initialize');

% confirm parameters of the run
an = questdlg([num2str(N) ' events of ' num2str(dur) ' sec. duration will run with alternating 375nm and 532nm light for ' num2str(Len375) ' and ' num2str(Len532) ' sec each. Press OK to run.'], 'Ready to run ...','OK','Cancel','Cancel');
if strcmp(an,'Cancel')
    NI('destroy');
    return;
end

% save parameters
if ~isempty(fsave)
    save(fsave, 'N', 'Len375', 'Len532', 'Pause375', 'Pause532',...
        'Power375', 'Sequence');
end


%% Experimental phase
h=waitbar(0,'Progress...');
NI('laser power',Power375);
NI('resettime');

L = length(Sequence);
for i=1:L
    if Sequence(i)==2
        waitbar(i/L,h,['Green light on (' num2str(i) ')']);
        NI('laser532',Len532);
        waitbar(i/L,h,['Green light off (' num2str(i) ')']);
        per = Pause532;
    elseif Sequence(i)==1
        waitbar(i/L,h,['UV light on (' num2str(i) ')']);
        NI('laser375',Len375);
        waitbar(i/L,h,['UV light off (' num2str(i) ')']);
        per = Pause375;
    else
        pause(PauseS);
    end
    pause (per);
end

%% Explicit save of stimulation times, and clean up

if ~isempty(fsave)
    TIMES_UV = EVENTS{1};
    TIMES_GREEN = EVENTS{2};
    save(fsave,'TIMES*','-append');
end
close (h);
NI('destroy');
