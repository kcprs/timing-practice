function metronome = generate_metronome(tempo, duration, fs)
    m_tick = audioread('tick.wav');
    m_length = duration * fs;
    t_length = length(m_tick);
    metronome = zeros(m_length, 1);

    interval = idivide(60 * fs, int32(tempo), 'round');

    wb = waitbar(0, 'Generating metronome signal...');
    cursor = 1;

    while cursor < m_length
        waitbar(cursor / m_length, wb);

        if cursor + t_length < m_length
            metronome(cursor:cursor + t_length - 1) = m_tick;
        end

        cursor = cursor + interval;
    end

    close(wb)
end
