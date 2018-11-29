% Testing onset detection method from:
% Duxbury, C., Bello, J.P., Davies, M. and Sandler, M. Complex domain Onset Detection for Musical Signals

test = sin(2 * pi * 0:48000 * 440/48000);
fft_test = fft(test);
plot(abs(fft_test))

z1 = exp(1j)
z2 = exp(1j * pi)

vec1 = [z1, z1]
vec2 = [z2, z2]

stat_test = bin_stationarity(z1, z2, z2)
stat_test_vec = stationarity(vec1, vec2, vec2)

function output = stationarity(current_fft, previous_fft, preprevious_fft)
    target_mag = arrayfun(@abs, previous_fft);
    target_arg = arrayfun(@angle, 2 * previous_fft - preprevious_fft);
    target = target_mag .* exp(1j * target_arg);

    real_diff = (arrayfun(@real, target) - arrayfun(@real, current_fft)).^2;
    imag_diff = (arrayfun(@imag, target) - arrayfun(@imag, current_fft)).^2;
    output = sum(arrayfun(@sqrt, real_diff + imag_diff));
end

function output = bin_stationarity(current_bin, previous_bin, preprevious_bin)
    target_mag = abs(previous_bin);
    target_arg = angle(2 * previous_bin - preprevious_bin);
    target = target_mag * exp(1j * target_arg);

    output = sqrt((real(target) - real(current_bin))^2 + (imag(target) - imag(current_bin))^2);
end
