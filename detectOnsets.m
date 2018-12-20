function onsetLocs = detectOnsets(audioIn, minPeakDist)
    fftSize = 2048;
    hopSize = 64;

    cursor = 1;
    novelty = zeros(length(audioIn), 1);
    previousFrameFFT = zeros(fftSize, 1);

    wb = waitbar(0, 'Detecting onsets...');
    while cursor + fftSize < length(audioIn)
        waitbar(cursor / length(audioIn) - 0.2, wb);
        frameFFT = fft(audioIn(cursor:cursor + fftSize - 1) .* hann(fftSize));
        fftDifference = abs(frameFFT(1:fftSize / 2 - 1)) - abs(previousFrameFFT(1:fftSize / 2 - 1));

        % novelty(cursor:cursor + hopSize - 1) = sqrt(sum(fftDifference.^2)) / (fftSize / 2);
        novelty(cursor:cursor + hopSize - 1) = sum(fftDifference); % Keeping the sign of the difference helps differentiate between note on and note off
        previousFrameFFT = frameFFT;
        cursor = cursor + hopSize;
    end

    waitbar(0.9, wb);
    fadeIn = linspace(0, 1, minPeakDist)';
    novelty(1:minPeakDist) = novelty(1:minPeakDist) .* fadeIn;
    maxVal = max(novelty);
    novelty = novelty / maxVal;
    [~, onsetLocs] = findpeaks(novelty, 'MinPeakProminence', 0.5, 'MinPeakDistance', minPeakDist);

    close(wb);

    % subplot(2, 1, 1)
    % plot(audioIn)
    % subplot(2, 1, 2)
    % plot(novelty)
    % hold
    % plot(onsetLocs, onsetPeaks, 'x')
end
