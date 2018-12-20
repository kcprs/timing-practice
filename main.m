clear;
close all;

%% User settings
tempo = 180;
duration = 10;
subtractAverageLag = true;

%% Technical settings
fs = 41000;
frameLength = 256;

%% Setup system
deviceReader = audioDeviceReader(fs, frameLength);
setup(deviceReader);
% averageLag = measureAudioLag(deviceReader);
% averageLag = 7200;

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

if subtractAverageLag
    averageLag = round(timingInfo.average);
    tickArrayAligned = circshift(tickArray, averageLag);
    tickLocs = getTickLocs(tickArrayAligned);
else
    tickLocs = getTickLocs(tickArray);
end

%% Plot
time = linspace(0, length(audioIn)/fs, length(audioIn));
plot(time, audioIn);
hold;
onsetTimes = onsetLocs / fs;
plot(onsetTimes, zeros(length(onsetTimes)), 'x', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'r');
tickTimes = tickLocs / fs;
plot(tickTimes, zeros(length(tickTimes)), '+', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'g');
hold;
