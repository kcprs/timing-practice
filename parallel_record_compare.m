tempo = 180;
duration = 10;

frameLength = 256;

[metronome, fs] = generate_metronome(tempo, duration);
player = audioplayer(metronome, fs);
deviceReader = audioDeviceReader(fs, frameLength);
setup(deviceReader);
play(player);
audio_in = record_audio_in(duration, deviceReader);

subplot(2, 1, 1);
plot(metronome)
subplot(2, 1, 2);
plot(audio_in)
