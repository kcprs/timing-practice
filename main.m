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
lag = 9500;

%% Setup session
metronome = generate_metronome(tempo, duration, fs);
player = audioplayer(metronome, fs);

%% Record
play(player);
audio_in = record_audio_in(duration, deviceReader);

% Process
audio_in_aligned = audio_in(lag:end);

subplot(2, 1, 1);
plot(metronome);
subplot(2, 1, 2);
plot(audio_in_aligned);
