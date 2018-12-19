function tick_dist = get_tick_distance(tempo, fs)
    tick_dist = idivide(60 * fs, int32(tempo), 'round');
end