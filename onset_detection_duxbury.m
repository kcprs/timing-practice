% Implementing onset detection method from:
% Duxbury, C., Bello, J.P., Davies, M. and Sandler, M. Complex domain Onset Detection for Musical Signals

clear;
close all;

[audio_in, fs] = audioread("Piano_scale.wav");
fft_size = 1024;
hop_size = 8;

novelty_map = zeros(length(audio_in), 1);
cursor = 1 + 2 * fft_size;
w = waitbar(0, "Finding Note Onsets...");

while cursor + fft_size < length(audio_in)
    waitbar(cursor / length(audio_in), w);
    preprev_fft = fft(audio_in(cursor - 2 * fft_size:cursor - fft_size - 1));
    prev_fft = fft(audio_in(cursor - fft_size:cursor - 1));
    current_fft = fft(audio_in(cursor:cursor + fft_size - 1));

    novelty_map(cursor:cursor + hop_size) = novelty_func(current_fft, prev_fft, preprev_fft);

    cursor = cursor + hop_size;
end

threshold = dynamic_threshold(novelty_map, 1, 16384, hop_size);

close(w)

subplot(2, 1, 1)
plot(audio_in)
subplot(2, 1, 2)
plot(novelty_map)
title("STFT Magnitude & Phase Tracking - Piano Scale")
hold
plot(threshold)

function output = novelty_func(current_fft, previous_fft, preprevious_fft)
    target_mag = arrayfun(@abs, previous_fft);
    current_mag = arrayfun(@abs, current_fft);
    current_arg = arrayfun(@angle, current_fft);
    previous_arg = arrayfun(@angle, previous_fft);
    preprevious_arg = arrayfun(@angle, preprevious_fft);
    phase_deviation = current_arg - 2 * previous_arg + preprevious_arg;

    output = sum(sqrt(target_mag.^2 + current_mag.^2 - 2 * target_mag .* current_mag .* cos(phase_deviation)));
end

function output = dynamic_threshold(novelty, scaling_factor, frame_size, hop_size)
    half_frame = ceil(frame_size);
    novelty = [zeros(half_frame, 1); novelty; zeros(half_frame, 1)];
    cursor = 1 + half_frame;
    output = zeros(length(novelty), 1);

    while cursor + half_frame < length(novelty)
        frame = novelty(cursor - half_frame:cursor + half_frame);
        output(cursor:cursor + hop_size) = scaling_factor * median(frame);
        cursor = cursor + hop_size;
    end

    output = output(half_frame:length(output) - half_frame);
end
