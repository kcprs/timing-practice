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
% lag = measure_audio_lag(deviceReader);
% lag = 7200;

%% Setup session
[metronome, tick_array] = generate_metronome(tempo, duration, fs);
player = audioplayer(metronome, fs);

%% Record
play(player);
audio_in = record_audio_in(duration, deviceReader);

%% Process
audio_in = highpass(audio_in, 50, fs);
min_tick_dist = get_tick_distance(tempo, fs) / 2;
onset_locs = detect_onsets(audio_in, min_tick_dist);
tick_locs = get_tick_locs(tick_array);
timing_info = get_timing_info(onset_locs, tick_locs);
lag = round(timing_info.average);
metronome = circshift(metronome, lag);
metronome = metronome(1:length(audio_in));
tick_array = circshift(tick_array, lag);
tick_locs = get_tick_locs(tick_array);

%% Plot
subplot(2, 1, 1);
plot(metronome);
subplot(2, 1, 2);
plot(audio_in);
hold;
plot(onset_locs, zeros(length(onset_locs)), 'x', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'r');
plot(tick_locs, zeros(length(tick_locs)), '+', 'LineWidth', 2, 'MarkerSize', 10, 'Color', 'g');
hold;
