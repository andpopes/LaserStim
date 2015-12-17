function NI(operation,varargin)

% This function controls the analog and digital output of a National
% Instruments (NI) PCI board. The two digital channels (lines 0 and 1) are
% connected to the TTL trigger input of a 375nm and 532nm lasers,
% respectively. The analog output (line 0) is coupled to a
% voltage-dependent intensity switch on the 375nm laser (values 0 - 5 V,
% max power at 5V). The 532nm laser intensity was adjusted with a manual
% potentiometer.
%
% Example:
%       NI('initilize');        - starts the NI board
%       NI('laser power', 3);   - sets an intermediate UV power level
%       NI('laser375', 1);      - activates the UV laser for 1 sec
%       NI('destroy');          - terminates experiment and frees NI board

global DIO AO AO_chan;
global TIME0 EVENTS ;
global NI_ON;

switch lower(operation)
    case 'initialize'
        warning off all
        if exist('DIO','var'), delete(DIO); end
        if exist('AO','var'), delete(AO); end
        
        %initialize digital channels
        DIO=digitalio('nidaq','Dev1');
        names={'375','532'};
        addline(DIO,0:1,{'out', 'out'},names);
        putvalue(DIO.Line(1),0);
        putvalue(DIO.Line(2),0);

        %analog channel out for laser power
        AO=analogoutput('nidaq','Dev1');
        AO_chan=addchannel(AO, 0, {'laser_power'});
        set(AO,'SampleRate',10); % 10 hz
        AO_chan(1).OutputRange = [0 5];
        NI ('resetall');

    case 'destroy'
        if ~isempty(DIO)
            putvalue(DIO.Line([1, 2]),0);
            delete(DIO);
        end
        delete (AO);
        AO=[];
        AO_chan=[];
        EVENTS=[];
        clear DIO AO;
        NI_ON=0;
        
    case 'resetall'
        TIME0=clock;
        EVENTS=[];
        EVENTS{10}=[];
        
    case 'resettime'
        TIME0=clock;
        
    case 'event'
        % records the time of the corresponding event
        es=etime(clock,TIME0);
        if varargin{1}>length(EVENTS)
            EVENTS{varargin{1}}=[];
        end
        EVENTS{varargin{1}}(end+1)=es;
        
    case 'laser power'
        if ~strcmp(AO.Running,'Off')
            return;
        end
        dat=varargin{1};
        putdata(AO,dat);
        start(AO);
    
    case 'laser375'
        dur=varargin{1};
        putvalue(DIO.Line(1),1);
        NI ('event', 1);
        pause (dur);
        putvalue(DIO.Line(1),0);
        
    case 'laser532'
        dur=varargin{1};
        putvalue(DIO.Line(2),1);
        NI ('event', 2);
        pause (dur);
        putvalue(DIO.Line(2),0);
        
    otherwise
        warning('unfamiliar operation');
end
return
