function lag = measure_audio_lag(deviceReader)
    fs = deviceReader.SampleRate;
    duration = 0.2;
    time = 0:duration / fs:1;
    chirp_sig = chirp(time, 10000, duration, 100, 'logarithmic');
    player = audioplayer(chirp_sig, fs);
    play(player);
    audio_in = record_audio_in(1, deviceReader);

    x_corr = xcorr(chirp_sig, audio_in);

    [max_val, lag] = max(x_corr);
    disp('Lag: ')
    disp(lag)

    % subplot(3, 1, 1);
    % plot(chirp_sig);
    % subplot(3, 1, 2)
    % plot(audio_in);
    % subplot(3, 1, 3);
    % plot(x_corr);
    % hold;
    % plot(lag, max_val, 'x');
end
