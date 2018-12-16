% Note onset detection using spectral flux

[audio_in, fs] = audioread('test_audio/Sine_single.wav');

fft_size = 2048;
hop_size = 256;

cursor = 1;
spec_flux = zeros(length(audio_in), 1);
previous_frame_fft = zeros(fft_size, 1);

while cursor + fft_size < length(audio_in)
    frame_fft = fft(audio_in(cursor:cursor + fft_size - 1) .* hann(fft_size));
    fft_difference = abs(frame_fft(1:fft_size / 2 - 1)) - abs(previous_frame_fft(1:fft_size / 2 - 1));

    spec_flux(cursor:cursor + hop_size - 1) = sqrt(sum(fft_difference.^2)) / (fft_size / 2);
    previous_frame_fft = frame_fft;
    cursor = cursor + hop_size;
end

[peak, peak_loc] = findpeaks(spec_flux, 'MinPeakProminence', 0.005, 'MinPeakDistance', 1000);

subplot(2, 1, 1)
plot(audio_in)
subplot(2, 1, 2)
plot(spec_flux)
title("Spectral Flux - Single sine tone")
hold
plot(peak_loc, peak, 'x')

