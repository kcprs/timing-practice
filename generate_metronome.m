function [metronome, tick_locs] = generate_metronome(tempo, duration, fs)
    m_tick = audioread('tick.wav');
    m_length = duration * fs;
    t_length = length(m_tick);
    metronome = zeros(m_length, 1);

    interval = idivide(60 * fs, int32(tempo), 'round');

    wb = waitbar(0, 'Generating metronome signal...');
    cursor = 1;
    tick_locs = ones(idivide(m_length, interval), 1);
    tick_cursor = 1;
    while cursor < m_length
        waitbar(cursor / m_length, wb);

        if cursor + t_length < m_length
            metronome(cursor:cursor + t_length - 1) = m_tick;
            tick_locs(tick_cursor) = cursor;
        end

        cursor = cursor + interval;
        tick_cursor = tick_cursor + 1;
    end

    close(wb)
end
