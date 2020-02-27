BCILABpath     = 'Z:\data\matlab\BCILAB'; % path to BCILAB toolbox
psychoToolbox  = false;  % Toggle to false for testing without psych toolbox
adrBoard       = false;  % Toggle to true if using ADR101 board to send events to the
                         % EEG amplifier
TCPIP          = false;  % send feedback to client through TCP/IP socket
TCPport        = 9789;   
TCPformat      = 'binstatechange';   

streamFile = ''; % if not empty stream a file instead of using LSL
lsltype = ''; % use empty if you cannot connect to your system
lslname = 'CGX Dev Kit DK-0090'; % this is the name of the stream that shows in Lab Recorder
% lslname = 'WS-default'; % this is the name of the stream that shows in Lab Recorder
              % if empty, it will only use the type above
              % USE lsl_resolve_byprop(lib, 'type', lsltype, 'name', lslname) 
              % to connect to the stream. If you cannot connect
              % nfblab won't be able to connect either.
fileNameAsr = sprintf('asr_filter_%s.mat',  datestr(now, 'yyyy-mm-dd_HH-MM'));
fileNameOut = sprintf('data_nfblab_%s.mat',  datestr(now, 'yyyy-mm-dd_HH-MM'));
defaultNameAsr = fileNameAsr;

% sessions parameters
baselineSessionDuration = 60; % duration of baseline in second (the baseline is used
                              % to train the artifact removal ASR function)
sessionDuration = 60*2; % regular (trial) sessions - here 5 minutes

% data acquisition parameters
chans    = [1:8]; % indices of data channels
averefflag = false; % compute average reference before chanmask below
chanmask = zeros(1,4); chanmask(1) = 1; % spatial filter for feedback

% data processing parameters for Wearable Sensing AMP
%srateHardware = 304; % sampling rate of the hardware
%srate         = 304; % sampling rate for processing data (must divide srateHardware)
%windowSize    = 304; % length of window size for FFT (if equal to srate then 1 second)
%nfft          = 304; % length of FFT - allows FFT padding if necessary
%windowInc     = 76;  % window increment - in this case update every 1/4 second

% data processing parameters for CGX AMP
srateHardware = 500; % sampling rate of the hardware
srate         = 500; % sampling rate for processing data (must divide srateHardware)
windowSize    = 500; % length of window size for FFT (if equal to srate then 1 second)
nfft          = 500; % length of FFT - allows FFT padding if necessary
windowInc     = 125;  % window increment - in this case update every 1/4 second
% feedback parameters
freqrange      = [3.5 6.5]; % Frequency range of interest. This program does
                            % not allow inhibition at other frequencies
                            % although it could be modified to do so

feedbackMode = 'threshold';
% parameters for threshold change. The threshold mode simply involve
% activity going above or below a threshold and parameter for how this
% threshold evolve. The output is binary
threshold = 10; % intial value for threshold
thresholdMem = 0.75; % i.e. new_threshold = current_value * 0.25 + old_threshold * 0.75 
thresholdMode = 'go'; % can be 'go' (1 when above threshold, 0 otherwise) 
                       % or 'stop' (1 when below threshold, 0 otherwise) 
                            
% mode = 'dynrange';
% parameters for dynamic range change. In this mode, the output is continuous
% between 0 and 1 (position in the range). Parameters control how the range
% change
maxChange      = 0.05;      % Cap for change in feedback between processed 
                            % windows every 1/4 sec. feedback is between 0 and 1
                            % so this is 5% here
dynRange       = [16 29];   % Initial power range in dB
dynRangeInc    = 0.0333;    % Increase in dynamical range in percent if the
                            % power value is outside the range (every 1/4 sec)
dynRangeDec    = 0.01;      % Decrease in dynamical range in percent if the
                            % power value is within the range (every 1/4 sec)
        
% meta-parameters not used by nfblab_process
ntrials = 8; % number of trials per day
ndays   = 8; % number of days of training
       
%custom_config = 'none';
%custom_config = '8-channel-cgs';
custom_config = '24-channel-ws';
%custom_config = '24-channel-cg';
%custom_config = '32-channel-cg';
%custom_config = '64-channel';
%custom_config = 'offline-file';

switch custom_config
    case 'none'
    case '24-channel-ws'
        chans    = [1:24]; % indices of data channels
        chanmask = zeros(1,24); 
        chanmask(12) = 1; % C4 spatial filter for feedback
        chanmask(19) = -1; % Pz
        TCPIP    = true;
        lslname = 'WS-default'; % this is the name of the stream that shows in Lab Recorder
        disp('CAREFUL: using alternate configuration in nfblab_option');
    case '8-channel-cgs'
        chans    = [1:8]; % indices of data channels
        chanmask = zeros(1,8); 
        chanmask(7) = 1; % A1
        TCPIP    = true;
        lslname = 'CGX Dev Kit DK-0090'; % this is the name of the stream that shows in Lab Recorder
        disp('CAREFUL: using alternate configuration in nfblab_option');
    case 'offline-file'
        p = fileparts(which('nfblab_options.m'));
        streamFile = fullfile(p, 'eeglab_data.set'); % if not empty stream a file instead of using LSL
        chans    = [1:32]; % indices of data channels
        chanmask = zeros(1,32); chanmask(1) = 1; % spatial filter for feedback
        TCPIP       = false;
        TCPformat = 'json';
        disp('CAREFUL: using alternate configuration in nfblab_option');
    otherwise 
        error('Unknown configuration');
end

if ~exist(BCILABpath, 'dir')
    p = fileparts(which('nbflab_options'));
    BCILABpath = fullfile(p, '..', 'BCILAB');
    if ~exist(BCILABpath, 'dir')
        BCILABpath = fullfile(p, '..', '..', 'BCILAB');
        if ~exist(BCILABpath, 'dir')
           error('Cannot find BCILAB - set path manually in file nfblab_options.m');
        end
    end
end

addpath(fullfile(BCILABpath, 'dependencies', 'liblsl-Matlab'));
addpath(fullfile(BCILABpath, 'dependencies', 'liblsl-Matlab', 'bin'));
addpath(fullfile(BCILABpath, 'dependencies', 'liblsl-Matlab', 'mex', 'build-Christian-PC'));
addpath(fullfile(BCILABpath, 'dependencies', 'asr-matlab-2012-09-12')); % not required if copied the files above
