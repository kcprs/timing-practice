% Implementing onset detection method from:
% Duxbury, C., Bello, J.P., Davies, M. and Sandler, M. Complex domain Onset Detection for Musical Signals

[audio_in, fs] = audioread("Piano_scale.wav");
fft_size = 4096;
hop_size = 32;

onset_map = zeros(length(audio_in), 1);
cursor = 1 + 2 * fft_size;
w = waitbar(0, "Finding Note Onsets...");

while cursor + fft_size < length(audio_in)
    waitbar(cursor/length(audio_in), w);
    preprev_fft = fft(audio_in(cursor - 2 * fft_size:cursor - fft_size));
    prev_fft = fft(audio_in(cursor - fft_size:cursor));
    current_fft = fft(audio_in(cursor:cursor + fft_size));

    onset_map(cursor:cursor+hop_size) = stationarity(current_fft, prev_fft, preprev_fft);

    cursor = cursor + hop_size;
end

close(w)
plot(onset_map)

function output = stationarity(current_fft, previous_fft, preprevious_fft)
    target_mag = arrayfun(@abs, previous_fft);
    previous_arg = arrayfun(@angle, previous_fft);
    preprevious_arg = arrayfun(@angle, preprevious_fft);
    target_arg = 2 * previous_arg - preprevious_arg;
    target = target_mag .* exp(1j * target_arg);

    real_diff = (arrayfun(@real, target) - arrayfun(@real, current_fft)).^2;
    imag_diff = (arrayfun(@imag, target) - arrayfun(@imag, current_fft)).^2;
    output = sum(arrayfun(@sqrt, real_diff + imag_diff));
end
