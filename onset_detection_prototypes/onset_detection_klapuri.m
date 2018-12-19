% Implementing onset detection algorithm as described in:
% A. Klapuri, "Sound Onset Detection by Applying Psychoacoustic Knowledge,"

clear
close all

[audio_in, fs] = audioread('test_audio/Piano_scale.wav');

bands = zeros(length(audio_in), 6);

bands(:, 1) = bandpass(audio_in, [20, 400], fs);
bands(:, 2) = bandpass(audio_in, [400, 800], fs);
bands(:, 3) = bandpass(audio_in, [800, 1600], fs);
bands(:, 4) = bandpass(audio_in, [1600, 3200], fs);
bands(:, 5) = bandpass(audio_in, [3200, 6400], fs);
bands(:, 6) = bandpass(audio_in, [6400, 12800], fs);

[upper_envs, lower_envs] = envelope(bands, 4000, 'rms');
amp_envs = upper_envs - lower_envs;
diff_amp_envs = [diff(amp_envs); zeros(1, 6)];
diff_amp_envs = arrayfun(@threshold, diff_amp_envs);
diff_amp_env = sum(diff_amp_envs, 2);

rel_diff_amp_envs = diff_amp_envs ./ amp_envs;
rel_diff_amp_env = sum(rel_diff_amp_envs, 2);

[peak, peak_loc] = findpeaks(rel_diff_amp_env, 'MinPeakDistance', 10000);

subplot(2, 1, 1)
plot(audio_in)
subplot(2, 1, 2)

plot(rel_diff_amp_env)
title("Multiband Differential of the Amplitude - Piano Scale")
hold
plot(peak_loc, peak, 'x')

function output = threshold(number)
    if number > 0.00001
        output = number;
    else
        output = 0;
    end
end