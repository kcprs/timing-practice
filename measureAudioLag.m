function measureAudioLag(app)
    %% Setup chirp signal
    duration = 0.5;
    fs = str2double(app.SampleRateDropDown.Value);
    time = 0:1 / fs:duration;
    chirpSig = [zeros(1, fs), chirp(time, 10000, duration, 100, 'logarithmic'), zeros(1, fs)];

    %% Setup player
    app.player = audioplayer(chirpSig, fs);

    %% Setup recorder and file writer
    app.deviceReader = audioDeviceReader(fs, str2double(app.BufferSizeDropDown.Value));
    setup(app.deviceReader);
    app.fileWriter = dsp.AudioFileWriter('audioResources/audioIn.wav', 'FileFormat', 'WAV');

    %% Play and record
    play(app.player);
    recordAudioIn(app, duration * fs);

    %% Release resources
    release(app.deviceReader);
    release(app.fileWriter);

    %% Find lag through cross-correlation
    xCorr = xcorr(app.session.audioIn, chirpSig);
    xCorrClipped = xCorr(ceil(length(xCorr) / 2):end);

    [~, lag] = max(xCorrClipped);
    lag = lag - 1;
    app.session.timingInfo.audioLag = lag;

    disp('Audio lag:');
    disp(lag);

    % subplot(3, 1, 3);
    % plot(xCorrClipped);
    % hold('on');
    % plot(lag, maxVal, 'x');
    % hold('off');
    % xl = xlim;
    % subplot(3, 1, 1);
    % plot(chirpSig);
    % ax = gca;
    % ax.XLim = xl;
    % subplot(3, 1, 2)
    % plot(app.session.audioIn);
    % ax = gca;
    % ax.XLim = xl;
end
