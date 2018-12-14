%% User-controlled parameters
tempo = 90;

%% System parameters
bufferSize = 256;
samplerate = 44100;

%% Setup timer, audiorecorder and audioplayer
% Audioplayer setup
[tickAudio, fs] = audioread('tick.wav');
player = audioplayer(tickAudio, fs);

% Timer setup
timeInterval = 60 / tempo;

mTimer = timer;
mTimer.Period = timeInterval;
mTimer.TimerFcn = @metronomeTick;
mTimer.ExecutionMode = 'fixedRate';
mTimer.TasksToExecute = 10;
mTimer.UserData = player;

% Audiorecorder setup
deviceReader = audioDeviceReader(samplerate, bufferSize);
setup(deviceReader);
fileWriter = dsp.AudioFileWriter('test.wav', 'FileFormat', 'WAV');

%% Run the system 
disp('Running...')
start(mTimer);

% while strcmp(mTimer.Running, 'on')
%     audioFromDevice = deviceReader();
%     fileWriter(audioFromDevice);
% end

disp('Done');

release(deviceReader);
release(fileWriter);

%% Functions
function metronomeTick(mTimer, ~)
    play(mTimer.UserData)
end
