function onset_locs = detect_onsets(audio_in, min_peak_dist)
    fft_size = 2048;
    hop_size = 64;

    cursor = 1;
    novelty = zeros(length(audio_in), 1);
    previous_frame_fft = zeros(fft_size, 1);

    wb = waitbar(0, 'Detecting onsets...');
    while cursor + fft_size < length(audio_in)
        waitbar(cursor / length(audio_in) - 0.2, wb);
        frame_fft = fft(audio_in(cursor:cursor + fft_size - 1) .* hann(fft_size));
        fft_difference = abs(frame_fft(1:fft_size / 2 - 1)) - abs(previous_frame_fft(1:fft_size / 2 - 1));

        % novelty(cursor:cursor + hop_size - 1) = sqrt(sum(fft_difference.^2)) / (fft_size / 2);
        novelty(cursor:cursor + hop_size - 1) = sum(fft_difference); % Keeping the sign of the difference helps differentiate between note on and note off
        previous_frame_fft = frame_fft;
        cursor = cursor + hop_size;
    end

    waitbar(0.9, wb);
    fade_in = linspace(0, 1, min_peak_dist)';
    novelty(1:min_peak_dist) = novelty(1:min_peak_dist) .* fade_in;
    max_val = max(novelty);
    novelty = novelty / max_val;
    [~, onset_locs] = findpeaks(novelty, 'MinPeakProminence', 0.5, 'MinPeakDistance', min_peak_dist);

    close(wb);

    % subplot(2, 1, 1)
    % plot(audio_in)
    % subplot(2, 1, 2)
    % plot(novelty)
    % hold
    % plot(onset_locs, onset_peaks, 'x')
end
