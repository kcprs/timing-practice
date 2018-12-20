% Implementing onset detection method from:
% Duxbury, C., Bello, J.P., Davies, M. and Sandler, M. Complex domain Onset Detection for Musical Signals

clear;
close all;

[audioIn, fs] = audioread('testAudio/pianoScale.wav');
fftSize = 1024;
hopSize = 8;

noveltyMap = zeros(length(audioIn), 1);
cursor = 1 + 2 * fftSize;
w = waitbar(0, 'Finding Note Onsets...');

while cursor + fftSize < length(audioIn)
    waitbar(cursor / length(audioIn), w);
    preprevFFT = fft(audioIn(cursor - 2 * fftSize:cursor - fftSize - 1));
    prevFFT = fft(audioIn(cursor - fftSize:cursor - 1));
    currentFFT = fft(audioIn(cursor:cursor + fftSize - 1));

    noveltyMap(cursor:cursor + hopSize) = noveltyFunc(currentFFT, prevFFT, preprevFFT);

    cursor = cursor + hopSize;
end

threshold = dynamicThreshold(noveltyMap, 1, 16384, hopSize);

close(w)

subplot(2, 1, 1)
plot(audioIn)
subplot(2, 1, 2)
plot(noveltyMap)
title('STFT Magnitude & Phase Tracking - Piano Scale')
hold
plot(threshold)

function output = noveltyFunc(currentFFT, previousFFT, prepreviousFFT)
    targetMag = arrayfun(@abs, previousFFT);
    currentMag = arrayfun(@abs, currentFFT);
    currentArg = arrayfun(@angle, currentFFT);
    previousArg = arrayfun(@angle, previousFFT);
    prepreviousArg = arrayfun(@angle, prepreviousFFT);
    phaseDeviation = currentArg - 2 * previousArg + prepreviousArg;

    output = sum(sqrt(targetMag.^2 + currentMag.^2 - 2 * targetMag .* currentMag .* cos(phaseDeviation)));
end

function output = dynamicThreshold(novelty, scalingFactor, frameSize, hopSize)
    halfFrame = ceil(frameSize);
    novelty = [zeros(halfFrame, 1); novelty; zeros(halfFrame, 1)];
    cursor = 1 + halfFrame;
    output = zeros(length(novelty), 1);

    while cursor + halfFrame < length(novelty)
        frame = novelty(cursor - halfFrame:cursor + halfFrame);
        output(cursor:cursor + hopSize) = scalingFactor * median(frame);
        cursor = cursor + hopSize;
    end

    output = output(halfFrame:length(output) - halfFrame);
end
