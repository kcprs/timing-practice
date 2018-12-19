function [metronome, tick_array] = generate_metronome(tempo, duration, fs)
    tick = audioread('tick.wav');
    interval = idivide(60 * fs, int32(tempo), 'round');
    metronome_length = interval * idivide(duration * fs, interval, 'round');
    tick_array = zeros(metronome_length, 1);

    cursor = 1;
    wb = waitbar(0, 'Generating metronome signal...');
    while cursor < metronome_length
        tick_array(cursor) = 1;
        cursor = cursor + interval;
        waitbar(cursor / metronome_length, wb);
    end

    metronome = conv(tick_array, tick, 'same');

    close(wb)
end
