function [metronome, tickArray] = generateMetronome(tempo, duration, fs)
    tick = audioread('tick.wav');
    interval = idivide(60 * fs, int32(tempo), 'round');
    metronomeLength = interval * idivide(duration * fs, interval, 'round');
    tickArray = zeros(metronomeLength, 1);

    cursor = 1;
    wb = waitbar(0, 'Generating metronome signal...');
    while cursor < metronomeLength
        tickArray(cursor) = 1;
        cursor = cursor + interval;
        waitbar(cursor / metronomeLength, wb);
    end

    metronome = conv(tickArray, tick, 'same');

    close(wb)
end
