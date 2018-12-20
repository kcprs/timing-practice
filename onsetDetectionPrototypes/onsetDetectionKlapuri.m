% Implementing onset detection algorithm as described in:
% A. Klapuri, 'Sound Onset Detection by Applying Psychoacoustic Knowledge,'

clear
close all

[audioIn, fs] = audioread('testAudio/pianoScale.wav');

bands = zeros(length(audioIn), 6);

bands(:, 1) = bandpass(audioIn, [20, 400], fs);
bands(:, 2) = bandpass(audioIn, [400, 800], fs);
bands(:, 3) = bandpass(audioIn, [800, 1600], fs);
bands(:, 4) = bandpass(audioIn, [1600, 3200], fs);
bands(:, 5) = bandpass(audioIn, [3200, 6400], fs);
bands(:, 6) = bandpass(audioIn, [6400, 12800], fs);

[upperEnvs, lowerEnvs] = envelope(bands, 4000, 'rms');
ampEnvs = upperEnvs - lowerEnvs;
diffAmpEnvs = [diff(ampEnvs); zeros(1, 6)];
diffAmpEnvs = arrayfun(@threshold, diffAmpEnvs);
diffAmpEnv = sum(diffAmpEnvs, 2);

relDiffAmpEnvs = diffAmpEnvs ./ ampEnvs;
relDiffAmpEnv = sum(relDiffAmpEnvs, 2);

[peakVals, peakLocs] = findpeaks(relDiffAmpEnv, 'MinPeakDistance', 10000);

subplot(2, 1, 1)
plot(audioIn)
subplot(2, 1, 2)

plot(relDiffAmpEnv)
title('Multiband Differential of the Amplitude - Piano Scale')
hold
plot(peakLocs, peakVals, 'x')

function output = threshold(number)
    if number > 0.00001
        output = number;
    else
        output = 0;
    end
end