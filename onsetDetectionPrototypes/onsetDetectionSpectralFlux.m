% Note onset detection using spectral flux

[audioIn, fs] = audioread('testAudio/pianoScale.wav');

fftSize = 2048;
hopSize = 256;

cursor = 1;
specFlux = zeros(length(audioIn), 1);
previousFrameFft = zeros(fftSize, 1);

while cursor + fftSize < length(audioIn)
    frameFFT = fft(audioIn(cursor:cursor + fftSize - 1) .* hann(fftSize));
    fftDifference = abs(frameFFT(1:fftSize / 2 - 1)) - abs(previousFrameFft(1:fftSize / 2 - 1));

    % specFlux(cursor:cursor + hopSize - 1) = sqrt(sum(fftDifference.^2)) / (fftSize / 2);
    specFlux(cursor:cursor + hopSize -1) = sum(fftDifference);  % Keeping the sign of the difference helps differentiate between note on and note off
    previousFrameFft = frameFFT;
    cursor = cursor + hopSize;
end

[peakVals, peakLocs] = findpeaks(specFlux, 'MinPeakProminence', 0.005, 'MinPeakDistance', 1000);

subplot(2, 1, 1)
plot(audioIn)
subplot(2, 1, 2)
plot(specFlux)
title('Spectral Flux - Single sine tone')
hold
plot(peakLocs, peakVals, 'x')

