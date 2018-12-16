time = 600;
tempo = 120;

[m_tick, fs] = audioread('tick.wav');
m_length = time * fs;
t_length = length(m_tick);
metronome = zeros(m_length, 1);

interval = 60 / tempo * fs;

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
audiowrite('metronome.wav', metronome, fs);
