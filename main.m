clear;
close all;

%% User settings
tempo = 180;
duration = 5;

%% Technical settings
fs = 41000;
frameLength = 256;

%% Setup system
deviceReader = audioDeviceReader(fs, frameLength);
setup(deviceReader);
% lag = measureAudioLag(deviceReader);
% lag = 7200;

%% Setup session
[metronome, tickArray] = generateMetronome(tempo, duration, fs);
player = audioplayer(metronome, fs);

%% Record
play(player);
audioIn = recordAudioIn(duration, deviceReader);

%% Process
audioIn = highpass(audioIn, 50, fs);
minTickDist = getTickDistance(tempo, fs) / 2;
onsetLocs = detectOnsets(audioIn, minTickDist);
tickLocs = getTickLocs(tickArray);
timingInfo = getTimingInfo(onsetLocs, tickLocs);
lag = round(timingInfo.average);
metronome = circshift(metronome, lag);
metronome = metronome(1:length(audioIn));
tickArray = circshift(tickArray, lag);
tickLocs = getTickLocs(tickArray);

%% Plot
subplot(2, 1, 1);
plot(metronome);
subplot(2, 1, 2);
plot(audioIn);
hold;
plot(onsetLocs, zeros(length(onsetLocs)), 'x', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'r');
plot(tickLocs, zeros(length(tickLocs)), '+', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'g');
hold;
