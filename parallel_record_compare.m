tempo = 180;
duration = 10;

frameLength = 256;

[metronome, fs] = generate_metronome(tempo, duration);
player = audioplayer(metronome, fs);
play(player);
audio_in = record_audio_in(duration, frameLength, fs);
