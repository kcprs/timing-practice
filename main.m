close all;
clear;

%% User settings
tempo = 180;
duration = 10;

%% Technical settings
fs = 41000;
frameLength = 256;

%% Setup system
deviceReader = audioDeviceReader(fs, frameLength);
setup(deviceReader);
% lag = measure_audio_lag(deviceReader);
lag = 9000;

%% Setup session
metronome = generate_metronome(tempo, duration, fs);
player = audioplayer(metronome, fs);

%% Record
play(player);
audio_in = record_audio_in(duration, deviceReader);

% Process
audio_in = highpass(audio_in, 50, fs);
audio_in_aligned = audio_in(lag:end);

min_tick_dist = get_tick_distance(tempo, fs) / 2;
onsets = detect_onsets(audio_in_aligned, min_tick_dist);

subplot(2, 1, 1);
plot(metronome);
subplot(2, 1, 2);
plot(audio_in_aligned);
hold
plot(onsets, audio_in_aligned(onsets), 'x');
