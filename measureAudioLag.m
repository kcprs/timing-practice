function lag = measureAudioLag(deviceReader)
    fs = deviceReader.SampleRate;
    duration = 0.2;
    time = 0:1 / (fs * duration):1;
    chirpSig = chirp(time, 10000, duration, 100, 'logarithmic');
    player = audioplayer(chirpSig, fs);
    play(player);
    audioIn = recordAudioIn(1, deviceReader);

    xCorr = xcorr(chirpSig, audioIn);

    [maxVal, lag] = max(xCorr);
    disp('Lag: ')
    disp(lag)

    % subplot(3, 1, 1);
    % plot(chirpSig);
    % subplot(3, 1, 2)
    % plot(audioIn);
    % subplot(3, 1, 3);
    % plot(xCorr);
    % hold;
    % plot(lag, maxVal, 'x');
end
